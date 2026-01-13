import 'dart:convert';
import 'dart:io';
import 'dart:isolate';
import 'dart:ui';
import 'package:android_alarm_manager_plus/android_alarm_manager_plus.dart';
import 'package:couple_note/core/config/app_constants.dart';
import 'package:couple_note/core/constants/trans_keys.dart';
import 'package:couple_note/core/services/Admob/rewarded_ad_manager%20.dart';
import 'package:couple_note/core/services/alarm/alarm_service.dart';
import 'package:couple_note/core/services/fcm_service.dart';
import 'package:couple_note/core/services/local_notification_service.dart';
import 'package:couple_note/core/utils/utils.dart';
import 'package:couple_note/di/dependency_injection.dart';
import 'package:couple_note/presentation/pages/alarm/alarm_screen.dart';
import 'package:couple_note/presentation/routes/router.dart';
import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:in_app_update/in_app_update.dart';
import 'firebase_options.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:android_intent_plus/android_intent.dart';

void main() async {
  WidgetsBinding widgetsBinding = WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: ".env");
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(statusBarColor: Colors.transparent),
  );
  FlutterNativeSplash.preserve(widgetsBinding: widgetsBinding);

  await AppTrans.init();
  await _initializeServices();

  final futures = await Future.wait([
    Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform),
    SharedPreferences.getInstance(),
  ]);

  FirebaseFirestore.instance.settings = Settings(
    persistenceEnabled: true,
    cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED,
  );

  final sharedPreferences = futures[1] as SharedPreferences;
  final initialMessage = await FirebaseMessaging.instance.getInitialMessage();
  final initialRoute = await _determineInitialRoute(initialMessage);

  if (initialRoute.startsWith('ALARM:') == true) {
    final alarmId = int.parse(initialRoute.split(':')[1]);
    FlutterNativeSplash.remove();

    runApp(
      MaterialApp(
        home: AlarmScreen(alarmId: alarmId),
        debugShowCheckedModeBanner: false,
      ),
    );
    return;
  }
  await EasyLocalization.ensureInitialized();
  await MobileAds.instance.initialize();
  RewardedAdManager().loadAd();
  await checkPermissions();
  await FirebaseAppCheck.instance.activate(
    providerAndroid: kDebugMode
        ? AndroidDebugProvider()
        : AndroidPlayIntegrityProvider(),
  );

  FlutterNativeSplash.remove();

  runApp(
    EasyLocalization(
      supportedLocales: [Locale('vi'), Locale('en')],
      path: 'assets/translations',
      fallbackLocale: Locale('en'),
      saveLocale: true,
      useOnlyLangCode: true,
      child: ProviderScope(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(sharedPreferences),
        ],
        child: MyApp(initRoute: initialRoute, initialMessage: initialMessage),
      ),
    ),
  );
}

Future<void> checkPermissions() async {
  if (Platform.isAndroid) {
    var status = await Permission.ignoreBatteryOptimizations.status;
    if (!status.isGranted) {
      final intent = AndroidIntent(
        action: 'android.settings.REQUEST_IGNORE_BATTERY_OPTIMIZATIONS',
        data: 'package:com.yorxbit.couplealarm',
      );
      await intent.launch();
    }
    status = await Permission.scheduleExactAlarm.status;
    if (!status.isGranted) {
      const intent = AndroidIntent(
        action: 'android.settings.REQUEST_SCHEDULE_EXACT_ALARM',
        data: 'package:com.yorxbit.couplealarm',
      );
      await intent.launch();
    }
  }
}

Future<String> _determineInitialRoute(RemoteMessage? initialMessage) async {
  final notificationPath = initialMessage?.data['navigationPath'] as String?;
  if (notificationPath != null &&
      notificationPath.isNotEmpty &&
      FCMService.validRoutes.contains(notificationPath)) {
    return notificationPath;
  } else {
    final launchDetails = await LocalNotifications.getLaunchDetails();
    if (launchDetails.didNotificationLaunchApp) {
      final payload = launchDetails.notificationResponse?.payload;

      Map<String, dynamic> data = {};
      if (payload?.isNotEmpty == true) {
        try {
          data = Map<String, dynamic>.from(json.decode(payload!) as Map);
        } catch (_) {}
      }
      final type = NotificationType.fromString(data['type']!.toString());

      if (type == NotificationType.alarm) {
        final itemId = int.tryParse(data['id']!.toString());
        if (itemId != null) {
          return 'ALARM:$itemId';
        }
      }
    }
  }

  return '/home';
}

Future<void> _initializeServices() async {
  await LocalNotifications.initialize();
  await LocalNotifications.requestPermissionIfNeeded();
  await AndroidAlarmManager.initialize();
  await AlarmService.initializeLocalNotifications();
}

class MyApp extends ConsumerStatefulWidget {
  final String initRoute;
  final RemoteMessage? initialMessage;

  const MyApp({super.key, required this.initRoute, this.initialMessage});

  @override
  ConsumerState<MyApp> createState() => _MyAppState();
}

class _MyAppState extends ConsumerState<MyApp> {
  late final GoRouter _router;

  @override
  void initState() {
    super.initState();
    _router = AppRouter.createRouter(widget.initRoute, ref);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      checkAndUpdate(context);
    });
    _initializeFCMService();
    _initAlarmPortListener();
  }

  void _initAlarmPortListener() {
    final ReceivePort receivePort = ReceivePort();

    IsolateNameServer.removePortNameMapping(kAlarmPortName);
    IsolateNameServer.registerPortWithName(
      receivePort.sendPort,
      kAlarmPortName,
    );

    receivePort.listen((message) {
      if (message is Map && message['action'] == 'show_alarm') {
        final alarmId = message['alarmId'];

        rootNavigatorKey.currentState?.push(
          MaterialPageRoute(
            fullscreenDialog: true,
            builder: (_) => SafeArea(child: AlarmScreen(alarmId: alarmId)),
          ),
        );
      }
    });
  }

  void _initializeFCMService() {
    FCMService.initialize(router: _router, container: ref)
        .then((_) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (widget.initialMessage != null) {
              FCMService.navigateFromNotification(widget.initialMessage!.data);
            } else {
              FCMService.handlePendingNavigation();
            }
          });
        })
        .catchError((e) {
          debugPrint('FCM init error: $e');
        });
  }

  Future<void> checkAndUpdate(BuildContext context) async {
    if (!Platform.isAndroid || kDebugMode) return;

    try {
      final info = await InAppUpdate.checkForUpdate();

      if (info.updateAvailability != UpdateAvailability.updateAvailable) return;

      if (info.immediateUpdateAllowed) {
        await InAppUpdate.performImmediateUpdate();
        return;
      }

      if (info.flexibleUpdateAllowed) {
        await InAppUpdate.startFlexibleUpdate();

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(TransKeys.update_downloaded_successfully.tr()),
            action: SnackBarAction(
              label: TransKeys.install_now.tr(),
              onPressed: () async {
                await InAppUpdate.completeFlexibleUpdate();
              },
            ),
          ),
        );
      }
    } catch (e) {
      debugPrint('In-app update error: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      routerConfig: _router,
      debugShowCheckedModeBanner: false,
      title: 'Couple Alarm',
      theme: ThemeData(
        textTheme: GoogleFonts.nunitoTextTheme(),
        useMaterial3: true,
      ),
      localizationsDelegates: context.localizationDelegates,
      supportedLocales: context.supportedLocales,
      locale: context.locale,
    );
  }
}

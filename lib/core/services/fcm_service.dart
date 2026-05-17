import 'dart:convert';
import 'dart:ui';
import 'package:couple_note/core/constants/trans_keys.dart';
import 'package:couple_note/core/services/local_storage_service.dart';
import 'package:couple_note/core/services/local_notification_service.dart';
import 'package:couple_note/core/config/theme/app_colors.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class FCMService {
  static final FirebaseMessaging _firebaseMessaging =
      FirebaseMessaging.instance;
  static final FirebaseFunctions _functions = FirebaseFunctions.instanceFor(
    region: 'asia-southeast1',
  );

  static GoRouter? _router;
  static String? _pendingNavigationPath;
  static Map<String, dynamic>? _pendingNavigationData;
  static bool _isInitialized = false;

  static const List<String> _validBottomNavRoutes = [
    '/home',
    '/reminder',
    '/todo',
    '/note',
    '/setting',
  ];

  static const List<String> _validSecondaryRoutes = ['/scanner'];

  static List<String> get _allValidRoutes => [
    ..._validBottomNavRoutes,
    ..._validSecondaryRoutes,
  ];

  // ✅ FIX: Đồng bộ keys với background handler
  static const String _keyPendingNavPath = 'pending_nav_path';
  static const String _keyPendingNavData = 'pending_nav_data';

  static Future<void> initialize({
    GoRouter? router,
    WidgetRef? container,
  }) async {
    _router = router;
    _isInitialized = true;

    await _restorePendingNavigation();

    NotificationSettings settings = await _firebaseMessaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    if (settings.authorizationStatus != AuthorizationStatus.authorized &&
        settings.authorizationStatus != AuthorizationStatus.provisional) {
      return;
    }
    final androidImpl =
        LocalNotifications.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();
    if (androidImpl != null) {
      const AndroidNotificationChannel channel = AndroidNotificationChannel(
        'general_channel',
        'General Notifications',
        description: 'This channel is used for general notifications.',
        importance: Importance.max,
        playSound: true,
        enableVibration: true,
      );
      await androidImpl.createNotificationChannel(channel);
      await androidImpl.requestNotificationsPermission();
    }

    FirebaseMessaging.onMessage.listen(_handleForegroundMessage);
    FirebaseMessaging.onMessageOpenedApp.listen(_handleMessageOpenedApp);
    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

    _checkForInitialMessage();
  }

  static Future<void> _checkForInitialMessage() async {
    try {
      int attempts = 0;
      while (_router == null && attempts < 10) {
        await Future.delayed(const Duration(milliseconds: 100));
        attempts++;
      }

      final RemoteMessage? initialMessage = await _firebaseMessaging
          .getInitialMessage();
      if (initialMessage != null) {
        await _savePendingNavigation(initialMessage.data);
        navigateFromNotification(initialMessage.data);
      }
    } catch (e) {
      print('Error checking initial message: $e');
    }
  }

  static Future<void> _savePendingNavigation(Map<String, dynamic> data) async {
    try {
      final prefs = await SharedPreferences.getInstance();

      final path = _extractNavigationPath(data);

      await prefs.setString(_keyPendingNavData, json.encode(data));
      if (path != null) {
        await prefs.setString(_keyPendingNavPath, path);
      }
    } catch (e) {
      print('Error saving pending navigation: $e');
    }
  }

  static Future<void> _restorePendingNavigation() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      final dataString = prefs.getString(_keyPendingNavData);
      final pathString = prefs.getString(_keyPendingNavPath);

      if (dataString != null) {
        _pendingNavigationData = Map<String, dynamic>.from(
          json.decode(dataString) as Map,
        );
      }

      if (pathString != null) {
        _pendingNavigationPath = pathString;
      }
    } catch (e) {
      print('Error restoring pending navigation: $e');
    }
  }

  static Future<void> _clearStoredPendingNavigation() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_keyPendingNavData);
      await prefs.remove(_keyPendingNavPath);
    } catch (e) {
      print('Error clearing pending navigation: $e');
    }
  }

  static String? _extractNavigationPath(Map<String, dynamic> data) {
    return data['navigationPath'] as String?;
  }

  static Future<String?> getFCMToken() async {
    try {
      return await _firebaseMessaging.getToken();
    } catch (e) {
      print('Error getting FCM token: $e');
      return null;
    }
  }

  static void onTokenRefresh(Function(String) onNewToken) {
    _firebaseMessaging.onTokenRefresh.listen(onNewToken);
  }

  static Future<void> deleteToken() async {
    try {
      await _firebaseMessaging.deleteToken();
    } catch (e) {
      print('Error deleting token: $e');
    }
  }

  static Future<void> _handleForegroundMessage(RemoteMessage message) async {
    await _savePendingNavigation(message.data);
    await showLocalNotification(
      title: message.data['title'] ?? 'Thông báo mới',
      body: message.data['body'] ?? 'Bạn có thông báo mới',
      data: message.data,
    );
  }

  static void _handleMessageOpenedApp(RemoteMessage message) {
    Future.delayed(const Duration(milliseconds: 500), () {
      navigateFromNotification(message.data);
    });
  }

  static void navigateFromNotification(Map<String, dynamic> data) {
    if (_router == null || !_isInitialized) {
      _pendingNavigationData = Map<String, dynamic>.from(data);
      _pendingNavigationPath = _extractNavigationPath(data);
      _savePendingNavigation(data);
      return;
    }

    try {
      final String? path = _extractNavigationPath(data);

      if (path != null && path.isNotEmpty && _allValidRoutes.contains(path)) {
        _router!.go(path);
        _clearPendingNavigation();
      } else {
        _router!.go('/home');
        _clearPendingNavigation();
      }
    } catch (e) {
      print('Error navigating from notification: $e');
      _router?.go('/home');
      _clearPendingNavigation();
    }
  }

  static void handlePendingNavigation() {
    if (_pendingNavigationData != null && _router != null) {
      final path = _pendingNavigationPath;
      _clearPendingNavigation();

      if (path != null && _allValidRoutes.contains(path)) {
        _router!.go(path);
      } else {
        _router!.go('/home');
      }
    }
  }

  static void _clearPendingNavigation() {
    _pendingNavigationData = null;
    _pendingNavigationPath = null;
    _clearStoredPendingNavigation();
  }

  static Map<String, dynamic>? getPendingNavigationData() {
    return _pendingNavigationData != null
        ? Map<String, dynamic>.from(_pendingNavigationData!)
        : null;
  }

  static Future<void> showLocalNotification({
    required String title,
    required String body,
    Map<String, dynamic>? data,
  }) async {
    try {
      final bool needApprovalButtons =
          (data?['action']?.toString() == 'request_approval');

      final prefs = await SharedPreferences.getInstance();
      LocalStorageService localStorageService = LocalStorageService(prefs);

      final userEntity = localStorageService.getObject(StorageKeys.user);
      final itemId =
          data?['id']?.toString() ?? data?['itemId']?.toString() ?? '';

      if (userEntity?.isAutoApproveReminder == true &&
          needApprovalButtons &&
          itemId.isNotEmpty) {
        await LocalNotifications.initializeFirebase();
        final reminderRepo = LocalNotifications.createReminderRepository();
        await LocalNotifications.handleReminderApprove(
          reminderRepo,
          itemId,
          localStorageService.getCoupleId() ?? '',
        );
      }

      final androidDetails = AndroidNotificationDetails(
        'general_channel',
        'General Notifications',
        importance: Importance.max,
        priority: Priority.high,
        icon: '@mipmap/ic_launcher',
        color: const Color.fromARGB(255, 255, 107, 107),
        playSound: true,
        enableVibration: true,
        autoCancel: true,
        category: AndroidNotificationCategory.message,
        visibility: NotificationVisibility.public,
        actions:
            needApprovalButtons && userEntity?.isAutoApproveReminder != true
            ? <AndroidNotificationAction>[
                AndroidNotificationAction(
                  'approve_action',
                  TransKeys.accept.tr(),
                  titleColor: AppColors.darkPrimary,
                  showsUserInterface: false,
                ),
                AndroidNotificationAction(
                  'reject_action',
                  TransKeys.reject.tr(),
                  titleColor: AppColors.error,
                  showsUserInterface: false,
                ),
              ]
            : null,
      );

      final iosDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
        categoryIdentifier: needApprovalButtons ? 'approval_category' : null,
      );

      final platformDetails = NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
      );

      String? payload;
      if (data?.isNotEmpty == true) {
        try {
          payload = json.encode(data);
        } catch (e) {
          print('Error encoding payload: $e');
        }
      }

      final notificationId = DateTime.now().millisecondsSinceEpoch.remainder(
        100000,
      );

      await LocalNotifications.show(
        notificationId,
        title,
        body,
        platformDetails,
        payload: payload,
      );
    } catch (e) {
      print('Error showing local notification: $e');
    }
  }

  static Future<FCMResult> sendNotificationToToken({
    required String fcmToken,
    required String title,
    required String body,
    Map<String, dynamic>? data,
    String? navigationPath,
    String? action,
    String? itemId,
    String? feedbackMessage,
  }) async {
    try {
      print('🔔 Gửi notification đến token: $fcmToken');
      if (fcmToken.isEmpty) {
        return FCMResult(success: false, error: 'FCM token is empty');
      }

      final Map<String, dynamic> mergedData = <String, dynamic>{
        ...?data,
        if (navigationPath != null) 'navigationPath': navigationPath,
        if (action != null) 'action': action,
        if (itemId != null) 'itemId': itemId,
        if (feedbackMessage != null) 'feedback_message': feedbackMessage,
        'timestamp': DateTime.now().millisecondsSinceEpoch.toString(),
      };

      final HttpsCallable callable = _functions.httpsCallable(
        'sendNotificationToToken',
      );

      final result = await callable.call({
        'token': fcmToken,
        'title': title,
        'body': body,
        'data': _convertDataToStrings(mergedData),
      });

      final responseData = result.data as Map<String, dynamic>;

      if (responseData['success'] == true) {
        return FCMResult(success: true, messageId: responseData['messageId']);
      } else {
        return FCMResult(
          success: false,
          error: responseData['error'] ?? 'Unknown error',
        );
      }
    } catch (e) {
      print('❌ Lỗi khi gửi notification: $e');
      return FCMResult(success: false, error: e.toString());
    }
  }

  static Map<String, String> _convertDataToStrings(Map<String, dynamic>? data) {
    if (data == null || data.isEmpty) return <String, String>{};

    final Map<String, String> stringData = <String, String>{};
    data.forEach((key, value) {
      if (value != null) {
        stringData[key] = value.toString();
      }
    });

    return stringData;
  }

  static List<String> get validRoutes => List.unmodifiable(_allValidRoutes);
  static bool get hasPendingNavigation => _pendingNavigationData != null;
  static String? get pendingNavigationPath => _pendingNavigationPath;
  static bool get isInitialized => _isInitialized;
}

class FCMResult {
  final bool success;
  final String? messageId;
  final String? error;
  final dynamic results;

  const FCMResult({
    required this.success,
    this.messageId,
    this.error,
    this.results,
  });

  @override
  String toString() {
    return 'FCMResult(success: $success, messageId: $messageId, error: $error, results: $results)';
  }
}

@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();

  try {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('pending_nav_data', json.encode(message.data));

    final path = message.data['navigationPath'] as String?;
    if (path != null) {
      await prefs.setString('pending_nav_path', path);
    }

    await _showBackgroundLocalNotification(
      title: message.data['title'] ?? 'Thông báo mới',
      body: message.data['body'] ?? 'Bạn có thông báo mới',
      data: message.data,
    );
  } catch (e) {
    print('Error in background handler: $e');
  }
}

@pragma('vm:entry-point')
Future<void> _showBackgroundLocalNotification({
  required String title,
  required String body,
  Map<String, dynamic>? data,
}) async {
  try {
    final FlutterLocalNotificationsPlugin localNotifications =
        FlutterLocalNotificationsPlugin();

    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const DarwinInitializationSettings initializationSettingsIOS =
        DarwinInitializationSettings();

    const InitializationSettings initializationSettings =
        InitializationSettings(
          android: initializationSettingsAndroid,
          iOS: initializationSettingsIOS,
        );

    await localNotifications.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: LocalNotifications.onNotificationTapped,
      onDidReceiveBackgroundNotificationResponse:
          LocalNotifications.notificationTapBackground,
    );

    final prefs = await SharedPreferences.getInstance();
    LocalStorageService localStorageService = LocalStorageService(prefs);

    final userEntity = localStorageService.getObject(StorageKeys.user);

    final bool needApprovalButtons =
        (data?['action']?.toString() == 'request_approval');

    final itemId = data?['itemId']?.toString() ?? data?['id']?.toString() ?? '';

    if (userEntity?.isAutoApproveReminder == true &&
        needApprovalButtons &&
        itemId.isNotEmpty) {
      await LocalNotifications.initializeFirebase();
      final reminderRepo = LocalNotifications.createReminderRepository();
      await LocalNotifications.handleReminderApprove(
        reminderRepo,
        itemId,
        localStorageService.getCoupleId() ?? '',
      );
    }

    final androidDetails = AndroidNotificationDetails(
      'general_channel',
      'General Notifications',
      importance: Importance.max,
      priority: Priority.high,
      icon: '@mipmap/ic_launcher',
      color: const Color.fromARGB(255, 255, 107, 107),
      playSound: true,
      enableVibration: true,
      autoCancel: true,
      category: AndroidNotificationCategory.message,
      visibility: NotificationVisibility.public,
      actions: needApprovalButtons && userEntity?.isAutoApproveReminder != true
          ? <AndroidNotificationAction>[
              AndroidNotificationAction(
                'approve_action',
                TransKeys.accept.tr(),
                titleColor: AppColors.darkPrimary,
                showsUserInterface: false,
              ),
              AndroidNotificationAction(
                'reject_action',
                TransKeys.reject.tr(),
                titleColor: AppColors.error,
                showsUserInterface: false,
              ),
            ]
          : null,
    );

    final iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
      categoryIdentifier: needApprovalButtons ? 'approval_category' : null,
    );

    final platformDetails = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    String? payload;
    if (data?.isNotEmpty == true) {
      try {
        payload = json.encode(data);
      } catch (e) {
        print('Error encoding payload: $e');
      }
    }

    final notificationId = DateTime.now().millisecondsSinceEpoch.remainder(
      100000,
    );

    await localNotifications.show(
      notificationId,
      title,
      body,
      platformDetails,
      payload: payload,
    );
  } catch (e) {
    print('Error showing background notification: $e');
  }
}

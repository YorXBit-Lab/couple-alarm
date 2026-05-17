import 'dart:convert';
import 'dart:ui';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:couple_note/core/common/api_response.dart';
import 'package:couple_note/core/config/app_constants.dart';
import 'package:couple_note/core/errors/app_exception.dart';
import 'package:couple_note/core/errors/exception_handler.dart';
import 'package:couple_note/core/services/alarm/alarm_service.dart';
import 'package:couple_note/core/services/fcm_service.dart';
import 'package:couple_note/core/services/local_storage_service.dart';
import 'package:couple_note/core/services/connectivity_service.dart';
import 'package:couple_note/core/utils/datetime_utils.dart';
import 'package:couple_note/core/utils/error_logger.dart';
import 'package:couple_note/features/user/data/models/user_model.dart';
import 'package:couple_note/features/couple/data/repository/couple_repository_impl.dart';
import 'package:couple_note/features/reminder/data/repository/reminder_repository_impl.dart';
import 'package:couple_note/features/user/data/repository/user_repository_impl.dart';
import 'package:couple_note/features/reminder/domain/entities/reminder.dart';
import 'package:couple_note/features/user/domain/entities/user.dart';
import 'package:couple_note/firebase_options.dart';
import 'package:couple_note/features/alarm/presentation/pages/alarm_screen.dart';
import 'package:couple_note/core/config/routers/router.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/data/latest.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

@pragma('vm:entry-point')
class LocalNotifications {
  LocalNotifications._();

  static const _initTimeout = Duration(seconds: 5);
  static const _operationTimeout = Duration(seconds: 10);
  static const _navigationDelay = Duration(milliseconds: 1000);

  static final _plugin = FlutterLocalNotificationsPlugin();

  @Deprecated('Use static methods instead')
  static FlutterLocalNotificationsPlugin get localNotification => _plugin;

  static Future<void> initialize() async {
    tzdata.initializeTimeZones();
    tz.setLocalLocation(tz.local);

    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosInit = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    await _plugin.initialize(
      const InitializationSettings(android: androidInit, iOS: iosInit),
      onDidReceiveNotificationResponse: onNotificationTapped,
      onDidReceiveBackgroundNotificationResponse: notificationTapBackground,
    );
  }

  static Future<void> requestPermissionIfNeeded() async {
    final android = _plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();

    final granted = await android?.areNotificationsEnabled() ?? true;
    if (!granted) {
      await android?.requestNotificationsPermission();
    }
  }

  static Future<NotificationAppLaunchDetails> getLaunchDetails() async {
    final details = await _plugin.getNotificationAppLaunchDetails();
    return details ??
        const NotificationAppLaunchDetails(false, notificationResponse: null);
  }

  static Future<void> cancel(int id) => _plugin.cancel(id);

  static Future<void> cancelAll() => _plugin.cancelAll();

  static Future<void> show(
    int id,
    String? title,
    String? body,
    NotificationDetails? notificationDetails, {
    String? payload,
  }) => _plugin.show(id, title, body, notificationDetails, payload: payload);

  static Future<void> scheduleNotification({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledDate,
  }) async {
    await _plugin.zonedSchedule(
      id,
      title,
      body,
      tz.TZDateTime.from(scheduledDate, tz.local),
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'todo_channel',
          'Todo Reminder',
          importance: Importance.max,
          priority: Priority.high,
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
    );
  }

  static T? resolvePlatformSpecificImplementation<T extends Object>() =>
      _plugin.resolvePlatformSpecificImplementation();

  @pragma('vm:entry-point')
  static Future<void> onNotificationTapped(
    NotificationResponse response,
  ) async {
    await _initializeBindings();

    final data = _parsePayload(response.payload);
    final type = NotificationType.fromString(data['type']?.toString() ?? '');

    await _routeNotificationByType(type, response, data);
  }

  @pragma('vm:entry-point')
  static Future<void> notificationTapBackground(
    NotificationResponse response,
  ) async {
    await _initializeBindings();
    final data = _parsePayload(response.payload);
    final type = NotificationType.fromString(data['type']?.toString() ?? '');

    await _routeNotificationByType(type, response, data);
  }

  @pragma('vm:entry-point')
  static Future<void> _routeNotificationByType(
    NotificationType type,
    NotificationResponse response,
    Map<String, dynamic> data,
  ) async {
    switch (type) {
      case NotificationType.alarm:
        await _handleAlarmNotification(response, data);
        break;
      case NotificationType.reminder:
        await _handleReminderNotification(response, data);
        break;
      default:
        debugPrint('⚠️ Unknown notification type: $type');
    }
  }

  static Future<void> _initializeBindings() async {
    WidgetsFlutterBinding.ensureInitialized();
    DartPluginRegistrant.ensureInitialized();
  }

  static Map<String, dynamic> _parsePayload(String? payload) {
    if (payload?.isEmpty ?? true) return {};

    try {
      return Map<String, dynamic>.from(json.decode(payload!) as Map);
    } catch (e) {
      debugPrint('Failed to parse payload: $e');
      return {};
    }
  }

  static Future<bool> initializeFirebase() async {
    try {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      ).timeout(_initTimeout);

      return true;
    } catch (e) {
      debugPrint('Firebase initialization failed (offline?): $e');
      return false;
    }
  }

  @pragma('vm:entry-point')
  static Future<void> _handleAlarmNotification(
    NotificationResponse response,
    Map<String, dynamic> data,
  ) async {
    final alarmId = int.tryParse(data['id']?.toString() ?? '');
    if (alarmId == null) {
      debugPrint('Invalid alarm ID in payload');
      return;
    }

    await initializeFirebase();
    debugPrint('Invalid alarm ID in payload: ${response.actionId}');
    switch (response.actionId) {
      case 'snooze_action':
        await _handleAlarmSnooze(alarmId);
        break;
      case 'dismiss_action':
        await _handleAlarmDismiss(alarmId);
        break;
      default:
        _navigateToAlarmScreen(alarmId);
    }
  }

  static Future<void> _handleAlarmSnooze(int alarmId) async {
    await AlarmService.snoozeFromNow(sourceAlarmId: alarmId);
    await cancel(alarmId);
  }

  static Future<void> _handleAlarmDismiss(int alarmId) async {
    await cancel(alarmId);
  }

  @pragma('vm:entry-point')
  static Future<void> _navigateToAlarmScreen(int alarmId) async {
    final context = rootNavigatorKey.currentContext;
    if (context == null) {
      debugPrint('No context available for navigation');
      return;
    }

    try {
      final currentRouteName = GoRouterState.of(context).name;

      if (currentRouteName != 'alarm') {
        rootNavigatorKey.currentState?.push(
          MaterialPageRoute(
            fullscreenDialog: true,
            builder: (_) => AlarmScreen(alarmId: alarmId),
          ),
        );
      }
    } catch (e) {
      debugPrint('Error navigating to alarm: $e');
    }
  }

  static Future<void> _handleReminderNotification(
    NotificationResponse response,
    Map<String, dynamic> data,
  ) async {
    final itemId = data['itemId']?.toString();
    if (itemId == null) {
      debugPrint('Invalid reminder itemId in payload');
      return;
    }

    await initializeFirebase();

    final reminderRepo = createReminderRepository();
    LocalStorageService? localStorageService = LocalStorageService(
      await SharedPreferences.getInstance(),
    );
    var currentUser =
        localStorageService.getObject(StorageKeys.user) as UserModel?;

    switch (response.actionId) {
      case 'approve_action':
        await handleReminderApprove(
          reminderRepo,
          itemId,
          localStorageService.getCoupleId() ?? '',
        );
        break;
      case 'reject_action':
        await handleReminderReject(reminderRepo, itemId, currentUser!.uid);
        break;
      default:
        // Tap vào notification body (không phải action button)
        break;
    }

    Future.delayed(_navigationDelay, () {
      FCMService.navigateFromNotification(data);
    });
  }

  static UserRepositoryImpl createUserRepository() {
    return UserRepositoryImpl(FirebaseFirestore.instance);
  }

  static ReminderRepositoryImpl createReminderRepository() {
    return ReminderRepositoryImpl(
      FirebaseFirestore.instance,
      ConnectivityService(),
    );
  }

  static CoupleRepositoryImpl createCoupleRepository() {
    return CoupleRepositoryImpl(
      FirebaseFirestore.instance,
      createUserRepository(),
    );
  }

  static Future<void> handleReminderApprove(
    ReminderRepositoryImpl repo,
    String itemId,
    String coupleId,
  ) async {
    try {
      final reminder = await _fetchReminder(repo, itemId);
      if (reminder == null) return;

      final nextReminderDate = _calculateNextReminderDate(reminder);

      if (nextReminderDate.isBefore(DateTime.now())) {
        await _updateReminderAsOverdue(
          repo,
          reminder,
          reminder.ownerId == coupleId,
        );
      } else {
        await _scheduleNextReminder(
          repo,
          reminder,
          nextReminderDate,
          reminder.ownerId == coupleId,
        );
      }
    } catch (e, stackTrace) {
      ErrorLogger.log(ExceptionHandler.handle(e, stackTrace));
    }
  }

  static Future<void> handleReminderReject(
    ReminderRepositoryImpl repo,
    String itemId,
    String currentUserId,
  ) async {
    try {
      final reminder = await _fetchReminder(repo, itemId);
      if (reminder == null) return;

      await repo.deleteReminder(reminder, currentUserId);
      await repo.updateReminder(
        reminder.copyWith(
          approvalStatus: ApprovalStatus.rejected,
          updatedAt: DateTime.now(),
        ),
      );
    } catch (e, stackTrace) {
      ErrorLogger.log(ExceptionHandler.handle(e, stackTrace));
    }
  }

  static Future<ReminderEntity?> _fetchReminder(
    ReminderRepositoryImpl repo,
    String itemId,
  ) async {
    final res = await repo
        .getReminderById(itemId)
        .timeout(
          _operationTimeout,
          onTimeout: () => ApiResponse<ReminderEntity>.failure(
            throw ThrowException(ErrorCode.connectionTimeout),
          ),
        );

    if (!res.isSuccess || res.data == null) {
      debugPrint('Reminder not found: $itemId');
      return null;
    }

    return res.data;
  }

  static DateTime _calculateNextReminderDate(ReminderEntity reminder) {
    if (reminder.days?.isNotEmpty == true) {
      return DateTimeUtils.getNextReminderDate(
        reminder.reminderDate,
        reminder.days!,
      );
    }
    return reminder.reminderDate;
  }

  static Future<void> _updateReminderAsOverdue(
    ReminderRepositoryImpl repo,
    ReminderEntity reminder,
    bool isCouple,
  ) async {
    await repo.updateReminder(
      reminder.copyWith(
        approvalStatus: ApprovalStatus.accepted,
        reminderStatus: isCouple
            ? reminder.reminderStatus
            : ReminderStatus.overdue,
        partnerReminderStatus: isCouple
            ? ReminderStatus.overdue
            : reminder.partnerReminderStatus,
        updatedAt: DateTime.now(),
      ),
    );
  }

  static Future<void> _scheduleNextReminder(
    ReminderRepositoryImpl repo,
    ReminderEntity reminder,
    DateTime nextDate,
    bool isCouple,
  ) async {
    final newAlarmId = await AlarmService.scheduleWithRollback(
      reminderDate: nextDate,
      alarmId: reminder.alarmId ?? -1,
    );

    await repo.updateReminder(
      reminder.copyWith(
        alarmId: newAlarmId,
        reminderDate: nextDate,
        approvalStatus: ApprovalStatus.accepted,
        reminderStatus: isCouple
            ? reminder.reminderStatus
            : ReminderStatus.doing,
        partnerReminderStatus: isCouple
            ? ReminderStatus.doing
            : reminder.partnerReminderStatus,
        updatedAt: DateTime.now(),
      ),
    );
  }
}

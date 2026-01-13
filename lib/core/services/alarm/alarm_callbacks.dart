import 'dart:ui';
import 'package:android_alarm_manager_plus/android_alarm_manager_plus.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:couple_note/core/common/api_response.dart';
import 'package:couple_note/core/config/app_constants.dart';
import 'package:couple_note/core/errors/app_exception.dart';
import 'package:couple_note/core/services/lib/core/local_storage_service.dart';
import 'package:couple_note/core/services/lib/core/services/connectivity_service.dart';
import 'package:couple_note/core/services/local_notification_service.dart';
import 'package:couple_note/core/utils/datetime_utils.dart';
import 'package:couple_note/data/repositories/reminder_repository_impl.dart';
import 'package:couple_note/domain/entities/reminder.dart';
import 'package:couple_note/domain/entities/user.dart';
import 'package:couple_note/firebase_options.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_show_when_locked/flutter_show_when_locked.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'alarm_service.dart';

const _kFirebaseInitTimeout = Duration(seconds: 5);
const _kFirestoreTimeout = Duration(seconds: 10);
const _kUpdateTimeout = Duration(seconds: 5);

@pragma('vm:entry-point')
Future<void> alarmFireCallback(int alarmId) async {
  try {
    await _initializeServices();
    final reminder = await _fetchReminder(alarmId);

    if (reminder == null) {
      debugPrint('Alarm $alarmId: Reminder not found');
      return;
    }

    await _displayAlarmNotification(alarmId, reminder);
    await _handlePostAlarmActions(reminder);
  } catch (e, stackTrace) {
    debugPrint('Error in alarmFireCallback($alarmId): $e');
    debugPrint('Stack trace: $stackTrace');
  }
}

@pragma('vm:entry-point')
Future<void> testAlarmCallback(int alarmId) async {
  await alarmFireCallback(alarmId);
}

Future<void> _initializeServices() async {
  WidgetsFlutterBinding.ensureInitialized();
  DartPluginRegistrant.ensureInitialized();

  await _initializeFirebase();
  await LocalNotifications.initialize();
  await AlarmService.initializeLocalNotifications();
}

Future<bool> _initializeFirebase() async {
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    ).timeout(_kFirebaseInitTimeout);

    return true;
  } catch (e) {
    return false;
  }
}

Future<ReminderEntity?> _fetchReminder(int alarmId) async {
  final reminderRepo = _createReminderRepository();

  try {
    final response = await reminderRepo
        .getReminderByAlarmId(alarmId)
        .timeout(
          _kFirestoreTimeout,
          onTimeout: () {
            debugPrint('Firestore timeout - working offline');
            return ApiResponse<ReminderEntity>.failure(
              throw ThrowException(ErrorCode.reminderNotFound),
            );
          },
        );

    return response.data;
  } catch (e) {
    debugPrint('Failed to fetch reminder $alarmId: $e');
    return null;
  }
}

ReminderRepositoryImpl _createReminderRepository() {
  return ReminderRepositoryImpl(
    FirebaseFirestore.instance,
    ConnectivityService(),
  );
}

Future<void> _displayAlarmNotification(
  int alarmId,
  ReminderEntity reminder,
) async {
  await FlutterShowWhenLocked().show();
  final notificationData = _prepareNotificationData(reminder);
  await _showFullscreenAlarm(alarmId, notificationData, reminder);
  _notifyMainApp(alarmId);
}

({String title, String body}) _prepareNotificationData(
  ReminderEntity reminder,
) {
  final title = DateTimeUtils.formatTimeWith24Hour(reminder.reminderDate);

  final body = reminder.title.isNotEmpty ? reminder.title : 'Đã đến giờ!';

  return (title: title, body: body);
}

Future<void> _showFullscreenAlarm(
  int alarmId,
  ({String title, String body}) data,
  ReminderEntity reminder,
) async {
  await AlarmService.showFullScreenAlarm(
    alarmId: alarmId,
    title: data.title,
    body: data.body,
    playSound: reminder.isSound,
    vibrate: reminder.isVibrate,
  );
}

Future<void> _handlePostAlarmActions(ReminderEntity reminder) async {
  final firebaseInitialized = await _initializeFirebase();

  if (!firebaseInitialized) {
    debugPrint('Skipping post-alarm update (no Firebase connection)');
    return;
  }

  if (reminder.recurringType == RecurringType.none) {
    await _markReminderAsDone(reminder);
  } else {
    await _handleRecurringAlarm(reminder);
  }
}

Future<void> _markReminderAsDone(ReminderEntity reminder) async {
  try {
    final reminderRepo = _createReminderRepository();
    LocalStorageService localStorageService = LocalStorageService(
      await SharedPreferences.getInstance(),
    );

    final isCoupleNotCreatedBy =
        (reminder.ownerId == localStorageService.getCoupleId() &&
        reminder.createdBy !=
            (localStorageService.getObject(StorageKeys.user) as UserEntity)
                .uid);

    final updated = reminder.copyWith(
      reminderStatus: isCoupleNotCreatedBy
          ? reminder.reminderStatus
          : ReminderStatus.done,
      partnerReminderStatus: isCoupleNotCreatedBy
          ? ReminderStatus.done
          : reminder.partnerReminderStatus,
      updatedAt: DateTime.now(),
    );

    await reminderRepo.updateReminder(updated).timeout(_kUpdateTimeout);
  } catch (e) {
    debugPrint('Failed to mark reminder as done: $e');
  }
}

Future<void> _handleRecurringAlarm(ReminderEntity reminder) async {
  try {
    final nextAt = _calculateNextAlarmTime(reminder);

    if (nextAt == null) {
      debugPrint('Cannot calculate next alarm time');
      return;
    }

    await _updateReminderDate(reminder, nextAt);
    await _scheduleNextAlarm(reminder.alarmId!, nextAt);
  } catch (e) {
    debugPrint('Error handling recurring alarm: $e');
  }
}

Future<void> _updateReminderDate(
  ReminderEntity reminder,
  DateTime nextAt,
) async {
  try {
    final reminderRepo = _createReminderRepository();
    final updated = reminder.copyWith(
      reminderDate: nextAt,
      updatedAt: DateTime.now(),
    );

    await reminderRepo.updateReminder(updated).timeout(_kUpdateTimeout);
  } catch (e) {
    debugPrint('Failed to update reminder date: $e');
  }
}

DateTime? _calculateNextAlarmTime(ReminderEntity reminder) {
  switch (reminder.recurringType) {
    case RecurringType.daily:
      return _calculateNextDailyAlarm(reminder.reminderDate);

    case RecurringType.weekly:
      return _calculateNextWeeklyAlarm(reminder);

    case RecurringType.none:
      return null;
  }
}

DateTime _calculateNextDailyAlarm(DateTime reminderDate) {
  final now = DateTime.now();
  DateTime nextAt = DateTime(
    now.year,
    now.month,
    now.day,
    reminderDate.hour,
    reminderDate.minute,
  );

  nextAt = nextAt.add(const Duration(days: 1));

  while (nextAt.isBefore(now)) {
    nextAt = nextAt.add(const Duration(days: 1));
  }

  return nextAt;
}

DateTime _calculateNextWeeklyAlarm(ReminderEntity reminder) {
  return DateTimeUtils.getNextReminderDate(
    reminder.reminderDate,
    reminder.days ?? {},
    from: DateTime.now(),
  );
}

Future<void> _scheduleNextAlarm(int alarmId, DateTime nextAt) async {
  try {
    final success = await AndroidAlarmManager.oneShotAt(
      nextAt,
      alarmId,
      alarmFireCallback,
      exact: true,
      wakeup: true,
      allowWhileIdle: true,
      rescheduleOnReboot: false,
    );

    if (success) {
      debugPrint('Rescheduled alarm $alarmId for $nextAt');
    } else {
      debugPrint('Failed to reschedule alarm $alarmId');
    }
  } catch (e) {
    debugPrint('Error scheduling alarm $alarmId: $e');
  }
}

void _notifyMainApp(int alarmId) {
  try {
    final port = IsolateNameServer.lookupPortByName(kAlarmPortName);

    if (port != null) {
      port.send({
        'action': 'show_alarm',
        'alarmId': alarmId,
        'timestamp': DateTime.now().millisecondsSinceEpoch,
      });
    } else {
      debugPrint('Main app port not found');
    }
  } catch (e) {
    debugPrint('Error notifying main app: $e');
  }
}

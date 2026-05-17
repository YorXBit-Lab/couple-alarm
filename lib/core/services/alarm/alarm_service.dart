import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';
import 'package:couple_note/core/config/app_constants.dart';
import 'package:couple_note/core/constants/trans_keys.dart';
import 'package:couple_note/core/services/alarm/alarm_callbacks.dart';
import 'package:couple_note/core/services/local_notification_service.dart';
import 'package:couple_note/features/reminder/domain/entities/reminder.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:android_alarm_manager_plus/android_alarm_manager_plus.dart';
import 'package:flutter_show_when_locked/flutter_show_when_locked.dart';

class AlarmService {
  static const snoozeMinutes = 5;
  static const int maxConcurrentSchedule = 10;
  static final _random = Random();

  static const String channelSoundVibrate = 'alarm_sound_vibrate';
  static const String channelSoundVibrateName = 'Sound & Vibrate Alarm';
  static const String channelSoundVibrateDesc =
      'Alarm notification with sound and vibration';

  static const String channelSoundOnly = 'alarm_sound_only';
  static const String channelSoundOnlyName = 'Only Sound Alarm';
  static const String channelSoundOnlyDesc =
      'Alarm notification with sound only';

  static const String channelVibrateOnly = 'alarm_vibrate_only';
  static const String channelVibrateOnlyName = 'Only Vibrate Alarm';
  static const String channelVibrateOnlyDesc =
      'Alarm notification with vibration only';

  static const String channelSilent = 'alarm_silent';
  static const String channelSilentName = 'Silent Alarm';
  static const String channelSilentDesc =
      'Silent alarm with no sound and no vibration';

  static int generateId() {
    final ms = DateTime.now().millisecondsSinceEpoch;
    final rand = _random.nextInt(1000);
    int id = (ms + rand) % 1000000000;
    return id;
  }

  static Future<void> initializeLocalNotifications() async {
    final androidImpl =
        LocalNotifications.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();
    if (androidImpl != null) {
      await androidImpl.createNotificationChannel(
        const AndroidNotificationChannel(
          channelSoundVibrate,
          channelSoundVibrateName,
          description: channelSoundVibrateDesc,
          importance: Importance.max,
          playSound: true,
          sound: RawResourceAndroidNotificationSound('mozart'),
          audioAttributesUsage: AudioAttributesUsage.alarm,
          enableVibration: true,
        ),
      );

      await androidImpl.createNotificationChannel(
        const AndroidNotificationChannel(
          channelSoundOnly,
          channelSoundOnlyName,
          description: channelSoundOnlyDesc,
          importance: Importance.max,
          playSound: true,
          sound: RawResourceAndroidNotificationSound('mozart'),
          audioAttributesUsage: AudioAttributesUsage.alarm,
          enableVibration: false,
        ),
      );

      await androidImpl.createNotificationChannel(
        AndroidNotificationChannel(
          channelVibrateOnly,
          channelVibrateOnlyName,
          description: channelVibrateOnlyDesc,
          vibrationPattern: Int64List.fromList(const [0, 300, 200, 300]),
          importance: Importance.max,
          playSound: false,
          enableVibration: true,
        ),
      );

      await androidImpl.createNotificationChannel(
        const AndroidNotificationChannel(
          channelSilent,
          channelSilentName,
          description: channelSilentDesc,
          importance: Importance.high,
          playSound: false,
          enableVibration: false,
          bypassDnd: true,
        ),
      );
    }
  }

  static Future<void> showFullScreenAlarm({
    required int alarmId,
    required String title,
    required String body,
    bool playSound = true,
    bool vibrate = true,
    bool ongoing = true,
  }) async {
    final Map<String, dynamic> mergedData = <String, dynamic>{
      'type': NotificationType.alarm,
      'id': alarmId,
      'timestamp': DateTime.now().millisecondsSinceEpoch.toString(),
    };

    final androidDetails = AndroidNotificationDetails(
      channelSilent,
      channelSilentName,
      channelDescription: channelSilentDesc,
      importance: Importance.max,
      channelBypassDnd: true,
      priority: Priority.max,
      category: AndroidNotificationCategory.alarm,
      icon: '@mipmap/ic_launcher',
      color: const Color.fromARGB(255, 255, 107, 107),
      fullScreenIntent: true,
      visibility: NotificationVisibility.public,
      ongoing: ongoing,
      autoCancel: false,
      audioAttributesUsage: AudioAttributesUsage.alarm,
      usesChronometer: true,
      showWhen: true,
      when: DateTime.now().millisecondsSinceEpoch,
      additionalFlags: Int32List.fromList(<int>[4]),
      actions: <AndroidNotificationAction>[
        AndroidNotificationAction(
          'snooze_action',
          '${TransKeys.snooze.tr()} (5\')',
          showsUserInterface: false,
        ),
        AndroidNotificationAction(
          'dismiss_action',
          TransKeys.dismiss.tr(),
          showsUserInterface: false,
        ),
      ],
    );

    final details = NotificationDetails(android: androidDetails);

    await LocalNotifications.show(
      alarmId,
      title,
      body,
      details,
      payload: json.encode(_convertDataToStrings(mergedData)),
    );
  }

  static Future<void> showNormalNotification({
    required int alarmId,
    required String title,
    required String body,
    bool playSound = true,
    bool vibrate = true,
  }) async {
    final Map<String, dynamic> mergedData = <String, dynamic>{
      'type': NotificationType.reminder,
      'id': alarmId,
      'timestamp': DateTime.now().millisecondsSinceEpoch.toString(),
    };

    String chanelId = channelSoundVibrate;
    String chanelName = channelSoundVibrate;
    String chanelDesc = channelSoundVibrate;

    if (playSound == false && vibrate == false) {
      chanelId = channelSilent;
      chanelName = channelSilentName;
      chanelDesc = channelSilentDesc;
    } else if (playSound == true && vibrate == false) {
      chanelId = channelSoundOnly;
      chanelName = channelSoundOnlyName;
      chanelDesc = channelSoundOnlyDesc;
    } else if (playSound == false && vibrate == true) {
      chanelId = channelVibrateOnly;
      chanelName = channelVibrateOnlyName;
      chanelDesc = channelVibrateOnlyDesc;
    }
    final androidDetails = AndroidNotificationDetails(
      chanelId,
      chanelName,
      channelDescription: chanelDesc,
      importance: Importance.high,
      priority: Priority.high,
      category: AndroidNotificationCategory.alarm,
      icon: '@mipmap/ic_launcher',
      color: const Color.fromARGB(255, 255, 107, 107),
      fullScreenIntent: false,
      visibility: NotificationVisibility.public,
      playSound: playSound,
      enableVibration: vibrate,
      ongoing: false,
      autoCancel: true,
      audioAttributesUsage: AudioAttributesUsage.notification,
      sound: const RawResourceAndroidNotificationSound('mozart'),
      actions: const <AndroidNotificationAction>[
        AndroidNotificationAction(
          'snooze_action',
          'Snooze (5\')',
          showsUserInterface: false,
        ),
        AndroidNotificationAction(
          'dismiss_action',
          'Dismiss',
          showsUserInterface: false,
        ),
      ],
    );

    final details = NotificationDetails(android: androidDetails);
    await LocalNotifications.show(
      alarmId,
      title,
      body,
      details,
      payload: json.encode(_convertDataToStrings(mergedData)),
    );
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

  static Future<void> cancelLocalNotification(int id) =>
      LocalNotifications.cancel(id);
  static Future<void> cancelAllLocalNotifications() =>
      LocalNotifications.cancelAll();

  static Future<int> scheduleWithRollback({
    required DateTime reminderDate,
    int? alarmId,
  }) async {
    try {
      if (alarmId == null || alarmId == -1) {
        alarmId = generateId();
      } else {
        await cancel(alarmId);
        alarmId = generateId();
      }

      final success = await AndroidAlarmManager.oneShotAt(
        reminderDate.toLocal(),
        alarmId,
        alarmFireCallback,
        exact: true,
        wakeup: true,
        rescheduleOnReboot: true,
        alarmClock: true,
        allowWhileIdle: true,
      );

      if (!success) {
        return -1;
      }

      return alarmId;
    } catch (e) {
      return -1;
    }
  }

  static Future<void> cancel(int id) async {
    try {
      await AndroidAlarmManager.cancel(id);
    } catch (e) {
      debugPrint('Error canceling alarm: $e');
    }
  }

  static Future<void> cancelAll(List<ReminderEntity> reminder) async {
    await Future.wait(
      reminder.map((a) {
        final alarmId = a.alarmId;
        if (alarmId == null) {
          return Future.value();
        }
        return AndroidAlarmManager.cancel(alarmId).catchError((_) {});
      }),
      eagerError: false,
    );
  }

  static Future<bool> snoozeFromNow({required int sourceAlarmId}) async {
    final when = DateTime.now().add(const Duration(minutes: snoozeMinutes));

    try {
      return await AndroidAlarmManager.oneShotAt(
        when.toLocal(),
        sourceAlarmId,
        alarmFireCallback,
        exact: true,
        wakeup: true,
        rescheduleOnReboot: false,
        allowWhileIdle: true,
      );
    } catch (e) {
      debugPrint('Error snoozing alarm: $e');
      return false;
    }
  }
}

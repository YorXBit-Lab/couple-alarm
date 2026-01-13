import 'package:couple_note/core/config/app_constants.dart';
import 'package:couple_note/core/constants/trans_keys.dart';
import 'package:couple_note/core/utils/datetime_utils.dart';
import 'package:couple_note/domain/entities/reminder.dart';
import 'package:couple_note/domain/entities/user.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:flutter/services.dart';

Color getPriorityColor(TodoPriority priority) {
  switch (priority) {
    case TodoPriority.high:
      return Colors.red;
    case TodoPriority.medium:
      return Colors.orange;
    case TodoPriority.normal:
      return Colors.green;
  }
}

String getPriorityLabel(TodoPriority priority) {
  switch (priority) {
    case TodoPriority.high:
      return TransKeys.high.tr();
    case TodoPriority.medium:
      return 'TB';
    case TodoPriority.normal:
      return 'Thap';
  }
}

IconData getStatusIcon(ApprovalStatus status) {
  switch (status) {
    case ApprovalStatus.pending:
      return Icons.pending_outlined;
    case ApprovalStatus.accepted:
      return Icons.error_outline;
    default:
      return Icons.pending_outlined;
  }
}

String getName(UserEntity? user, {int maxLength = 7}) {
  var name = user == null
      ? TransKeys.lover.tr()
      : (user.nickname != null && user.nickname!.isNotEmpty)
      ? user.nickname
      : user.displayName;

  if (name == null || name.isEmpty) {
    name = TransKeys.lover.tr();
  }

  if (name.length <= maxLength) {
    return name;
  }

  return '${name.substring(0, maxLength)}...';
}

String getReminderDateContent(ReminderEntity reminder) {
  switch (reminder.recurringType) {
    case RecurringType.none:
      final isExpiredOrDone =
          reminder.reminderStatus == ReminderStatus.overdue ||
          reminder.reminderStatus == ReminderStatus.done;

      if (isExpiredOrDone) {
        final now = DateTime.now();
        final reminderTime = TimeOfDay.fromDateTime(reminder.reminderDate);
        final todayWithReminderTime = DateTime(
          now.year,
          now.month,
          now.day,
          reminderTime.hour,
          reminderTime.minute,
        );

        if (todayWithReminderTime.isAfter(now)) {
          return TransKeys.today.tr();
        } else {
          return TransKeys.tomorrow.tr();
        }
      }
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      final reminderDay = DateTime(
        reminder.reminderDate.year,
        reminder.reminderDate.month,
        reminder.reminderDate.day,
      );

      if (reminderDay == today) {
        return TransKeys.today.tr();
      }

      final tomorrow = today.add(Duration(days: 1));
      if (reminderDay == tomorrow) {
        return TransKeys.tomorrow.tr();
      }
      return '${DateTimeUtils.getWeekdayName(reminder.reminderDate)} ';

    case RecurringType.daily:
      return TransKeys.every_day.tr();

    case RecurringType.weekly:
      return getSelectedDaysText(reminder.days ?? {});
  }
}

String getSelectedDaysText(Set<int> selectedDays) {
  if (selectedDays.isEmpty) return '';

  final dayMap = {
    1: TransKeys.mon.tr(),
    2: TransKeys.tue.tr(),
    3: TransKeys.wed.tr(),
    4: TransKeys.thu.tr(),
    5: TransKeys.fri.tr(),
    6: TransKeys.sat.tr(),
    7: TransKeys.sun.tr(),
  };

  final sortedDays = selectedDays.toList()..sort();
  final dayNames = sortedDays.map((day) => dayMap[day]!).toList();

  if (dayNames.length == 7) return TransKeys.every_day.tr();
  return '${TransKeys.every.tr()} ${dayNames.join(', ')}';
}

int calculateDaysTogether(DateTime loveStartDate) {
  final now = DateTime.now();
  return now.difference(loveStartDate).inDays;
}

class AppTrans {
  static Map<String, Map<String, String>> _translations = {'en': {}, 'vi': {}};

  // Load 2 file JSON
  static Future<void> init() async {
    final viJson = await rootBundle.loadString('assets/translations/vi.json');
    final enJson = await rootBundle.loadString('assets/translations/en.json');

    _translations['vi'] = Map<String, String>.from(json.decode(viJson));
    _translations['en'] = Map<String, String>.from(json.decode(enJson));
  }

  static String get(String? languageCode, String key) {
    if (languageCode == null) {
      languageCode = 'en';
    }
    return _translations[languageCode]?[key] ?? key;
  }
}

int buildNotifyId(String id) {
  return '${id}'.hashCode & 0x7fffffff;
}

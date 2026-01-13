import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:couple_note/core/constants/trans_keys.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class DateTimeUtils {
  static final DateTimeUtils _instance = DateTimeUtils._internal();
  factory DateTimeUtils() => _instance;
  DateTimeUtils._internal();

  static String getTimeAgo(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inDays > 365) {
      final years = (difference.inDays / 365).floor();
      return '${years} năm trước';
    } else if (difference.inDays > 30) {
      final months = (difference.inDays / 30).floor();
      return '${months} tháng trước';
    } else if (difference.inDays > 7) {
      final weeks = (difference.inDays / 7).floor();
      return '${weeks} tuần trước';
    } else if (difference.inDays > 0) {
      return '${difference.inDays} ngày trước';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} giờ trước';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} phút trước';
    } else {
      return 'Vừa xong';
    }
  }

  /// Format ngày tháng theo định dạng Việt Nam
  static String formatDate(DateTime dateTime, {String pattern = 'dd/MM/yyyy'}) {
    return DateFormat(pattern, 'vi_VN').format(dateTime);
  }

  /// Format ngày giờ đầy đủ
  static String formatDateTime(
    DateTime dateTime, {
    String pattern = 'dd/MM/yyyy HH:mm',
  }) {
    return DateFormat(pattern, 'vi_VN').format(dateTime);
  }

  /// Format thời gian
  static String formatTime(DateTime dateTime, {String pattern = 'HH:mm'}) {
    return DateFormat(pattern, 'vi_VN').format(dateTime);
  }

  /// Format th i gian theo d nh: 'HH:mm PM/AM'
  static String formatTimeWithAMPM(DateTime dateTime) {
    final hour = dateTime.hour;
    final minute = dateTime.minute;
    final isPM = hour >= 12;
    final hour12 = hour % 12 == 0 ? 12 : hour % 12;
    return '${hour12.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')} ${isPM ? 'PM' : 'AM'}';
  }

  static String formatTimeWith24Hour(DateTime dateTime) {
    final hour = dateTime.hour;
    final minute = dateTime.minute;
    return '${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}';
  }

  /// Kiểm tra xem có phải ngày hôm nay không
  static bool isToday(DateTime dateTime) {
    final now = DateTime.now();
    return dateTime.year == now.year &&
        dateTime.month == now.month &&
        dateTime.day == now.day;
  }

  /// Kiểm tra xem có phải ngày hôm qua không
  static bool isYesterday(DateTime dateTime) {
    final yesterday = DateTime.now().subtract(const Duration(days: 1));
    return dateTime.year == yesterday.year &&
        dateTime.month == yesterday.month &&
        dateTime.day == yesterday.day;
  }

  /// Kiểm tra xem có phải tuần này không
  static bool isThisWeek(DateTime dateTime) {
    final now = DateTime.now();
    final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
    final endOfWeek = startOfWeek.add(const Duration(days: 6));

    return dateTime.isAfter(startOfWeek.subtract(const Duration(days: 1))) &&
        dateTime.isBefore(endOfWeek.add(const Duration(days: 1)));
  }

  /// Kiểm tra xem có phải tháng này không
  static bool isThisMonth(DateTime dateTime) {
    final now = DateTime.now();
    return dateTime.year == now.year && dateTime.month == now.month;
  }

  /// Kiểm tra xem có phải năm này không
  static bool isThisYear(DateTime dateTime) {
    final now = DateTime.now();
    return dateTime.year == now.year;
  }

  /// Lấy ngày đầu tuần (Thứ 2)
  static DateTime getStartOfWeek(DateTime dateTime) {
    return dateTime.subtract(Duration(days: dateTime.weekday - 1));
  }

  /// Lấy ngày cuối tuần (Chủ nhật)
  static DateTime getEndOfWeek(DateTime dateTime) {
    return dateTime.add(Duration(days: 7 - dateTime.weekday));
  }

  /// Lấy ngày đầu tháng
  static DateTime getStartOfMonth(DateTime dateTime) {
    return DateTime(dateTime.year, dateTime.month, 1);
  }

  /// Lấy ngày cuối tháng
  static DateTime getEndOfMonth(DateTime dateTime) {
    return DateTime(dateTime.year, dateTime.month + 1, 0);
  }

  /// Lấy ngày đầu năm
  static DateTime getStartOfYear(DateTime dateTime) {
    return DateTime(dateTime.year, 1, 1);
  }

  /// Lấy ngày cuối năm
  static DateTime getEndOfYear(DateTime dateTime) {
    return DateTime(dateTime.year, 12, 31);
  }

  /// Tính tuổi từ ngày sinh
  static int calculateAge(DateTime birthDate) {
    final now = DateTime.now();
    int age = now.year - birthDate.year;

    if (now.month < birthDate.month ||
        (now.month == birthDate.month && now.day < birthDate.day)) {
      age--;
    }

    return age;
  }

  /// Thêm ngày làm việc (bỏ qua thứ 7, chủ nhật)
  static DateTime addWorkingDays(DateTime dateTime, int days) {
    DateTime result = dateTime;
    int daysToAdd = days;

    while (daysToAdd > 0) {
      result = result.add(const Duration(days: 1));
      if (result.weekday < 6) {
        // Thứ 2-6 (1-5)
        daysToAdd--;
      }
    }

    return result;
  }

  /// Kiểm tra xem có phải ngày làm việc không
  static bool isWorkingDay(DateTime dateTime) {
    return dateTime.weekday < 6; // Thứ 2-6
  }

  /// Kiểm tra xem có phải cuối tuần không
  static bool isWeekend(DateTime dateTime) {
    return dateTime.weekday >= 6; // Thứ 7, Chủ nhật
  }

  /// Lấy tên thứ trong tuần
  static String getWeekdayName(DateTime dateTime) {
    if (dateTime.day == DateTime.now().day &&
        dateTime.month == DateTime.now().month &&
        dateTime.year == DateTime.now().year) {
      return TransKeys.today.tr();
    }
    final weekdays = [
      TransKeys.monday.tr(),
      TransKeys.tuesday.tr(),
      TransKeys.wednesday.tr(),
      TransKeys.thursday.tr(),
      TransKeys.friday.tr(),
      TransKeys.saturday.tr(),
      TransKeys.sunday.tr(),
    ];
    return weekdays[dateTime.weekday - 1] +
        ' ' +
        DateTimeUtils.formatDate(dateTime);
  }

  /// Lấy tên tháng
  static String getMonthName(DateTime dateTime) {
    const months = [
      'Tháng 1',
      'Tháng 2',
      'Tháng 3',
      'Tháng 4',
      'Tháng 5',
      'Tháng 6',
      'Tháng 7',
      'Tháng 8',
      'Tháng 9',
      'Tháng 10',
      'Tháng 11',
      'Tháng 12',
    ];
    return months[dateTime.month - 1];
  }

  /// Chuyển đổi timestamp sang DateTime
  static DateTime fromTimestamp(int timestamp) {
    return DateTime.fromMillisecondsSinceEpoch(timestamp);
  }

  /// Chuyển đổi DateTime sang timestamp
  static int toTimestamp(DateTime dateTime) {
    return dateTime.millisecondsSinceEpoch;
  }

  /// Parse string thành DateTime với format tùy chỉnh
  static DateTime? parseDate(
    String dateString, {
    String pattern = 'dd/MM/yyyy',
  }) {
    try {
      return DateFormat(pattern, 'vi_VN').parse(dateString);
    } catch (e) {
      return null;
    }
  }

  /// So sánh hai ngày (bỏ qua thời gian)
  static bool isSameDate(DateTime date1, DateTime date2) {
    return date1.year == date2.year &&
        date1.month == date2.month &&
        date1.day == date2.day;
  }

  /// Tính số ngày giữa hai ngày
  static int daysBetween(DateTime date1, DateTime date2) {
    final difference = date2.difference(date1);
    return difference.inDays.abs();
  }

  /// Format thời gian theo ngữ cảnh (hôm nay, hôm qua, etc.)
  static String formatContextual(DateTime dateTime) {
    if (isToday(dateTime)) {
      return 'Hôm nay ${formatTime(dateTime)}';
    } else if (isYesterday(dateTime)) {
      return 'Hôm qua ${formatTime(dateTime)}';
    } else if (isThisWeek(dateTime)) {
      return '${getWeekdayName(dateTime)} ${formatTime(dateTime)}';
    } else if (isThisYear(dateTime)) {
      return formatDateTime(dateTime, pattern: 'dd/MM HH:mm');
    } else {
      return formatDateTime(dateTime);
    }
  }

  /// Tạo DateTime với thời gian bắt đầu ngày (00:00:00)
  static DateTime startOfDay(DateTime dateTime) {
    return DateTime(dateTime.year, dateTime.month, dateTime.day);
  }

  /// Tạo DateTime với thời gian kết thúc ngày (23:59:59)
  static DateTime endOfDay(DateTime dateTime) {
    return DateTime(dateTime.year, dateTime.month, dateTime.day, 23, 59, 59);
  }

  /// Kiểm tra xem DateTime có trong khoảng thời gian không
  static bool isInRange(DateTime dateTime, DateTime start, DateTime end) {
    return dateTime.isAfter(start) && dateTime.isBefore(end);
  }

  /// Lấy danh sách các ngày trong tháng
  static List<DateTime> getDaysInMonth(DateTime dateTime) {
    final firstDay = getStartOfMonth(dateTime);
    final lastDay = getEndOfMonth(dateTime);
    final days = <DateTime>[];

    for (int i = 0; i <= lastDay.day - firstDay.day; i++) {
      days.add(firstDay.add(Duration(days: i)));
    }

    return days;
  }

  /// Lấy danh sách các ngày trong tuần
  static List<DateTime> getDaysInWeek(DateTime dateTime) {
    final startOfWeek = getStartOfWeek(dateTime);
    final days = <DateTime>[];

    for (int i = 0; i < 7; i++) {
      days.add(startOfWeek.add(Duration(days: i)));
    }

    return days;
  }

  static DateTime? toDateTime(dynamic value) {
    if (value == null) return null;
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    if (value is int) return DateTime.fromMillisecondsSinceEpoch(value);
    if (value is String) {
      return DateTime.tryParse(value);
    }
    return null;
  }

  static DateTime nextInstanceOfTimeOfDay(TimeOfDay t, {DateTime? from}) {
    final now = from ?? DateTime.now();
    var scheduled = DateTime(now.year, now.month, now.day, t.hour, t.minute);
    if (scheduled.isBefore(now)) {
      scheduled = scheduled.add(const Duration(days: 1));
    }
    return scheduled;
  }

  static DateTime nextDailyFrom(DateTime reminderDate) {
    final n = DateTime.now().toLocal();
    final r = reminderDate.toLocal();

    if (r.isAfter(n)) return r;
    DateTime candidate = DateTime(
      n.year,
      n.month,
      n.day,
      r.hour,
      r.minute,
      r.second,
      r.millisecond,
      r.microsecond,
    );

    if (!candidate.isAfter(n)) {
      candidate = candidate.add(const Duration(days: 1));
    }
    return candidate;
  }

  static DateTime nextWeeklyFrom(DateTime reminderDate) {
    final n = DateTime.now().toLocal();
    final r = reminderDate.toLocal();

    if (r.isAfter(n)) return r;

    final int daysAhead = (r.weekday - n.weekday) % 7;
    DateTime candidate = DateTime(
      n.year,
      n.month,
      n.day,
    ).add(Duration(days: daysAhead));
    candidate = DateTime(
      candidate.year,
      candidate.month,
      candidate.day,
      r.hour,
      r.minute,
      0,
      0,
      0,
    );

    if (!candidate.isAfter(n)) {
      candidate = candidate.add(const Duration(days: 7));
    }
    return candidate;
  }

  static DateTime getNextReminderDate(
    DateTime reminderDate,
    Set<int> repeatDays, {
    DateTime? from,
  }) {
    if (repeatDays.isEmpty) {
      throw ArgumentError('repeatDays phải có ít nhất 1 giá trị (1..7)');
    }
    if (repeatDays.any((d) => d < 1 || d > 7)) {
      throw ArgumentError('repeatDays chỉ nhận các giá trị từ 1 đến 7');
    }

    final now = (from ?? DateTime.now()).toLocal();
    final reminderLocal = reminderDate.toLocal();

    final h = reminderLocal.hour;
    final m = reminderLocal.minute;
    final s = reminderLocal.second;
    final ms = reminderLocal.millisecond;

    final todayAtReminderTime = DateTime(
      now.year,
      now.month,
      now.day,
      h,
      m,
      s,
      ms,
    );

    int bestOffset = 7;

    for (final w in repeatDays) {
      var offset = (w - now.weekday) % 7;

      if (offset == 0 && todayAtReminderTime.isBefore(now)) {
        offset = 7;
      }

      if (offset < bestOffset) {
        bestOffset = offset;
      }
    }

    final baseDay = DateTime(
      now.year,
      now.month,
      now.day,
    ).add(Duration(days: bestOffset));
    return DateTime(baseDay.year, baseDay.month, baseDay.day, h, m, s, ms);
  }
}

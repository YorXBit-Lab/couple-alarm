import 'package:couple_note/core/constants/trans_keys.dart';
import 'package:couple_note/core/config/theme/app_colors.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

const String kAlarmPortName = 'alarm_port';

enum NotificationType {
  alarm('alarm'),
  reminder('reminder_notification'),
  invite('invitation_response');

  const NotificationType(this.value);

  final String value;

  static NotificationType fromString(String value) {
    switch (value) {
      case 'NotificationType.alarm':
        return NotificationType.alarm;
      case 'NotificationType.reminder':
        return NotificationType.reminder;
      case 'NotificationType.invite':
        return NotificationType.invite;
      default:
        return NotificationType.invite;
    }
  }
}

enum RecurringType {
  none('none'),
  daily('daily'),
  weekly('weekly');

  const RecurringType(this.value);

  final String value;

  static RecurringType fromString(String value) {
    switch (value) {
      case 'none':
        return RecurringType.none;
      case 'daily':
        return RecurringType.daily;
      case 'weekly':
        return RecurringType.weekly;
      default:
        return RecurringType.none;
    }
  }
}

enum ApprovalStatus {
  none('none'),
  accepted('accepted'),
  pending('pending'),
  rejected('rejected');

  const ApprovalStatus(this.value);

  final String value;

  static ApprovalStatus fromString(String value) {
    switch (value) {
      case 'none':
        return ApprovalStatus.none;
      case 'accepted':
        return ApprovalStatus.accepted;
      case 'pending':
        return ApprovalStatus.pending;
      case 'rejected':
        return ApprovalStatus.rejected;
      default:
        return ApprovalStatus.none;
    }
  }
}

enum AssigneeType {
  me,
  private,
  lover,
  couple;

  Color get color {
    switch (this) {
      case AssigneeType.me:
        return Colors.blue[400]!;
      case AssigneeType.lover:
        return Colors.red[400]!;
      case AssigneeType.couple:
        return AppColors.primary;
      case AssigneeType.private:
        return Colors.yellow[600]!;
    }
  }

  IconData get icon {
    switch (this) {
      case AssigneeType.me:
        return Icons.person;
      case AssigneeType.lover:
        return Icons.favorite;
      case AssigneeType.couple:
        return Icons.people;
      case AssigneeType.private:
        return Icons.lock;
    }
  }

  String get label {
    switch (this) {
      case AssigneeType.me:
        return TransKeys.mine.tr();
      case AssigneeType.lover:
        return TransKeys.lover.tr();
      case AssigneeType.couple:
        return TransKeys.couple.tr();
      case AssigneeType.private:
        return TransKeys.private.tr();
    }
  }

  String get description {
    switch (this) {
      case AssigneeType.me:
        return TransKeys.assignee_me_description.tr();
      case AssigneeType.lover:
        return TransKeys.assignee_lover_description.tr();
      case AssigneeType.couple:
        return TransKeys.assignee_couple_description.tr();
      case AssigneeType.private:
        return TransKeys.assignee_private_description.tr();
    }
  }
}

enum ActivityType { alarm, timer }

class RecentActivity {
  final String description;
  final DateTime timestamp;
  final ActivityType type;

  RecentActivity(this.description, this.timestamp, this.type);
}

enum SoundType {
  defaultSound('defaultSound'),
  customRecording('customRecording'),
  uploadedFile('uploadedFile');

  const SoundType(this.value);
  final String value;

  static SoundType fromString(String value) {
    switch (value.toLowerCase()) {
      case 'default_sound':
        return SoundType.defaultSound;
      case 'custom_recording':
        return SoundType.customRecording;
      case 'uploaded_file':
        return SoundType.uploadedFile;
      default:
        return SoundType.defaultSound;
    }
  }
}

extension SoundTypeExtension on SoundType {
  String get getLabel {
    switch (this) {
      case SoundType.defaultSound:
        return 'Âm mặc định';
      case SoundType.customRecording:
        return 'Ghi âm';
      case SoundType.uploadedFile:
        return 'Tệp tải lên';
    }
  }
}

enum ReminderStatus {
  doing('doing'),
  done('done'),
  overdue('overdue');

  const ReminderStatus(this.value);
  final String value;

  static ReminderStatus fromString(String value) {
    switch (value.toLowerCase()) {
      case 'doing':
        return ReminderStatus.doing;
      case 'done':
        return ReminderStatus.done;
      case 'overdue':
        return ReminderStatus.overdue;
      default:
        return ReminderStatus.doing;
    }
  }

  static String getLabel(ReminderStatus status) {
    switch (status) {
      case ReminderStatus.doing:
        return 'Đang làm';
      case ReminderStatus.done:
        return 'Đã dừng';
      case ReminderStatus.overdue:
        return 'Quá hạn';
    }
  }

  static String getDescription(ReminderStatus status) {
    switch (status) {
      case ReminderStatus.doing:
        return 'Báo thức đang được thực hiện';
      case ReminderStatus.done:
        return 'Báo thức đã được dừng';
      case ReminderStatus.overdue:
        return 'Báo thức đã quá hạn';
    }
  }
}

enum InvitationStatus {
  pending('pending'),
  accepted('accepted'),
  rejected('rejected'),
  expired('expired');

  const InvitationStatus(this.value);
  final String value;

  static InvitationStatus fromString(String value) {
    switch (value.toLowerCase()) {
      case 'pending':
        return InvitationStatus.pending;
      case 'accepted':
        return InvitationStatus.accepted;
      case 'rejected':
        return InvitationStatus.rejected;
      case 'expired':
        return InvitationStatus.expired;
      default:
        return InvitationStatus.pending;
    }
  }
}

// Error code
enum ErrorCode {
  // Authentication & Authorization
  userExited(1001, 'User exited'),
  usernameInvalid(1002, 'Username must be at least {min} characters'),
  userNotExited(1003, 'User not exited'),
  invalidKey(1004, 'Invalid key'),
  invalidPassword(1005, 'Invalid password'),
  unauthenticated(1006, 'Unauthenticated'),
  unauthorized(1007, 'You do not have permission'),
  tokenNotExited(1008, 'Your token does not exist'),
  roleNotExited(1009, 'Role not exited'),
  sessionExpired(1010, 'Session expired'),
  emailNotVerified(1011, 'Email not verified'),
  accountLocked(1012, 'Account locked'),
  accountSuspended(1013, 'Account suspended'),
  signInFailed(1014, "Login failed"),
  userNotSignedIn(1015, "User is not logged in"),

  // Business Logic
  coupleNotFound(2001, 'Couple not found'),
  alarmNotFound(2003, 'Alarm not found'),

  coupleAlreadyExists(3001, 'Couple already exists'),
  alarmConflict(3002, 'Alarm time conflict'),
  duplicateEntry(3003, 'Duplicate entry'),

  // Media & Storage
  mediaUploadFailed(4001, 'Media upload failed'),
  mediaDownloadFailed(4002, 'Media download failed'),
  storageQuotaExceeded(4003, 'Storage quota exceeded'),
  fileNotFound(4004, 'File not found'),
  fileSizeExceeded(4005, 'File size exceeded limit'),
  unsupportedFileType(4006, 'Unsupported file type'),
  imageProcessingFailed(4007, 'Image processing failed'),

  // Validation
  validationFailed(5001, 'Validation failed: {field}'),
  requiredFieldMissing(5002, 'Required field missing: {field}'),
  invalidFormat(5003, 'Invalid format: {field}'),
  valueTooLong(5004, 'Value too long: {field}'),
  valueTooShort(5005, 'Value too short: {field}'),
  invalidDateRange(5006, 'Invalid date range'),
  invalidEnumValue(5007, 'Invalid enum value for: {field}'),

  // Rate Limiting
  rateLimited(6001, 'Too many requests'),
  dailyLimitExceeded(6002, 'Daily limit exceeded'),

  // Network & Connectivity
  networkError(7001, 'Network error'),
  connectionTimeout(7002, 'Connection timeout'),
  noInternetConnection(7003, 'No internet connection'),
  serverError(7004, 'Server error'),
  serviceUnavailable(7005, 'Service unavailable'),
  firebaseUnavailable(7006, 'Firebase service unavailable'),

  // Device & Platform
  permissionDenied(8001, 'Permission denied'),
  deviceNotSupported(8002, 'Device not supported'),
  platformNotSupported(8003, 'Platform not supported'),
  cameraNotAvailable(8004, 'Camera not available'),
  locationNotAvailable(8005, 'Location not available'),
  notificationPermissionDenied(8006, 'Notification permission denied'),

  // Database & Cache
  databaseError(9001, 'Database error'),
  cacheError(9002, 'Cache error'),
  dataCorrupted(9003, 'Data corrupted'),
  firestoreWriteFailed(9004, 'Failed to write to Firestore'),
  firestoreReadFailed(9005, 'Failed to read from Firestore'),
  transactionFailed(9006, 'Firestore transaction failed'),

  unknown(9999, 'Unknown error occurred');

  final int code;
  final String message;

  const ErrorCode(this.code, this.message);
}

class FilterTab {
  final String key;
  final String label;
  final IconData icon;
  final bool isPartner;
  final int count;

  FilterTab({
    required this.key,
    required this.label,
    required this.icon,
    this.isPartner = false,
    this.count = 0,
  });
}

class AppTextStyles {
  static const heading = TextStyle(fontSize: 20, fontWeight: FontWeight.bold);
  static const headingSmall = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.bold,
  );

  static const title = TextStyle(fontSize: 16, fontWeight: FontWeight.w500);
  static const titleBold = TextStyle(fontSize: 16, fontWeight: FontWeight.bold);
  static const subtitle = TextStyle(fontSize: 14, fontWeight: FontWeight.w500);
  static const subtitleBold = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.bold,
  );

  static const body = TextStyle(fontSize: 12, fontWeight: FontWeight.normal);
  static const bodySmall = TextStyle(
    fontSize: 10,
    fontWeight: FontWeight.normal,
  );

  static const caption = TextStyle(fontSize: 8, color: Colors.grey);

  static const button = TextStyle(fontSize: 14, fontWeight: FontWeight.w600);
}

enum SyncStatus {
  synced,
  pending,
  failed;

  factory SyncStatus.fromString(String value) {
    switch (value) {
      case 'synced':
        return SyncStatus.synced;
      case 'pending':
        return SyncStatus.pending;
      case 'failed':
        return SyncStatus.failed;
      default:
        throw ArgumentError('Invalid sync status: $value');
    }
  }
}

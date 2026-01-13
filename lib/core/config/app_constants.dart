import 'package:couple_note/core/constants/trans_keys.dart';
import 'package:couple_note/presentation/themes/app_colors.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

const String kAlarmPortName = 'alarm_port';

enum NoteCategory { general, date, memory, plan }

enum NotificationType {
  alarm('alarm'),
  reminder('reminder_notification'),
  todo('todo_notification'),
  note('note_notification'),
  invite('invitation_response');

  const NotificationType(this.value);

  final String value;

  static NotificationType fromString(String value) {
    switch (value) {
      case 'NotificationType.alarm':
        return NotificationType.alarm;
      case 'NotificationType.reminder':
        return NotificationType.reminder;
      case 'NotificationType.todo':
        return NotificationType.todo;
      case 'NotificationType.note':
        return NotificationType.note;
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

enum ActivityType { todo, reminder, note, timer, sharedNote }

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
        return 'Nhắc nhở đang được thực hiện';
      case ReminderStatus.done:
        return 'Nhắc nhở đã được dừng';
      case ReminderStatus.overdue:
        return 'Nhắc nhở đã quá hạn';
    }
  }
}

enum TodoStatus {
  doing(Color.fromARGB(255, 197, 179, 20), 'doing'),
  completed(Color.fromARGB(255, 71, 206, 30), 'completed'),
  overdue(Color.fromARGB(255, 214, 90, 82), 'overdue');

  const TodoStatus(this.color, this.value);
  final Color color;
  final String value;

  static TodoStatus fromString(String value) {
    switch (value.toLowerCase()) {
      case 'doing':
        return TodoStatus.doing;
      case 'completed':
        return TodoStatus.completed;
      case 'overdue':
        return TodoStatus.overdue;
      default:
        return TodoStatus.doing;
    }
  }

  static String getLabel(TodoStatus status) {
    switch (status) {
      case TodoStatus.doing:
        return TransKeys.doing.tr();
      case TodoStatus.completed:
        return TransKeys.complete.tr();
      case TodoStatus.overdue:
        return TransKeys.overdue.tr();
    }
  }

  static String getDescription(TodoStatus status) {
    switch (status) {
      case TodoStatus.doing:
        return TransKeys.todo_in_progress.tr();
      case TodoStatus.completed:
        return TransKeys.todo_has_been_completed.tr();
      case TodoStatus.overdue:
        return TransKeys.todo_is_overdue.tr();
    }
  }
}

enum TodoPriority {
  normal(Color.fromARGB(255, 159, 238, 163), 'normal'),
  medium(Color.fromARGB(255, 233, 170, 75), 'medium'),
  high(Color.fromARGB(255, 214, 90, 82), 'high');

  const TodoPriority(this.color, this.value);
  final Color color;
  final String value;

  static TodoPriority fromString(String value) {
    switch (value.toLowerCase()) {
      case 'normal':
        return TodoPriority.normal;
      case 'medium':
        return TodoPriority.medium;
      case 'high':
        return TodoPriority.high;
      default:
        return TodoPriority.normal;
    }
  }

  static String getLabel(TodoPriority priority) {
    switch (priority) {
      case TodoPriority.normal:
        return TransKeys.low.tr();
      case TodoPriority.medium:
        return TransKeys.medium.tr();
      case TodoPriority.high:
        return TransKeys.high.tr();
    }
  }

  static String getDescription(TodoPriority priority) {
    switch (priority) {
      case TodoPriority.normal:
        return TransKeys.low_sub.tr();
      case TodoPriority.medium:
        return TransKeys.medium_sub.tr();
      case TodoPriority.high:
        return TransKeys.high_sub.tr();
    }
  }
}

enum NotePriority {
  normal(Color.fromARGB(255, 159, 238, 163), 'normal'),
  medium(Color.fromARGB(255, 233, 170, 75), 'medium'),
  high(Color.fromARGB(255, 214, 90, 82), 'high');

  const NotePriority(this.color, this.value);
  final Color color;
  final String value;

  static NotePriority fromString(String value) {
    switch (value.toLowerCase()) {
      case 'normal':
        return NotePriority.normal;
      case 'medium':
        return NotePriority.medium;
      case 'high':
        return NotePriority.high;
      default:
        return NotePriority.normal;
    }
  }

  static String getLabel(NotePriority priority) {
    switch (priority) {
      case NotePriority.normal:
        return TransKeys.low.tr();
      case NotePriority.medium:
        return TransKeys.medium.tr();
      case NotePriority.high:
        return TransKeys.high.tr();
    }
  }

  static String getDescription(NotePriority priority) {
    switch (priority) {
      case NotePriority.normal:
        return TransKeys.low_note_sub.tr();
      case NotePriority.medium:
        return TransKeys.medium_note_sub.tr();
      case NotePriority.high:
        return TransKeys.high_note_sub.tr();
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
  noteNotFound(2002, 'Note not found'),
  reminderNotFound(2003, 'Reminder not found'),
  todoNotFound(2004, 'Todo not found'),

  coupleAlreadyExists(3001, 'Couple already exists'),
  reminderConflict(3002, 'Reminder time conflict'),
  duplicateEntry(3003, 'Duplicate entry'),
  noteTitleRequired(3101, 'Note title is required'),
  noteOwnerRequired(3102, 'Note ownerId is required'),
  noteTitleTooLong(3103, 'Note title is too long'),

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

enum TodoType { personal, shared }

class TodoConversionHelper {
  static Map<String, dynamic> convertTodoTypeToNewModel({
    required TodoType type,
    required bool isPrivate,
    required String currentUserId,
    required String? partnerId,
  }) {
    switch (type) {
      case TodoType.personal:
        return {
          'category': 'personal',
          'isPrivate': false,
          'assignedTo': null,
          'status': ApprovalStatus.pending,
        };
      case TodoType.shared:
        return {
          'category': 'shared',
          'isPrivate': true,
          'assignedTo': partnerId,
          'status': ApprovalStatus.pending,
        };
    }
  }
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

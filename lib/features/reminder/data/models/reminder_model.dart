import 'package:couple_note/core/config/app_constants.dart';
import 'package:couple_note/core/utils/datetime_utils.dart';
import 'package:couple_note/features/reminder/domain/entities/reminder.dart';

class ReminderModel extends ReminderEntity {
  ReminderModel({
    required super.id,
    required super.alarmId,
    required super.ownerId,
    required super.title,
    required super.reminderDate,
    required super.days,
    required super.isVibrate,
    required super.isSound,
    // super.soundUrl,
    // super.soundName,
    // super.soundType,
    required super.createdBy,
    required super.recurringType,
    required super.approvalStatus,
    required super.reminderStatus,
    required super.partnerReminderStatus,
    required super.isPrivate,
    required super.createdAt,
    super.updatedAt,
    super.deletedBy = const [],

    super.syncStatus = SyncStatus.synced,
  });

  factory ReminderModel.fromMap(Map<String, dynamic> map, String id) {
    return ReminderModel(
      id: id,
      alarmId: map['alarmId'] as int?,
      ownerId: map['ownerId'] ?? '',
      title: map['title'] ?? '',
      createdAt: DateTimeUtils.toDateTime(map['createdAt']),
      updatedAt: DateTimeUtils.toDateTime(map['updatedAt']),
      reminderDate:
          DateTimeUtils.toDateTime(map['reminderDate']) ?? DateTime.now(),
      days: map['days'] != null ? List<int>.from(map['days']).toSet() : <int>{},
      isVibrate: map['isVibrate'] as bool? ?? true,
      isSound: map['isSound'] as bool? ?? true,
      // soundUrl: map['soundUrl'] as String? ?? '',
      // soundName: map['soundName'] as String? ?? '',
      // soundType: map['soundType'] != null
      //     ? SoundType.fromString(map['soundType'])
      //     : SoundType.defaultSound,
      createdBy: map['createdBy'] as String? ?? '',
      deletedBy: map['deletedBy'] != null
          ? List<String>.from(map['deletedBy'])
          : [],
      recurringType: map['recurringType'] != null
          ? RecurringType.fromString(map['recurringType'])
          : RecurringType.none,
      approvalStatus: map['approvalStatus'] != null
          ? ApprovalStatus.fromString(map['approvalStatus'])
          : ApprovalStatus.none,
      reminderStatus: map['reminderStatus'] != null
          ? ReminderStatus.fromString(map['reminderStatus'])
          : ReminderStatus.done,
      partnerReminderStatus: map['partnerReminderStatus'] != null
          ? ReminderStatus.fromString(map['partnerReminderStatus'])
          : ReminderStatus.done,
      isPrivate: map['isPrivate'] as bool? ?? true,

      syncStatus: SyncStatus.synced,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'ownerId': ownerId,
      'alarmId': alarmId,
      'title': title,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
      'reminderDate': reminderDate,
      'days': days,
      'isVibrate': isVibrate,
      'isSound': isSound,
      // 'soundUrl': soundUrl,
      // 'soundName': soundName,
      // 'soundType': soundType?.value,
      'createdBy': createdBy,
      'deletedBy': deletedBy,
      'recurringType': recurringType.value,
      'approvalStatus': approvalStatus?.value,
      'reminderStatus': reminderStatus.value,
      'partnerReminderStatus': partnerReminderStatus?.value,
      'isPrivate': isPrivate,
    };
  }
}

import 'package:couple_note/core/config/app_constants.dart';

class ReminderEntity {
  final String id;
  final int? alarmId;
  final String ownerId;
  final String title;
  final DateTime reminderDate;
  final Set<int>? days;
  final bool isVibrate;
  final bool isSound;
  // final String? soundUrl;
  // final String? soundName;
  // final SoundType? soundType;
  final String createdBy;
  final RecurringType recurringType;
  final ApprovalStatus? approvalStatus;
  final ReminderStatus reminderStatus;
  final ReminderStatus? partnerReminderStatus;
  final bool isPrivate;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final List<String> deletedBy;
  final SyncStatus syncStatus;

  ReminderEntity({
    required this.id,
    required this.alarmId,
    required this.ownerId,
    required this.title,
    required this.reminderDate,
    required this.days,
    this.isVibrate = true,
    this.isSound = true,
    // this.soundUrl,
    // this.soundName,
    // this.soundType,
    required this.createdBy,
    required this.recurringType,
    required this.approvalStatus,
    required this.reminderStatus,
    this.partnerReminderStatus,
    required this.isPrivate,
    required this.createdAt,
    this.updatedAt,
    this.deletedBy = const [],
    this.syncStatus = SyncStatus.synced,
  });

  ReminderEntity copyWith({
    String? id,
    int? alarmId,
    String? ownerId,
    String? title,
    String? description,
    DateTime? reminderDate,
    Set<int>? days,
    bool? isVibrate,
    bool? isSound,
    // String? soundUrl,
    // String? soundName,
    // SoundType? soundType,
    String? createdBy,
    RecurringType? recurringType,
    ApprovalStatus? approvalStatus,
    ReminderStatus? reminderStatus,
    ReminderStatus? partnerReminderStatus,
    bool? isPrivate,
    DateTime? createdAt,
    DateTime? updatedAt,
    List<String>? deletedBy,
    SyncStatus? syncStatus,
  }) {
    return ReminderEntity(
      id: id ?? this.id,
      alarmId: alarmId ?? this.alarmId,
      ownerId: ownerId ?? this.ownerId,
      title: title ?? this.title,
      reminderDate: reminderDate ?? this.reminderDate,
      days: days ?? this.days,
      isVibrate: isVibrate ?? this.isVibrate,
      isSound: isSound ?? this.isSound,
      // soundUrl: soundUrl ?? this.soundUrl,
      // soundName: soundName ?? this.soundName,
      // soundType: soundType ?? this.soundType,
      createdBy: createdBy ?? this.createdBy,
      deletedBy: deletedBy ?? this.deletedBy,
      recurringType: recurringType ?? this.recurringType,
      approvalStatus: approvalStatus ?? this.approvalStatus,
      reminderStatus: reminderStatus ?? this.reminderStatus,
      partnerReminderStatus:
          partnerReminderStatus ?? this.partnerReminderStatus,
      isPrivate: isPrivate ?? this.isPrivate,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      syncStatus: syncStatus ?? this.syncStatus,
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

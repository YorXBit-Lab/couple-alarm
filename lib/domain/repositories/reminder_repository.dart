import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:couple_note/core/common/api_response.dart';
import 'package:couple_note/core/config/app_constants.dart';
import 'package:couple_note/domain/entities/reminder.dart';

class ReminderFilterOptions {
  final List<String>? approvalStatus;
  final List<String>? reminderStatus;
  final List<String>? tags;
  final RecurringType? recurringType;
  final DateTime? remindAtStart;
  final DateTime? remindAtEnd;
  final DateTime? createdAtStart;
  final DateTime? createdAtEnd;
  final String? sortBy;
  final bool? ascending;
  final int? limit;
  final DocumentSnapshot? lastDocument;
  final String? createdBy;
  final String? searchKeyword;
  final String? ownerId;

  const ReminderFilterOptions({
    this.approvalStatus,
    this.reminderStatus,
    this.tags,
    this.recurringType,
    this.remindAtStart,
    this.remindAtEnd,
    this.createdAtStart,
    this.createdAtEnd,
    this.sortBy,
    this.ascending,
    this.limit,
    this.lastDocument,
    this.createdBy,
    this.searchKeyword,
    this.ownerId,
  });

  ReminderFilterOptions copyWith({
    List<String>? approvalStatus,
    List<String>? reminderStatus,
    List<String>? tags,
    RecurringType? recurringType,
    DateTime? remindAtStart,
    DateTime? remindAtEnd,
    String? sortBy,
    bool? ascending,
    int? limit,
    DocumentSnapshot? lastDocument,
    String? createdBy,
    String? searchKeyword,
    String? ownerId,
  }) {
    return ReminderFilterOptions(
      approvalStatus: approvalStatus ?? this.approvalStatus,
      reminderStatus: reminderStatus ?? this.reminderStatus,
      tags: tags ?? this.tags,
      recurringType: recurringType ?? this.recurringType,
      createdAtStart: createdAtStart ?? this.createdAtStart,
      createdAtEnd: createdAtEnd ?? this.createdAtEnd,
      remindAtStart: remindAtStart ?? this.remindAtStart,
      remindAtEnd: remindAtEnd ?? this.remindAtEnd,
      sortBy: sortBy ?? this.sortBy,
      ascending: ascending ?? this.ascending,
      limit: limit ?? this.limit,
      lastDocument: lastDocument ?? this.lastDocument,
      createdBy: createdBy ?? this.createdBy,
      searchKeyword: searchKeyword ?? this.searchKeyword,
      ownerId: ownerId ?? this.ownerId,
    );
  }

  @override
  String toString() {
    return 'ReminderFilterOptions(status: $approvalStatus, reminderStatus: $reminderStatus, tags: $tags, '
        'remindAtStart: $remindAtStart, remindAtEnd: $remindAtEnd, '
        'sortBy: $sortBy, ascending: $ascending, limit: $limit, '
        'createdBy: $createdBy, ownerId: $ownerId, search: $searchKeyword, ';
  }
}

abstract class ReminderRepository {
  Future<ApiResponse<List<ReminderEntity>>> getRemindersByUser(String userId);
  Future<ApiResponse<ReminderEntity>> getReminderById(String id);
  Future<ApiResponse<ReminderEntity>> getReminderByAlarmId(int id);
  Future<ApiResponse<List<ReminderEntity>>> getAllReminders();
  Future<ApiResponse<ReminderEntity>> createReminder(ReminderEntity reminder);
  Future<ApiResponse<ReminderEntity>> updateReminder(ReminderEntity reminder);
  Future<ApiResponse<void>> deleteReminder(
    ReminderEntity reminder,
    String userId,
  );

  Stream<ApiResponse<List<ReminderEntity>>> getRemindersWithFilter(
    String userId,
    ReminderFilterOptions filterOptions,
    String currentUserId,
  );

  Future<ApiResponse<void>> moveCoupleReminderToPersonal(
    String currentUserId,
    String loverId,
    String coupleId,
  );

  Future<ApiResponse<void>> deletePendingReminder(
    String currentUserId,
    String loverId,
  );

  // Future<ApiResponse<String>> getPlayableSound({
  //   required String reminderId,
  //   String? soundUrl,
  // });
  //   Future<ApiResponse<Map<String, String>>> uploadAndCacheReminderSound({
  //   required String filePath,
  //   required String reminderId,
  //   required String userId,
  // });
}

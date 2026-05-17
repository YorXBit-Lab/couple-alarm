import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:couple_note/core/common/api_response.dart';
import 'package:couple_note/core/config/app_constants.dart';
import 'package:couple_note/core/errors/app_exception.dart';
import 'package:couple_note/core/errors/exception_handler.dart';
import 'package:couple_note/core/services/alarm/alarm_service.dart';
import 'package:couple_note/core/services/connectivity_service.dart';
import 'package:couple_note/core/utils/error_logger.dart';
import 'package:couple_note/features/reminder/domain/entities/reminder.dart';
import 'package:couple_note/features/reminder/domain/repository/reminder_repository.dart';
import 'package:couple_note/features/reminder/data/models/reminder_model.dart';

class ReminderRepositoryImpl implements ReminderRepository {
  final FirebaseFirestore firestore;
  final ConnectivityService connectivityService;

  ReminderRepositoryImpl(this.firestore, this.connectivityService);

  static const _collection = 'reminders';
  static const _soundStoragePath = 'alarm_sounds';

  bool _isFromCache(DocumentSnapshot doc) {
    return doc.metadata.isFromCache;
  }

  bool _hasPendingWrites(DocumentSnapshot doc) {
    return doc.metadata.hasPendingWrites;
  }

  // ---------------- Basic CRUD (converted to Streams) ----------------

  @override
  Future<ApiResponse<List<ReminderEntity>>> getRemindersByUser(
    String userId,
  ) async {
    try {
      if (userId.isEmpty) {
        throw ThrowException(
          ErrorCode.validationFailed,
          attributes: {'field': 'userId'},
        );
      }

      final userRemindersSnapshot = await firestore
          .collection(_collection)
          .where('ownerId', isEqualTo: userId)
          .get();

      final reminders = userRemindersSnapshot.docs
          .map((doc) => ReminderModel.fromMap(doc.data(), doc.id))
          .toList();
      return ApiResponse.success(reminders);
    } catch (e, stackTrace) {
      final exception = ExceptionHandler.handle(e, stackTrace);
      ErrorLogger.log(exception);
      return ApiResponse.failure(exception);
    }
  }

  @override
  Future<ApiResponse<ReminderEntity>> getReminderById(String id) async {
    try {
      if (id.isEmpty) {
        throw ThrowException(
          ErrorCode.validationFailed,
          attributes: {'field': 'id'},
        );
      }

      final doc = await firestore.collection(_collection).doc(id).get();

      if (!doc.exists) {
        throw ThrowException(ErrorCode.alarmNotFound);
      }

      final data = doc.data();
      if (data == null) {
        throw ThrowException(ErrorCode.dataCorrupted);
      }

      final reminder = ReminderModel.fromMap(data, doc.id);
      ErrorLogger.logInfo('Successfully retrieved reminder with id: $id');
      return ApiResponse.success(reminder);
    } catch (e, stackTrace) {
      final exception = ExceptionHandler.handle(e, stackTrace);
      ErrorLogger.log(exception);
      return ApiResponse.failure(exception);
    }
  }

  @override
  Future<ApiResponse<ReminderEntity>> getReminderByAlarmId(int alarmId) async {
    try {
      if (alarmId == 0) {
        throw ThrowException(
          ErrorCode.validationFailed,
          attributes: {'field': 'id'},
        );
      }

      final querySnapshot = await firestore
          .collection(_collection)
          .where('alarmId', isEqualTo: alarmId)
          .get();

      final doc = querySnapshot.docs.isNotEmpty
          ? querySnapshot.docs.first
          : null;

      if (!doc!.exists) {
        throw ThrowException(ErrorCode.alarmNotFound);
      }

      final reminder = ReminderModel.fromMap(doc.data(), doc.id);
      ErrorLogger.logInfo(
        'Successfully retrieved reminder with alarmId: $alarmId',
      );
      return ApiResponse.success(reminder);
    } catch (e, stackTrace) {
      final exception = ExceptionHandler.handle(e, stackTrace);
      ErrorLogger.log(exception);
      return ApiResponse.failure(exception);
    }
  }

  @override
  Future<ApiResponse<List<ReminderEntity>>> getAllReminders() async {
    try {
      final snapshot = await firestore.collection(_collection).get();

      final reminders = snapshot.docs
          .map((doc) => ReminderModel.fromMap(doc.data(), doc.id))
          .toList();

      return ApiResponse.success(reminders);
    } catch (e, stackTrace) {
      final exception = ExceptionHandler.handle(e, stackTrace);
      ErrorLogger.log(exception);
      return ApiResponse.failure(exception);
    }
  }

  @override
  Future<ApiResponse<ReminderEntity>> createReminder(ReminderEntity r) async {
    try {
      _validateReminderEntity(r);

      final isOnline = connectivityService.isOnline;
      final ref = firestore.collection(_collection).doc();

      final model = ReminderModel(
        id: ref.id,
        alarmId: r.alarmId,
        ownerId: r.ownerId,
        title: r.title,
        reminderDate: r.reminderDate,
        days: r.days,
        isVibrate: r.isVibrate,
        isSound: r.isSound,
        createdBy: r.createdBy,
        recurringType: r.recurringType,
        createdAt: r.createdAt,
        updatedAt: r.updatedAt,
        approvalStatus: r.approvalStatus,
        reminderStatus: r.reminderStatus,
        partnerReminderStatus: r.partnerReminderStatus,
        // soundUrl: r.soundUrl,
        // soundName: r.soundName,
        // soundType: r.soundType,
        isPrivate: r.isPrivate,
      );

      if (isOnline) {
        await ref.set(model.toMap());
      } else {
        ref.set(model.toMap());
      }

      return ApiResponse.success(
        model,
        metadata: {'isOnline': isOnline, 'syncStatus': model.syncStatus.name},
      );
    } catch (e, st) {
      final ex = ExceptionHandler.handle(e, st);
      ErrorLogger.log(ex);
      return ApiResponse.failure(ex);
    }
  }

  @override
  Future<ApiResponse<ReminderEntity>> updateReminder(ReminderEntity r) async {
    try {
      _validateReminderEntity(r);

      if (r.id.isEmpty) {
        throw ThrowException(
          ErrorCode.validationFailed,
          attributes: {'field': 'id'},
        );
      }

      final isOnline = connectivityService.isOnline;
      final ref = firestore.collection(_collection).doc(r.id);

      if (isOnline) {
        final existingDoc = await ref.get();
        if (!existingDoc.exists) {
          throw ThrowException(ErrorCode.alarmNotFound);
        }
      }

      final model = ReminderModel(
        id: r.id,
        alarmId: r.alarmId,
        ownerId: r.ownerId,
        title: r.title,
        reminderDate: r.reminderDate,
        days: r.days,
        isVibrate: r.isVibrate,
        isSound: r.isSound,
        createdBy: r.createdBy,
        reminderStatus: r.reminderStatus,
        partnerReminderStatus: r.partnerReminderStatus,
        createdAt: r.createdAt,
        isPrivate: r.isPrivate,
        approvalStatus: r.approvalStatus,
        recurringType: r.recurringType,
        updatedAt: DateTime.now(),
      );

      if (isOnline) {
        await ref.set(model.toMap(), SetOptions(merge: true));
      } else {
        ref.set(model.toMap(), SetOptions(merge: true));
      }

      return ApiResponse.success(
        model,
        metadata: {'isOnline': isOnline, 'syncStatus': model.syncStatus.name},
      );
    } catch (e, st) {
      print('Lỗi khi cập nhật reminder: ${e.toString()}');
      final ex = ExceptionHandler.handle(e, st);
      ErrorLogger.log(ex);
      return ApiResponse.failure(ex);
    }
  }

  @override
  Future<ApiResponse<void>> deleteReminder(
    ReminderEntity reminder,
    String userId,
  ) async {
    try {
      if (reminder.id.isEmpty) {
        throw ThrowException(
          ErrorCode.validationFailed,
          attributes: {'field': 'id'},
        );
      }

      final isOnline = connectivityService.isOnline;
      final ref = firestore.collection(_collection).doc(reminder.id);
      final isCoupleReminder = reminder.ownerId != userId;
      final alarmId = reminder.alarmId ?? 0;

      if (isOnline) {
        final doc = await ref.get();

        if (!doc.exists) {
          throw ThrowException(ErrorCode.alarmNotFound);
        }

        if (isCoupleReminder) {
          final data = doc.data();
          if (data == null) {
            throw ThrowException(ErrorCode.alarmNotFound);
          }

          final deletedBy = data['deletedBy'] != null
              ? List<String>.from(data['deletedBy'])
              : [];

          final createdBy = data['createdBy'] as String?;
          final reminderStatusStr = data['reminderStatus'] as String?;
          final partnerReminderStatusStr =
              data['partnerReminderStatus'] as String?;

          final isCreator = createdBy == userId;
          final currentUserStatus = isCreator
              ? (reminderStatusStr != null
                    ? ReminderStatus.fromString(reminderStatusStr)
                    : null)
              : (partnerReminderStatusStr != null
                    ? ReminderStatus.fromString(partnerReminderStatusStr)
                    : null);

          final partnerStatus = isCreator
              ? (partnerReminderStatusStr != null
                    ? ReminderStatus.fromString(partnerReminderStatusStr)
                    : null)
              : (reminderStatusStr != null
                    ? ReminderStatus.fromString(reminderStatusStr)
                    : null);

          final shouldDelete =
              (partnerStatus != null &&
                  partnerStatus != ReminderStatus.doing) ||
              (deletedBy.isNotEmpty);

          if (shouldDelete) {
            if (currentUserStatus == ReminderStatus.doing) {
              await AlarmService.cancel(alarmId);
            }
            await ref.delete();
          } else {
            if (currentUserStatus == ReminderStatus.doing) {
              await AlarmService.cancel(alarmId);
            }
            await ref.update({'deletedBy': deletedBy..add(userId)});
          }
        } else {
          if (reminder.reminderStatus == ReminderStatus.doing) {
            await AlarmService.cancel(alarmId);
          }
          await ref.delete();
        }
      } else {
        if (isCoupleReminder) {
          if (reminder.reminderStatus == ReminderStatus.doing) {
            await AlarmService.cancel(alarmId);
          }
          ref.update({'deletedBy': reminder.deletedBy..add(userId)});
        } else {
          if (reminder.reminderStatus == ReminderStatus.doing) {
            await AlarmService.cancel(alarmId);
          }
          ref.delete();
        }
      }

      return ApiResponse.success(null);
    } catch (e, st) {
      final ex = ExceptionHandler.handle(e, st);
      ErrorLogger.log(ex);
      return ApiResponse.failure(ex);
    }
  }

  Future<ApiResponse<List<String>>> getUserTags(String userId) async {
    try {
      final querySnapshot = await firestore
          .collection(_collection)
          .where('ownerId', isEqualTo: userId)
          .get();

      final allTags = <String>{};
      for (final doc in querySnapshot.docs) {
        final data = doc.data();
        final tags = List<String>.from(data['tags'] ?? []);
        allTags.addAll(tags);
      }

      return ApiResponse.success(allTags.toList()..sort());
    } catch (e) {
      final exception = ExceptionHandler.handle(e);
      ErrorLogger.log(exception);
      return ApiResponse.failure(exception);
    }
  }

  // ---------------- Advanced Filter (converted to Stream) ----------------

  @override
  Stream<ApiResponse<List<ReminderEntity>>> getRemindersWithFilter(
    String userId,
    ReminderFilterOptions filterOptions,
    String currentUserId,
  ) async* {
    try {
      if (userId.isEmpty) {
        yield ApiResponse.failure(
          ThrowException(
                ErrorCode.validationFailed,
                attributes: {'field': 'userId'},
              )
              as AppException,
        );
        return;
      }

      Query<Map<String, dynamic>> query = firestore
          .collection(_collection)
          .where('ownerId', isEqualTo: userId);

      query = _applyFirestoreFilters(query, filterOptions, currentUserId);

      yield* query.snapshots(includeMetadataChanges: true).map((snapshot) {
        try {
          List<ReminderEntity> reminders = snapshot.docs
              .where((doc) {
                if (currentUserId.isEmpty) return true;

                final data = doc.data();
                final deletedBy = data['deletedBy'] as List<dynamic>?;
                final approvalStatus = data['approvalStatus'] as String?;
                final createdBy = data['createdBy'] as String?;

                if (deletedBy != null &&
                    deletedBy.isNotEmpty &&
                    deletedBy.contains(currentUserId)) {
                  return false;
                }

                if (approvalStatus == 'rejected' &&
                    createdBy != currentUserId) {
                  return false;
                }
                print(approvalStatus);
                return true;
              })
              .map((doc) {
                final reminder = ReminderModel.fromMap(doc.data(), doc.id);

                if (_hasPendingWrites(doc)) {
                  return reminder.copyWith(syncStatus: SyncStatus.pending);
                }

                return reminder;
              })
              .toList();

          final uniqueReminders = {
            for (var reminder in reminders) reminder.id: reminder,
          };

          return ApiResponse.success(uniqueReminders.values.toList());
        } catch (e, st) {
          print('Error processing reminders: $e');
          final ex = ExceptionHandler.handle(e, st);
          ErrorLogger.log(ex);
          return ApiResponse.failure(ex);
        }
      });
    } catch (e, st) {
      final ex = ExceptionHandler.handle(e, st);
      ErrorLogger.log(ex);
      yield ApiResponse.failure(ex);
    }
  }

  Query<Map<String, dynamic>> _applyFirestoreFilters(
    Query<Map<String, dynamic>> query,
    ReminderFilterOptions filterOptions,
    String currentUserId,
  ) {
    Query<Map<String, dynamic>> filteredQuery = query;

    // Single value filters (more efficient in Firestore)
    if (filterOptions.approvalStatus != null &&
        filterOptions.approvalStatus!.isNotEmpty) {
      if (filterOptions.approvalStatus!.length == 1) {
        filteredQuery = filteredQuery.where(
          'approvalStatus',
          isEqualTo: filterOptions.approvalStatus!.first,
        );
      } else {
        filteredQuery = filteredQuery.where(
          'approvalStatus',
          whereIn: filterOptions.approvalStatus,
        );
      }
    }

    if (filterOptions.reminderStatus != null &&
        filterOptions.reminderStatus!.isNotEmpty) {
      if (filterOptions.reminderStatus!.length == 1) {
        filteredQuery = filteredQuery.where(
          'reminderStatus',
          isEqualTo: filterOptions.reminderStatus!.first,
        );
      } else {
        filteredQuery = filteredQuery.where(
          'reminderStatus',
          whereIn: filterOptions.reminderStatus,
        );
      }
    }

    if (filterOptions.remindAtStart != null) {
      filteredQuery = filteredQuery.where(
        'reminderDate',
        isGreaterThanOrEqualTo: Timestamp.fromDate(
          filterOptions.remindAtStart!,
        ),
      );
    }

    if (filterOptions.remindAtEnd != null) {
      final endDate = filterOptions.remindAtEnd!.add(const Duration(days: 1));
      filteredQuery = filteredQuery.where(
        'reminderDate',
        isLessThan: Timestamp.fromDate(endDate),
      );
    }

    filteredQuery = filteredQuery.where('reminderDate', isNotEqualTo: null);

    if (filterOptions.createdAtStart != null) {
      filteredQuery = filteredQuery.where(
        'createdAt',
        isGreaterThanOrEqualTo: Timestamp.fromDate(
          filterOptions.createdAtStart!,
        ),
      );
    }

    if (filterOptions.createdAtEnd != null) {
      final endDate = filterOptions.createdAtEnd!.add(const Duration(days: 1));
      filteredQuery = filteredQuery.where(
        'createdAt',
        isLessThan: Timestamp.fromDate(endDate),
      );
    }

    if (filterOptions.tags != null && filterOptions.tags!.isNotEmpty) {
      if (filterOptions.tags!.length == 1) {
        filteredQuery = filteredQuery.where(
          'tags',
          arrayContains: filterOptions.tags!.first,
        );
      } else {
        filteredQuery = filteredQuery.where(
          'tags',
          arrayContainsAny: filterOptions.tags,
        );
      }
    }

    if (filterOptions.recurringType != null) {
      filteredQuery = filteredQuery.where(
        'recurringType',
        isEqualTo: filterOptions.recurringType!.name,
      );
    }

    if (filterOptions.sortBy != null) {
      final isAscending = filterOptions.ascending ?? true;

      switch (filterOptions.sortBy!) {
        case 'createdAt':
          filteredQuery = filteredQuery.orderBy(
            'createdAt',
            descending: !isAscending,
          );
          break;
        case 'reminderDate':
          filteredQuery = filteredQuery.orderBy(
            'reminderDate',
            descending: !isAscending,
          );
          break;
        case 'title':
          filteredQuery = filteredQuery.orderBy(
            'title',
            descending: !isAscending,
          );
          break;
      }
    }

    if (filterOptions.lastDocument != null) {
      filteredQuery = filteredQuery.startAfterDocument(
        filterOptions.lastDocument!,
      );
    }

    if (filterOptions.limit != null) {
      filteredQuery = filteredQuery.limit(filterOptions.limit!);
    }

    return filteredQuery;
  }

  void _validateReminderEntity(ReminderEntity r) {
    if (r.title.isEmpty) {
      throw ThrowException(
        ErrorCode.validationFailed,
        attributes: {'field': 'title'},
      );
    }
    if (r.title.length > 200) {
      throw ThrowException(
        ErrorCode.valueTooLong,
        attributes: {'field': 'title'},
      );
    }
    if (r.ownerId.isEmpty) {
      throw ThrowException(
        ErrorCode.validationFailed,
        attributes: {'field': 'ownerId'},
      );
    }
  }

  @override
  Future<ApiResponse<void>> moveCoupleReminderToPersonal(
    String currentUserId,
    String loverId,
    String coupleId,
  ) async {
    try {
      final coupleReminders = await firestore
          .collection(_collection)
          .where('ownerId', isEqualTo: coupleId)
          .get();

      if (coupleReminders.docs.isEmpty) {
        return ApiResponse.success(null);
      }

      final batch = firestore.batch();

      for (var doc in coupleReminders.docs) {
        final data = doc.data();
        final reminder = ReminderModel.fromMap(data, doc.id);

        final deletedBy = reminder.deletedBy ?? [];

        final isDeletedByCurrentUser = deletedBy.contains(currentUserId);

        final isDeletedByPartner = deletedBy.contains(loverId);

        final isCreatedByCurrentUser = reminder.createdBy == currentUserId;
        final isCreatedByPartner = reminder.createdBy == loverId;

        final approvalStatus = reminder.approvalStatus;
        final isRejected = approvalStatus == ApprovalStatus.rejected;

        bool shouldCreateForCurrentUser = false;
        bool shouldCreateForPartner = false;

        if (!isDeletedByCurrentUser) {
          if (isCreatedByCurrentUser) {
            shouldCreateForCurrentUser = true;
          } else if (!isRejected) {
            shouldCreateForCurrentUser = true;
          }
        }

        if (!isDeletedByPartner) {
          if (isCreatedByPartner) {
            shouldCreateForPartner = true;
          } else if (!isRejected) {
            shouldCreateForPartner = true;
          }
        }

        if (shouldCreateForCurrentUser) {
          final currentUserReminderRef = firestore
              .collection(_collection)
              .doc();

          ReminderStatus reminderStatusForCurrentUser;
          if (isCreatedByCurrentUser) {
            reminderStatusForCurrentUser = reminder.reminderStatus;
          } else {
            reminderStatusForCurrentUser =
                reminder.partnerReminderStatus ?? ReminderStatus.doing;
          }

          final personalReminderForCurrent = reminder.copyWith(
            ownerId: currentUserId,
            createdBy: currentUserId,
            deletedBy: [],
            reminderStatus: reminderStatusForCurrentUser,
            partnerReminderStatus: null,
            approvalStatus: ApprovalStatus.none,
          );
          batch.set(currentUserReminderRef, personalReminderForCurrent.toMap());
        }

        if (shouldCreateForPartner) {
          final partnerReminderRef = firestore.collection(_collection).doc();

          ReminderStatus reminderStatusForPartner;
          if (isCreatedByPartner) {
            reminderStatusForPartner = reminder.reminderStatus;
          } else {
            reminderStatusForPartner =
                reminder.partnerReminderStatus ?? ReminderStatus.doing;
          }

          final personalReminderForPartner = reminder.copyWith(
            ownerId: loverId,
            createdBy: loverId,
            deletedBy: [],
            reminderStatus: reminderStatusForPartner,
            partnerReminderStatus: null,
            approvalStatus: ApprovalStatus.none,
          );
          batch.set(partnerReminderRef, personalReminderForPartner.toMap());
        }

        batch.delete(doc.reference);
      }

      await batch.commit();
      return ApiResponse.success(null);
    } catch (e, st) {
      final ex = ExceptionHandler.handle(e, st);
      ErrorLogger.log(ex);
      return ApiResponse.failure(ex);
    }
  }

  @override
  Future<ApiResponse<void>> deletePendingReminder(
    String currentUserId,
    String loverId,
  ) async {
    try {
      final results = await Future.wait([
        firestore
            .collection(_collection)
            .where('ownerId', isEqualTo: loverId)
            .where('createdBy', isEqualTo: currentUserId)
            .where('approvalStatus', isEqualTo: ApprovalStatus.pending.value)
            .get(),

        firestore
            .collection(_collection)
            .where('ownerId', isEqualTo: currentUserId)
            .where('createdBy', isEqualTo: loverId)
            .where('approvalStatus', isEqualTo: ApprovalStatus.pending.value)
            .get(),
      ]);

      print(results);

      final allReminders = [...results[0].docs, ...results[1].docs];

      if (allReminders.isEmpty) {
        return ApiResponse.success(null);
      }

      const batchSize = 500;

      for (var i = 0; i < allReminders.length; i += batchSize) {
        final batch = firestore.batch();
        final batchDocs = allReminders.skip(i).take(batchSize);

        for (var doc in batchDocs) {
          batch.delete(doc.reference);
        }

        await batch.commit();
      }

      return ApiResponse.success(null);
    } catch (e, st) {
      final ex = ExceptionHandler.handle(e, st);
      ErrorLogger.log(ex);
      return ApiResponse.failure(ex);
    }
  }
  //Sound
  // Future<ApiResponse<String>> uploadReminderSound({
  //   required String filePath,
  //   required String reminderId,
  //   required String userId,
  // }) async {
  //   try {
  //     if (filePath.isEmpty) {
  //       throw ThrowException(
  //         ErrorCode.validationFailed,
  //         attributes: {'field': 'filePath'},
  //       );
  //     }

  //     if (reminderId.isEmpty) {
  //       throw ThrowException(
  //         ErrorCode.validationFailed,
  //         attributes: {'field': 'reminderId'},
  //       );
  //     }

  //     final isOnline = connectivityService.isOnline;
  //     if (!isOnline) {
  //       throw ThrowException(ErrorCode.networkError);
  //     }

  //     final file = File(filePath);
  //     if (!await file.exists()) {
  //       throw ThrowException(
  //         ErrorCode.validationFailed,
  //         attributes: {'message': 'File không tồn tại'},
  //       );
  //     }

  //     // Kiểm tra kích thước file (giới hạn 5MB)
  //     final fileSize = await file.length();
  //     if (fileSize > 5 * 1024 * 1024) {
  //       throw ThrowException(
  //         ErrorCode.valueTooLong,
  //         attributes: {'message': 'File vượt quá 5MB'},
  //       );
  //     }

  //     final timestamp = DateTime.now().millisecondsSinceEpoch;
  //     final fileName = '${userId}_${reminderId}_$timestamp.m4a';
  //     final ref = storage.ref().child(_soundStoragePath).child(fileName);

  //     final uploadTask = ref.putFile(
  //       file,
  //       SettableMetadata(
  //         contentType: 'audio/mp4',
  //         customMetadata: {
  //           'userId': userId,
  //           'reminderId': reminderId,
  //           'uploadedAt': DateTime.now().toIso8601String(),
  //         },
  //       ),
  //     );

  //     final snapshot = await uploadTask;

  //     final downloadUrl = await snapshot.ref.getDownloadURL();

  //     return ApiResponse.success(
  //       downloadUrl,
  //       metadata: {
  //         'fileName': fileName,
  //         'fileSize': fileSize,
  //         'path': ref.fullPath,
  //       },
  //     );
  //   } catch (e, stackTrace) {
  //     final exception = ExceptionHandler.handle(e, stackTrace);
  //     ErrorLogger.log(exception);
  //     return ApiResponse.failure(exception);
  //   }
  // }

  // Future<ApiResponse<void>> deleteReminderSound(String soundUrl) async {
  //   try {
  //     if (soundUrl.isEmpty) {
  //       throw ThrowException(
  //         ErrorCode.validationFailed,
  //         attributes: {'field': 'soundUrl'},
  //       );
  //     }

  //     final isOnline = connectivityService.isOnline;
  //     if (!isOnline) {
  //       throw ThrowException(ErrorCode.networkError);
  //     }

  //     final ref = storage.refFromURL(soundUrl);

  //     await ref.delete();

  //     return ApiResponse.success(null);
  //   } catch (e, stackTrace) {
  //     final exception = ExceptionHandler.handle(e, stackTrace);
  //     ErrorLogger.log(exception);
  //     return ApiResponse.failure(exception);
  //   }
  // }

  // Future<ApiResponse<String>> downloadReminderSound({
  //   required String soundUrl,
  //   required String reminderId,
  // }) async {
  //   try {
  //     if (soundUrl.isEmpty) {
  //       throw ThrowException(
  //         ErrorCode.validationFailed,
  //         attributes: {'field': 'soundUrl'},
  //       );
  //     }

  //     final isOnline = connectivityService.isOnline;
  //     if (!isOnline) {
  //       throw ThrowException(ErrorCode.networkError);
  //     }

  //     // Tạo đường dẫn local để lưu
  //     final appDir = await getApplicationDocumentsDirectory();
  //     final soundsDir = Directory('${appDir.path}/reminder_sounds');

  //     // Tạo thư mục nếu chưa có
  //     if (!await soundsDir.exists()) {
  //       await soundsDir.create(recursive: true);
  //     }

  //     final localPath = '${soundsDir.path}/${reminderId}_sound.m4a';
  //     final localFile = File(localPath);

  //     if (await localFile.exists()) {
  //       ErrorLogger.logInfo('Sound file already exists: $localPath');
  //       return ApiResponse.success(localPath);
  //     }

  //     // Download file
  //     final ref = storage.refFromURL(soundUrl);
  //     await ref.writeToFile(localFile);

  //     ErrorLogger.logInfo('Downloaded sound to: $localPath');

  //     return ApiResponse.success(localPath, metadata: {'soundUrl': soundUrl});
  //   } catch (e, stackTrace) {
  //     final exception = ExceptionHandler.handle(e, stackTrace);
  //     ErrorLogger.log(exception);
  //     return ApiResponse.failure(exception);
  //   }
  // }

  // Future<ApiResponse<ReminderEntity>> updateReminderWithSound({
  //   required String reminderId,
  //   required String soundUrl,
  //   String? soundName,
  // }) async {
  //   try {
  //     if (reminderId.isEmpty) {
  //       throw ThrowException(
  //         ErrorCode.validationFailed,
  //         attributes: {'field': 'reminderId'},
  //       );
  //     }

  //     final isOnline = connectivityService.isOnline;
  //     final ref = firestore.collection(_collection).doc(reminderId);

  //     final doc = await ref.get();
  //     if (!doc.exists) {
  //       throw ThrowException(ErrorCode.alarmNotFound);
  //     }

  //     final currentReminder = ReminderModel.fromMap(doc.data()!, doc.id);

  //     if (currentReminder.soundUrl != null &&
  //         currentReminder.soundUrl!.isNotEmpty &&
  //         currentReminder.soundUrl != soundUrl) {
  //       await deleteReminderSound(currentReminder.soundUrl!);
  //     }

  //     final updatedData = {
  //       'soundUrl': soundUrl,
  //       'soundName': soundName ?? 'Custom Sound',
  //       'updatedAt': FieldValue.serverTimestamp(),
  //     };

  //     if (isOnline) {
  //       await ref.update(updatedData);
  //     } else {
  //       ref.update(updatedData);
  //     }

  //     final updatedDoc = await ref.get();
  //     final updatedReminder = ReminderModel.fromMap(
  //       updatedDoc.data()!,
  //       updatedDoc.id,
  //     );

  //     return ApiResponse.success(
  //       updatedReminder,
  //       metadata: {'isOnline': isOnline},
  //     );
  //   } catch (e, stackTrace) {
  //     final exception = ExceptionHandler.handle(e, stackTrace);
  //     ErrorLogger.log(exception);
  //     return ApiResponse.failure(exception);
  //   }
  // }

  // Future<ApiResponse<void>> clearLocalSoundCache() async {
  //   try {
  //     final appDir = await getApplicationDocumentsDirectory();
  //     final soundsDir = Directory('${appDir.path}/reminder_sounds');

  //     if (await soundsDir.exists()) {
  //       await soundsDir.delete(recursive: true);
  //       ErrorLogger.logInfo('Cleared local sound cache');
  //     }

  //     return ApiResponse.success(null);
  //   } catch (e, stackTrace) {
  //     final exception = ExceptionHandler.handle(e, stackTrace);
  //     ErrorLogger.log(exception);
  //     return ApiResponse.failure(exception);
  //   }
  // }

  // Future<ApiResponse<Map<String, String>>> uploadAndCacheReminderSound({
  //   required String filePath,
  //   required String reminderId,
  //   required String userId,
  // }) async {
  //   try {
  //     final uploadResult = await uploadReminderSound(
  //       filePath: filePath,
  //       reminderId: reminderId,
  //       userId: userId,
  //     );

  //     final soundUrl = uploadResult.data!;

  //     final appDir = await getApplicationDocumentsDirectory();
  //     final soundsDir = Directory('${appDir.path}/reminder_sounds');

  //     if (!await soundsDir.exists()) {
  //       await soundsDir.create(recursive: true);
  //     }

  //     final localPath = '${soundsDir.path}/${reminderId}_sound.m4a';
  //     final sourceFile = File(filePath);
  //     final localFile = File(localPath);

  //     // Copy file sang thư mục cache
  //     await sourceFile.copy(localPath);

  //     ErrorLogger.logInfo('Cached sound locally: $localPath');

  //     return ApiResponse.success({
  //       'soundUrl': soundUrl,
  //       'localPath': localPath,
  //     });
  //   } catch (e, stackTrace) {
  //     final exception = ExceptionHandler.handle(e, stackTrace);
  //     ErrorLogger.log(exception);
  //     return ApiResponse.failure(exception);
  //   }
  // }

  // // Lấy file local để phát (ưu tiên local, fallback về download)
  // Future<ApiResponse<String>> getPlayableSound({
  //   required String reminderId,
  //   String? soundUrl,
  // }) async {
  //   try {
  //     final appDir = await getApplicationDocumentsDirectory();
  //     final localPath =
  //         '${appDir.path}/reminder_sounds/${reminderId}_sound.m4a';
  //     final localFile = File(localPath);

  //     if (await localFile.exists()) {
  //       ErrorLogger.logInfo('Using cached sound: $localPath');
  //       return ApiResponse.success(localPath);
  //     }

  //     if (soundUrl != null && soundUrl.isNotEmpty) {
  //       final isOnline = connectivityService.isOnline;

  //       if (!isOnline) {
  //         throw ThrowException(
  //           ErrorCode.networkError,
  //           attributes: {'message': 'File âm thanh chưa được tải về'},
  //         );
  //       }

  //       ErrorLogger.logWarning('Sound not cached, downloading: $soundUrl');

  //       return await downloadReminderSound(
  //         soundUrl: soundUrl,
  //         reminderId: reminderId,
  //       );
  //     }

  //     throw ThrowException(
  //       ErrorCode.validationFailed,
  //       attributes: {'message': 'Không tìm thấy file âm thanh'},
  //     );
  //   } catch (e, stackTrace) {
  //     final exception = ExceptionHandler.handle(e, stackTrace);
  //     ErrorLogger.log(exception);
  //     return ApiResponse.failure(exception);
  //   }
  // }
}

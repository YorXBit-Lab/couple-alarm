import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:couple_note/core/common/api_response.dart';
import 'package:couple_note/core/config/app_constants.dart';
import 'package:couple_note/core/errors/app_exception.dart';
import 'package:couple_note/core/errors/exception_handler.dart';
import 'package:couple_note/core/utils/error_logger.dart';
import 'package:couple_note/data/models/couple_model.dart';
import 'package:couple_note/domain/entities/couples.dart';
import 'package:couple_note/domain/entities/user.dart';
import 'package:couple_note/domain/repositories/couple_repository.dart';
import 'package:couple_note/domain/repositories/user_repository.dart';
import 'package:rxdart/rxdart.dart';

class CoupleRepositoryImpl implements CoupleRepository {
  final FirebaseFirestore firestore;
  static const String _collection = 'couples';
  final UserRepository userRepository;

  CoupleRepositoryImpl(this.firestore, this.userRepository);

  @override
  Stream<ApiResponse<UserEntity?>?> getPartner(String userId) {
    return firestore
        .collection(_collection)
        .snapshots()
        .asyncMap<String?>((snapshot) async {
          // Lấy partnerId từ couples collection
          try {
            final member1Docs = snapshot.docs.where((doc) {
              final data = doc.data();
              return data['member1'] == userId;
            }).toList();

            if (member1Docs.isNotEmpty) {
              final data = member1Docs.first.data();
              return data['member2'] as String?;
            }

            final member2Docs = snapshot.docs.where((doc) {
              final data = doc.data();
              return data['member2'] == userId;
            }).toList();

            if (member2Docs.isNotEmpty) {
              final data = member2Docs.first.data();
              return data['member1'] as String?;
            }

            return null;
          } catch (e) {
            return null;
          }
        })
        .switchMap((partnerId) {
          // ✅ switchMap để chuyển sang stream mới khi partnerId thay đổi
          if (partnerId == null || partnerId.isEmpty) {
            return Stream.value(ApiResponse<UserEntity?>.success(null));
          }

          return firestore
              .collection('users')
              .doc(partnerId)
              .snapshots()
              .asyncMap<ApiResponse<UserEntity?>?>((userDoc) async {
                try {
                  if (!userDoc.exists || userDoc.data() == null) {
                    throw ThrowException(ErrorCode.userNotExited);
                  }

                  // Convert sang UserEntity
                  final userData = userDoc.data()!;
                  final user = UserEntity.fromMap({
                    ...userData,
                    'uid': userDoc.id,
                  });

                  return ApiResponse<UserEntity?>.success(user);
                } catch (e, stackTrace) {
                  final exception = ExceptionHandler.handle(e, stackTrace);
                  ErrorLogger.log(exception);
                  return ApiResponse<UserEntity?>.failure(exception);
                }
              });
        })
        .handleError((error, stackTrace) {
          final exception = ExceptionHandler.handle(error, stackTrace);
          ErrorLogger.log(exception);
          return ApiResponse<UserEntity?>.failure(exception);
        });
  }

  @override
  Stream<ApiResponse<CoupleEntity?>> getCoupleByUserId(String userId) {
    return firestore
        .collection(_collection)
        .where('member1', isEqualTo: userId)
        .snapshots()
        .map<ApiResponse<CoupleEntity?>>((snapshot) {
          try {
            if (snapshot.docs.isNotEmpty) {
              final doc = snapshot.docs.first;
              return ApiResponse<CoupleEntity?>.success(
                CoupleModel.fromMap(doc.data(), doc.id),
              );
            }
            return ApiResponse<CoupleEntity?>.success(null);
          } catch (e, stackTrace) {
            final exception = ExceptionHandler.handle(e, stackTrace);
            ErrorLogger.log(exception);
            return ApiResponse<CoupleEntity?>.failure(exception);
          }
        })
        .switchMap((result) {
          if (result.data == null && result.isSuccess) {
            return firestore
                .collection(_collection)
                .where('member2', isEqualTo: userId)
                .snapshots()
                .map<ApiResponse<CoupleEntity?>>((snapshot) {
                  try {
                    if (snapshot.docs.isNotEmpty) {
                      final doc = snapshot.docs.first;
                      return ApiResponse<CoupleEntity?>.success(
                        CoupleModel.fromMap(doc.data(), doc.id),
                      );
                    }
                    return ApiResponse<CoupleEntity?>.success(null);
                  } catch (e, stackTrace) {
                    final exception = ExceptionHandler.handle(e, stackTrace);
                    ErrorLogger.log(exception);
                    return ApiResponse<CoupleEntity?>.failure(exception);
                  }
                });
          }
          return Stream.value(result);
        })
        .handleError((error, stackTrace) {
          final exception = ExceptionHandler.handle(error, stackTrace);
          ErrorLogger.log(exception);
          return ApiResponse<CoupleEntity?>.failure(exception);
        });
  }

  @override
  Future<ApiResponse<String?>> getCoupleIdByUserId(String userId) async {
    try {
      // Tìm trong member1
      final member1Query = await firestore
          .collection(_collection)
          .where('member1', isEqualTo: userId)
          .limit(1)
          .get();

      if (member1Query.docs.isNotEmpty) {
        return ApiResponse<String?>.success(member1Query.docs.first.id);
      }

      // Tìm trong member2
      final member2Query = await firestore
          .collection(_collection)
          .where('member2', isEqualTo: userId)
          .limit(1)
          .get();

      if (member2Query.docs.isNotEmpty) {
        return ApiResponse<String?>.success(member2Query.docs.first.id);
      }

      return ApiResponse<String?>.success(null);
    } catch (e, stackTrace) {
      final exception = ExceptionHandler.handle(e, stackTrace);
      ErrorLogger.log(exception);
      return ApiResponse<String?>.failure(exception);
    }
  }

  @override
  Future<ApiResponse<List<CoupleEntity>>> getAllCouples() async {
    try {
      final snapshot = await firestore.collection(_collection).get();
      final couples = snapshot.docs
          .map((doc) => CoupleModel.fromMap(doc.data(), doc.id))
          .toList();
      return ApiResponse.success(couples);
    } catch (e, stackTrace) {
      final exception = ExceptionHandler.handle(e, stackTrace);
      ErrorLogger.log(exception);
      return ApiResponse.failure(exception);
    }
  }

  @override
  Future<ApiResponse<CoupleEntity?>> getCoupleById(String id) async {
    try {
      if (id.isEmpty) {
        throw ThrowException(
          ErrorCode.validationFailed,
          attributes: {'field': 'id'},
        );
      }

      final doc = await firestore.collection(_collection).doc(id).get();
      if (!doc.exists || doc.data() == null) {
        throw ThrowException(ErrorCode.coupleNotFound);
      }

      return ApiResponse.success(CoupleModel.fromMap(doc.data()!, doc.id));
    } catch (e, stackTrace) {
      final exception = ExceptionHandler.handle(e, stackTrace);
      ErrorLogger.log(exception);
      return ApiResponse.failure(exception);
    }
  }

  @override
  Future<ApiResponse<CoupleEntity>> createCouple(CoupleEntity couple) async {
    try {
      // _validateCoupleEntity(couple);
      final docRef = firestore.collection(_collection).doc();

      final model = CoupleModel(
        id: docRef.id,
        createdAt: couple.createdAt,
        member1: couple.member1,
        member2: couple.member2,
      );

      await docRef.set(model.toMap());

      await userRepository.updateUserCoupleId(couple.member1, docRef.id);
      await userRepository.updateUserCoupleId(couple.member2, docRef.id);
      return ApiResponse.success(model);
    } catch (e, stackTrace) {
      final exception = ExceptionHandler.handle(e, stackTrace);
      ErrorLogger.log(exception);
      return ApiResponse.failure(exception);
    }
  }

  @override
  Future<ApiResponse<CoupleEntity>> updateCouple(CoupleEntity couple) async {
    try {
      _validateCoupleEntity(couple);

      final docRef = firestore.collection(_collection).doc(couple.id);
      final existingDoc = await docRef.get();
      if (!existingDoc.exists) {
        throw ThrowException(ErrorCode.coupleNotFound);
      }

      final model = CoupleModel(
        id: couple.id,
        coupleName: couple.coupleName,
        coupleAvatar: couple.coupleAvatar,
        loveStartDate: couple.loveStartDate,
        createdAt: couple.createdAt,
        member1: couple.member1,
        member2: couple.member2,
      );

      await docRef.update(model.toMap());
      return ApiResponse.success(model);
    } catch (e, stackTrace) {
      final exception = ExceptionHandler.handle(e, stackTrace);
      ErrorLogger.log(exception);
      return ApiResponse.failure(exception);
    }
  }

  @override
  Future<ApiResponse<void>> deleteCouple(String coupleId) async {
    try {
      final docRef = firestore.collection(_collection).doc(coupleId);
      final existingDoc = await docRef.get();
      if (!existingDoc.exists) {
        throw ThrowException(ErrorCode.coupleNotFound);
      }
      await docRef.delete();
      return ApiResponse.success(null);
    } catch (e, stackTrace) {
      final exception = ExceptionHandler.handle(e, stackTrace);
      ErrorLogger.log(exception);
      return ApiResponse.failure(exception);
    }
  }

  @override
  Future<ApiResponse<List<CoupleEntity>>> getCouplesByMember(
    String userId,
  ) async {
    try {
      if (userId.isEmpty) {
        throw ThrowException(
          ErrorCode.validationFailed,
          attributes: {'field': 'userId'},
        );
      }

      final snapshot1 = await firestore
          .collection(_collection)
          .where('member1', isEqualTo: userId)
          .get();

      final snapshot2 = await firestore
          .collection(_collection)
          .where('member2', isEqualTo: userId)
          .get();

      final allDocs = [...snapshot1.docs, ...snapshot2.docs];

      final couples = allDocs
          .map((doc) => CoupleModel.fromMap(doc.data(), doc.id))
          .toList();

      return ApiResponse.success(couples);
    } catch (e, stackTrace) {
      final exception = ExceptionHandler.handle(e, stackTrace);
      ErrorLogger.log(exception);
      return ApiResponse.failure(exception);
    }
  }

  void _validateCoupleEntity(CoupleEntity couple) {
    if (couple.id == null || couple.id!.isEmpty) {
      throw ThrowException(
        ErrorCode.validationFailed,
        attributes: {'field': 'id'},
      );
    }

    if (couple.member1.isEmpty || couple.member2.isEmpty) {
      throw ThrowException(
        ErrorCode.validationFailed,
        attributes: {'field': 'member1/member2'},
      );
    }
  }
}

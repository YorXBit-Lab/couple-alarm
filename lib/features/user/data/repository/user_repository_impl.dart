import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:couple_note/core/common/api_response.dart';
import 'package:couple_note/core/config/app_constants.dart';
import 'package:couple_note/core/errors/exception_handler.dart';
import 'package:couple_note/core/errors/app_exception.dart';
import 'package:couple_note/core/utils/error_logger.dart';
import 'package:couple_note/features/user/data/models/user_model.dart';
import 'package:couple_note/features/user/domain/entities/user.dart';
import 'package:couple_note/features/user/domain/repository/user_repository.dart';

class UserRepositoryImpl implements UserRepository {
  final FirebaseFirestore _firestore;
  static const String _collection = 'users';

  UserRepositoryImpl(this._firestore);

  @override
  Future<ApiResponse<UserEntity>> createUser(UserEntity user) async {
    try {
      final userModel = UserModel(
        uid: user.uid,
        email: user.email,
        displayName: user.displayName,
        photoURL: user.photoURL,
        createdAt: user.createdAt,
        updatedAt: DateTime.now(),
        fcmToken: user.fcmToken,
        languageCode: user.languageCode,
        isAutoApproveReminder: user.isAutoApproveReminder,
      );

      await _firestore
          .collection(_collection)
          .doc(user.uid)
          .set(userModel.toFirestore());
      return ApiResponse.success(userModel);
    } catch (e, stackTrace) {
      final ex = ExceptionHandler.handle(e, stackTrace);
      ErrorLogger.log(ex);
      return ApiResponse.failure(ex);
    }
  }

  @override
  Future<ApiResponse<UserEntity?>> getUserById(String uid) async {
    try {
      final doc = await _firestore.collection(_collection).doc(uid).get();

      if (!doc.exists) {
        return ApiResponse.success(null);
      }

      return ApiResponse.success(UserModel.fromFirestore(doc));
    } catch (e, stackTrace) {
      final ex = ExceptionHandler.handle(e, stackTrace);
      ErrorLogger.log(ex);
      return ApiResponse.failure(ex);
    }
  }

  @override
  Future<ApiResponse<UserEntity>> updateUser(UserEntity user) async {
    try {
      final userModel = UserModel(
        uid: user.uid,
        email: user.email,
        displayName: user.displayName,
        photoURL: user.photoURL,
        createdAt: user.createdAt,
        nickname: user.nickname,
        avatar: user.avatar,
        languageCode: user.languageCode,
        updatedAt: DateTime.now(),
        fcmToken: user.fcmToken,
        coupleId: user.coupleId,
        isAutoApproveReminder: user.isAutoApproveReminder,
      );

      await _firestore
          .collection(_collection)
          .doc(user.uid)
          .update(userModel.toFirestore());
      return ApiResponse.success(userModel);
    } catch (e, stackTrace) {
      final ex = ExceptionHandler.handle(e, stackTrace);
      ErrorLogger.log(ex);
      return ApiResponse.failure(ex);
    }
  }

  @override
  Future<ApiResponse<void>> deleteUser(String uid) async {
    try {
      await _firestore.collection(_collection).doc(uid).delete();
      return ApiResponse.success("User was deleted successfully");
    } catch (e, stackTrace) {
      final ex = ExceptionHandler.handle(e, stackTrace);
      ErrorLogger.log(ex);
      return ApiResponse.failure(ex);
    }
  }

  @override
  Future<ApiResponse<void>> updateUserOnlineStatus(
    String uid,
    bool isOnline,
  ) async {
    try {
      await _firestore.collection(_collection).doc(uid).update({
        'isOnline': isOnline,
        'lastSeen': Timestamp.now(),
        'updatedAt': Timestamp.now(),
      });
      return ApiResponse.success(null);
    } catch (e, stackTrace) {
      final ex = ExceptionHandler.handle(e, stackTrace);
      ErrorLogger.log(ex);
      return ApiResponse.failure(ex);
    }
  }

  @override
  Future<ApiResponse<void>> updateUserFCMToken(
    String uid,
    String fcmToken,
  ) async {
    try {
      await _firestore.collection(_collection).doc(uid).update({
        'fcmToken': fcmToken,
        'updatedAt': Timestamp.now(),
      });
      return ApiResponse.success(null);
    } catch (e, stackTrace) {
      final ex = ExceptionHandler.handle(e, stackTrace);
      ErrorLogger.log(ex);
      return ApiResponse.failure(ex);
    }
  }

  @override
  Future<String?> getUserFCMToken(String userId) async {
    final doc = await _firestore.collection(_collection).doc(userId).get();
    if (doc.exists) {
      return doc.data()?['fcmToken'];
    }
    return null;
  }

  @override
  Future<ApiResponse<void>> updateUserCoupleId(
    String uid,
    String? coupleId,
  ) async {
    try {
      await _firestore.collection(_collection).doc(uid).update({
        'coupleId': coupleId,
        'updatedAt': Timestamp.now(),
      });
      return ApiResponse.success(null);
    } catch (e, stackTrace) {
      final ex = ExceptionHandler.handle(e, stackTrace);
      ErrorLogger.log(ex);
      return ApiResponse.failure(ex);
    }
  }

  @override
  Future<ApiResponse<List<UserEntity>>> searchUsersByEmail(String email) async {
    try {
      final querySnapshot = await _firestore
          .collection(_collection)
          .where('email', isEqualTo: email)
          .get();

      final users = querySnapshot.docs.map(UserModel.fromFirestore).toList();
      return ApiResponse.success(users);
    } catch (e, stackTrace) {
      final ex = ExceptionHandler.handle(e, stackTrace);
      ErrorLogger.log(ex);
      return ApiResponse.failure(ex);
    }
  }

  @override
  Stream<ApiResponse<UserEntity?>> watchUser(String userId) {
    return _firestore
        .collection('users')
        .doc(userId)
        .snapshots()
        .asyncMap<ApiResponse<UserEntity?>>((userDoc) async {
          try {
            if (!userDoc.exists || userDoc.data() == null) {
              return ApiResponse<UserEntity?>.success(null);
            }

            final userData = userDoc.data()!;
            final user = UserEntity.fromMap({...userData, 'uid': userDoc.id});

            return ApiResponse<UserEntity?>.success(user);
          } catch (e, stackTrace) {
            final exception = ExceptionHandler.handle(e, stackTrace);
            ErrorLogger.log(exception);
            return ApiResponse<UserEntity?>.failure(exception);
          }
        })
        .handleError((error, stackTrace) {
          final exception = ExceptionHandler.handle(error, stackTrace);
          ErrorLogger.log(exception);
          return ApiResponse<UserEntity?>.failure(exception);
        });
  }

  @override
  Future<ApiResponse<bool>> updateNickname(String uid, String nickname) async {
    try {
      await _firestore.collection(_collection).doc(uid).update({
        'nickname': nickname,
        'updatedAt': Timestamp.now(),
      });
      return ApiResponse.success(true);
    } catch (e, stackTrace) {
      final ex = ExceptionHandler.handle(e, stackTrace);
      ErrorLogger.log(ex);
      return ApiResponse.failure(ex);
    }
  }

  @override
  Future<ApiResponse<bool>> updateIsAutoApproveReminder(
    String uid,
    bool isAutoApproveReminder,
  ) async {
    try {
      await _firestore.collection(_collection).doc(uid).update({
        'isAutoApproveReminder': isAutoApproveReminder,
        'updatedAt': Timestamp.now(),
      });
      return ApiResponse.success(true);
    } catch (e, stackTrace) {
      final ex = ExceptionHandler.handle(e, stackTrace);
      ErrorLogger.log(ex);
      return ApiResponse.failure(ex);
    }
  }
}

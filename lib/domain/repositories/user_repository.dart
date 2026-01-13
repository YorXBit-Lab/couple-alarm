import 'package:couple_note/core/common/api_response.dart';
import 'package:couple_note/domain/entities/user.dart';

abstract class UserRepository {
  Future<ApiResponse<UserEntity>> createUser(UserEntity user);
  Future<ApiResponse<UserEntity?>> getUserById(String uid);
  Future<ApiResponse<UserEntity>> updateUser(UserEntity user);
  Future<ApiResponse<void>> deleteUser(String uid);
  Future<ApiResponse<void>> updateUserOnlineStatus(String uid, bool isOnline);
  Future<ApiResponse<void>> updateUserFCMToken(String uid, String fcmToken);
  Future<String?> getUserFCMToken(String userId);
  Future<ApiResponse<void>> updateUserCoupleId(String uid, String? coupleId);
  Future<ApiResponse<List<UserEntity>>> searchUsersByEmail(String email);
  Stream<ApiResponse<UserEntity?>> watchUser(String uid);
  Future<ApiResponse<bool>> updateNickname(String uid, String nickname);
  Future<ApiResponse<bool>> updateIsAutoApproveReminder(
    String uid,
    bool isAutoApproveReminder,
  );
}

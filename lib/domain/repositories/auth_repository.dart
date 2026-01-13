import 'package:couple_note/core/common/api_response.dart';
import 'package:couple_note/domain/entities/user.dart';

abstract class AuthRepository {
  Future<ApiResponse<UserEntity>> signInWithGoogle();
  Future<ApiResponse<void>> signOut();
  Future<ApiResponse<void>> deleteAccount();
  Future<ApiResponse<UserEntity?>> getCurrentUser();
  Stream<UserEntity?> get authStateChanges;
  bool get isSignedIn;
  Future<ApiResponse<void>> updateProfile({
    String? displayName,
    String? photoURL,
  });
}

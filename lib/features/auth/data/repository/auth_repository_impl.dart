import 'package:couple_note/core/config/app_constants.dart';
import 'package:couple_note/core/errors/app_exception.dart';
import 'package:couple_note/core/errors/exception_handler.dart';
import 'package:couple_note/core/utils/error_logger.dart';
import 'package:couple_note/core/services/auth_service.dart';
import 'package:couple_note/core/common/api_response.dart';
import 'package:couple_note/features/user/data/models/user_model.dart';
import 'package:couple_note/features/user/domain/entities/user.dart';
import 'package:couple_note/features/auth/domain/repository/auth_repository.dart';
import 'package:couple_note/features/user/domain/repository/user_repository.dart';

class AuthRepositoryImpl implements AuthRepository {
  final AuthService _authService;
  final UserRepository _userRepository;

  AuthRepositoryImpl(this._authService, this._userRepository);

  @override
  Future<ApiResponse<UserEntity>> signInWithGoogle() async {
    try {
      final userCredential = await _authService.signInWithGoogle();

      if (userCredential?.user == null) {
        throw ThrowException(ErrorCode.signInFailed);
      }

      final firebaseUser = userCredential!.user!;

      final existingUser = await _userRepository.getUserById(firebaseUser.uid);

      if (existingUser.isSuccess && existingUser.data != null)
        return ApiResponse.success(existingUser.data!);

      final newUser = UserModel.fromFirebaseUser(firebaseUser);
      final createdUser = await _userRepository.createUser(newUser);

      if (createdUser.data != null) {
        return ApiResponse.success(createdUser.data!);
      } else {
        throw ThrowException(ErrorCode.signInFailed);
      }
    } catch (e, stackTrace) {
      final exception = ExceptionHandler.handle(e, stackTrace);
      ErrorLogger.log(exception);
      return ApiResponse.failure(exception);
    }
  }

  @override
  Future<ApiResponse<void>> updateProfile({
    String? displayName,
    String? photoURL,
  }) async {
    try {
      final currentUser = _authService.currentUser;
      if (currentUser == null) {
        throw ThrowException(ErrorCode.userNotSignedIn);
      }

      await _authService.updateProfile(
        displayName: displayName,
        photoURL: photoURL,
      );

      final firestoreUser = await _userRepository.getUserById(currentUser.uid);
      if (firestoreUser.isSuccess && firestoreUser.data != null) {
        final updatedUser = firestoreUser.data!.copyWith(
          displayName: displayName ?? firestoreUser.data!.displayName,
          photoURL: photoURL ?? firestoreUser.data!.photoURL,
        );
        await _userRepository.updateUser(updatedUser);
      }

      return ApiResponse.success(null);
    } catch (e, stackTrace) {
      final exception = ExceptionHandler.handle(e, stackTrace);
      ErrorLogger.log(exception);
      return ApiResponse.failure(exception);
    }
  }

  @override
  Future<ApiResponse<void>> signOut() async {
    try {
      await _authService.signOut();
      return ApiResponse.success(null);
    } catch (e, stackTrace) {
      final exception = ExceptionHandler.handle(e, stackTrace);
      ErrorLogger.log(exception);
      return ApiResponse.failure(exception);
    }
  }

  @override
  Future<ApiResponse<void>> deleteAccount() async {
    try {
      final currentUser = _authService.currentUser;
      if (currentUser != null) {
        await _userRepository.deleteUser(currentUser.uid);
      }

      await _authService.deleteAccount();
      return ApiResponse.success(null);
    } catch (e, stackTrace) {
      final exception = ExceptionHandler.handle(e, stackTrace);
      ErrorLogger.log(exception);
      return ApiResponse.failure(exception);
    }
  }

  @override
  Future<ApiResponse<UserEntity?>> getCurrentUser() async {
    try {
      final firebaseUser = _authService.currentUser;
      if (firebaseUser == null) {
        throw ThrowException(ErrorCode.userNotSignedIn);
      }

      final user = await _userRepository.getUserById(firebaseUser.uid);
      if (!user.isSuccess || user.data == null) {
        return ApiResponse.success(null);
      }
      return ApiResponse.success(user.data);
    } catch (e, stackTrace) {
      final exception = ExceptionHandler.handle(e, stackTrace);
      ErrorLogger.log(exception);
      return ApiResponse.failure(exception);
    }
  }

  @override
  Stream<UserEntity?> get authStateChanges {
    return _authService.authStateChanges.asyncMap((firebaseUser) async {
      if (firebaseUser == null) return null;

      try {
        final firestoreUser = await _userRepository.getUserById(
          firebaseUser.uid,
        );
        if (!firestoreUser.isSuccess || firestoreUser.data == null) {
          return null;
        }
        return firestoreUser.data;
      } catch (e, stackTrace) {
        final exception = ExceptionHandler.handle(e, stackTrace);
        ErrorLogger.log(exception);
        return null;
      }
    });
  }

  @override
  bool get isSignedIn => _authService.isSignedIn;
}

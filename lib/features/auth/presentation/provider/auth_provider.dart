import 'package:couple_note/core/common/api_response.dart';
import 'package:couple_note/core/config/dev_flags.dart';
import 'package:couple_note/core/providers/global_providers.dart';
import 'package:couple_note/core/services/auth_service.dart';
import 'package:couple_note/features/auth/data/repository/auth_repository_impl.dart';
import 'package:couple_note/features/auth/domain/repository/auth_repository.dart';
import 'package:couple_note/features/auth/domain/usecases/delete_account_usecase.dart';
import 'package:couple_note/features/auth/domain/usecases/get_current_user_usecase.dart';
import 'package:couple_note/features/auth/domain/usecases/sign_in_with_gg_usecase.dart';
import 'package:couple_note/features/auth/domain/usecases/sign_out_usecase.dart';
import 'package:couple_note/features/auth/domain/usecases/update_profile_usecase.dart';
import 'package:couple_note/features/auth/domain/usecases/watch_auth_state_usecase.dart';
import 'package:couple_note/features/auth/presentation/provider/auth_notifier.dart';
import 'package:couple_note/features/couple/domain/entities/couples.dart';
import 'package:couple_note/features/couple/presentation/provider/couple_provider.dart';
import 'package:couple_note/features/user/domain/entities/user.dart';
import 'package:couple_note/features/user/presentation/provider/user_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'auth_provider.g.dart';

UserEntity get _devUser {
  final now = DateTime.now();
  return UserEntity(
    uid: 'dev-user',
    email: 'dev@couple-alarm.local',
    displayName: 'Dev User',
    createdAt: now,
    updatedAt: now,
    isAutoApproveReminder: false,
    languageCode: 'vi',
  );
}

@riverpod
AuthService authService(Ref ref) => AuthService();

@riverpod
AuthRepository authRepository(Ref ref) {
  return AuthRepositoryImpl(
    ref.read(authServiceProvider),
    ref.read(userRepositoryProvider),
  );
}

@riverpod
SignInWithGoogleUseCase signInWithGoogleUseCase(Ref ref) {
  return SignInWithGoogleUseCase(ref.read(authRepositoryProvider));
}

@riverpod
SignOutUseCase signOutUseCase(Ref ref) {
  return SignOutUseCase(ref.read(authRepositoryProvider));
}

@riverpod
DeleteAccountUseCase deleteAccountUseCase(Ref ref) {
  return DeleteAccountUseCase(ref.read(authRepositoryProvider));
}

@riverpod
GetCurrentUserUseCase getCurrentUserUseCase(Ref ref) {
  return GetCurrentUserUseCase(ref.read(authRepositoryProvider));
}

@riverpod
UpdateProfileUseCase updateProfileUseCase(Ref ref) {
  return UpdateProfileUseCase(ref.read(authRepositoryProvider));
}

@riverpod
WatchAuthStateUseCase watchAuthStateUseCase(Ref ref) {
  return WatchAuthStateUseCase(ref.read(authRepositoryProvider));
}

@riverpod
UserEntity? currentUser(Ref ref) {
  return devBypassLogin ? _devUser : ref.watch(authProvider).currentUser;
}

@riverpod
AuthState authState(Ref ref) {
  return ref.watch(authProvider).state;
}

@riverpod
bool isAuthenticated(Ref ref) {
  return devBypassLogin || ref.watch(authProvider).isAuthenticated;
}

@riverpod
bool isLoading(Ref ref) {
  return ref.watch(authProvider).isLoading;
}

@riverpod
String? authError(Ref ref) {
  return ref.watch(authProvider).errorMessage;
}

@riverpod
Stream<UserEntity?> authStateStream(Ref ref) {
  return ref.read(watchAuthStateUseCaseProvider).call();
}

@riverpod
String? coupleId(Ref ref) {
  return ref.watch(authProvider).coupleId;
}

@riverpod
bool hasCouple(Ref ref) {
  return ref.watch(authProvider).hasCouple;
}

@riverpod
bool hasPartner(Ref ref) {
  return ref.watch(authProvider).hasPartner;
}

@riverpod
Stream<ApiResponse<UserEntity?>?> partner(Ref ref) {
  final userId = ref.watch(currentUserProvider)?.uid;
  if (userId == null || userId.isEmpty) return Stream.value(null);
  return ref.read(coupleRepositoryProvider).getPartner(userId);
}

@riverpod
Stream<ApiResponse<CoupleEntity?>?> coupleStream(Ref ref) {
  final userId = ref.watch(currentUserProvider)?.uid;
  if (userId == null || userId.isEmpty) return Stream.value(null);
  return ref.read(coupleRepositoryProvider).getCoupleByUserId(userId);
}

@riverpod
Stream<ApiResponse<UserEntity?>> currentUserStream(Ref ref) {
  if (devBypassLogin) return Stream.value(ApiResponse.success(_devUser));

  final userId = ref.watch(currentUserProvider)?.uid;
  if (userId == null || userId.isEmpty)
    return Stream.value(ApiResponse.success(null));
  return ref.read(userRepositoryProvider).watchUser(userId);
}

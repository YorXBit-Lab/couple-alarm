import 'package:couple_note/core/common/api_response.dart';
import 'package:couple_note/core/services/auth_service.dart';
import 'package:couple_note/core/services/lib/core/local_storage_service.dart';
import 'package:couple_note/core/services/lib/core/services/fcm_manager.dart';
import 'package:couple_note/data/repositories/auth_repository_impl.dart';
import 'package:couple_note/data/repositories/couple_repository_impl.dart';
import 'package:couple_note/data/repositories/user_repository_impl.dart';
import 'package:couple_note/di/dependency_injection.dart';
import 'package:couple_note/domain/entities/user.dart';
import 'package:couple_note/domain/entities/couples.dart';
import 'package:couple_note/domain/repositories/auth_repository.dart';
import 'package:couple_note/domain/repositories/couple_repository.dart';
import 'package:couple_note/domain/repositories/user_repository.dart';
import 'package:couple_note/domain/usecases/auth/delete_account_usecase.dart';
import 'package:couple_note/domain/usecases/auth/get_current_user_usecase.dart';
import 'package:couple_note/domain/usecases/auth/sign_in_with_gg_usecase.dart';
import 'package:couple_note/domain/usecases/auth/sign_out_usecase.dart';
import 'package:couple_note/domain/usecases/auth/update_profile_usecase.dart';
import 'package:couple_note/domain/usecases/auth/watch_auth_state_usecase.dart';
import 'package:couple_note/presentation/viewmodels/auth_viewmodel.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:couple_note/providers/couple_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';

final authServiceProvider = Provider<AuthService>((ref) {
  return AuthService();
});

// Repositories
final userRepositoryProvider = Provider<UserRepository>((ref) {
  return UserRepositoryImpl(FirebaseFirestore.instance);
});

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepositoryImpl(
    ref.read(authServiceProvider),
    ref.read(userRepositoryProvider),
  );
});

// Use Cases
final signInWithGoogleUseCaseProvider = Provider<SignInWithGoogleUseCase>((
  ref,
) {
  return SignInWithGoogleUseCase(ref.read(authRepositoryProvider));
});

final signOutUseCaseProvider = Provider<SignOutUseCase>((ref) {
  return SignOutUseCase(ref.read(authRepositoryProvider));
});

final deleteAccountUseCaseProvider = Provider<DeleteAccountUseCase>((ref) {
  return DeleteAccountUseCase(ref.read(authRepositoryProvider));
});

final getCurrentUserUseCaseProvider = Provider<GetCurrentUserUseCase>((ref) {
  return GetCurrentUserUseCase(ref.read(authRepositoryProvider));
});

final updateProfileUseCaseProvider = Provider<UpdateProfileUseCase>((ref) {
  return UpdateProfileUseCase(ref.read(authRepositoryProvider));
});

final watchAuthStateUseCaseProvider = Provider<WatchAuthStateUseCase>((ref) {
  return WatchAuthStateUseCase(ref.read(authRepositoryProvider));
});

// View Model
final authViewModelProvider =
    StateNotifierProvider<AuthViewModel, AuthViewState>((ref) {
      return AuthViewModel(
        signInWithGoogleUseCase: ref.read(signInWithGoogleUseCaseProvider),
        signOutUseCase: ref.read(signOutUseCaseProvider),
        deleteAccountUseCase: ref.read(deleteAccountUseCaseProvider),
        getPartnerUseCase: ref.read(getPartnerUseCaseProvider),
        getCurrentUserUseCase: ref.read(getCurrentUserUseCaseProvider),
        updateProfileUseCase: ref.read(updateProfileUseCaseProvider),
        watchAuthStateUseCase: ref.read(watchAuthStateUseCaseProvider),
        reminderRepository: ref.read(reminderRepositoryProvider),
        userRepository: ref.read(userRepositoryProvider),
        coupleRepository: ref.read(coupleRepositoryProvider),
        fcmTokenManager: FCMTokenManager(ref.read(userRepositoryProvider)),
        localStorageService: ref.watch(localStorageServiceProvider),
        getCoupleIdByUserIdUseCase: ref.read(
          getCoupleIdByUserIdUseCaseProvider,
        ),
      );
    });

final authStateProvider = Provider<AuthState>((ref) {
  return ref.watch(authViewModelProvider).state;
});

final currentUserProvider = Provider<UserEntity?>((ref) {
  return ref.watch(authViewModelProvider).currentUser;
});

final isAuthenticatedProvider = Provider<bool>((ref) {
  return ref.watch(authViewModelProvider).isAuthenticated;
});

final isLoadingProvider = Provider<bool>((ref) {
  return ref.watch(authViewModelProvider).isLoading;
});

final authErrorProvider = Provider<String?>((ref) {
  return ref.watch(authViewModelProvider).errorMessage;
});

final authStateStreamProvider = StreamProvider<UserEntity?>((ref) {
  return ref.read(watchAuthStateUseCaseProvider).call();
});

final coupleIdProvider = Provider<String?>((ref) {
  return ref.watch(authViewModelProvider).coupleId;
});

final hasCoupleProvider = Provider<bool>((ref) {
  return ref.watch(authViewModelProvider).hasCouple;
});

final hasPartnerProvider = Provider<bool>((ref) {
  return ref.watch(authViewModelProvider).hasPartner;
});

final partnerProvider = StreamProvider<ApiResponse<UserEntity?>?>((ref) {
  final userId = ref.watch(currentUserProvider)?.uid;
  if (userId == null || userId.isEmpty) {
    return Stream.value(null);
  }
  final repository = ref.read(coupleRepositoryProvider);
  return repository.getPartner(userId);
});

final coupleProvider = StreamProvider<ApiResponse<CoupleEntity?>?>((ref) {
  final userId = ref.watch(currentUserProvider)?.uid;
  if (userId == null || userId.isEmpty) {
    return Stream.value(null);
  }
  final repository = ref.read(coupleRepositoryProvider);
  return repository.getCoupleByUserId(userId);
});

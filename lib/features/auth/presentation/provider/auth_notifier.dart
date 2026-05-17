import 'package:couple_note/core/config/app_constants.dart';
import 'package:couple_note/core/constants/trans_keys.dart';
import 'package:couple_note/core/providers/global_providers.dart';
import 'package:couple_note/core/services/alarm/alarm_service.dart';
import 'package:couple_note/core/services/connectivity_service.dart';
import 'package:couple_note/core/services/local_storage_service.dart';
import 'package:couple_note/core/services/fcm_manager.dart';
import 'package:couple_note/core/utils/datetime_utils.dart';
import 'package:couple_note/features/reminder/data/repository/reminder_repository_impl.dart';
import 'package:couple_note/features/reminder/domain/entities/reminder.dart';
import 'package:couple_note/features/reminder/domain/repository/reminder_repository.dart';
import 'package:couple_note/features/user/domain/entities/user.dart';
import 'package:couple_note/features/couple/domain/entities/couples.dart';
import 'package:couple_note/features/user/domain/repository/user_repository.dart';
import 'package:couple_note/features/auth/domain/usecases/delete_account_usecase.dart';
import 'package:couple_note/features/auth/domain/usecases/get_current_user_usecase.dart';
import 'package:couple_note/features/auth/domain/usecases/sign_in_with_gg_usecase.dart';
import 'package:couple_note/features/auth/domain/usecases/sign_out_usecase.dart';
import 'package:couple_note/features/auth/domain/usecases/update_profile_usecase.dart';
import 'package:couple_note/features/auth/domain/usecases/watch_auth_state_usecase.dart';
import 'package:couple_note/features/couple/domain/usecases/get_coupleId_by_user_id.dart';
import 'package:couple_note/features/couple/domain/usecases/get_partner.dart';
import 'package:couple_note/features/auth/presentation/provider/auth_provider.dart';
import 'package:couple_note/features/user/presentation/provider/user_provider.dart';
import 'package:couple_note/features/couple/presentation/provider/couple_provider.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'auth_notifier.g.dart';

enum AuthState { initial, loading, authenticated, unauthenticated, error }

class AuthViewState {
  final AuthState state;
  final UserEntity? currentUser;
  final String? errorMessage;
  final bool isLoading;
  final String? coupleId;
  final UserEntity? partner;
  final CoupleEntity? couple;

  const AuthViewState({
    required this.state,
    this.currentUser,
    this.errorMessage,
    this.isLoading = false,
    this.coupleId,
    this.partner,
    this.couple,
  });

  AuthViewState copyWith({
    AuthState? state,
    UserEntity? currentUser,
    String? errorMessage,
    bool? isLoading,
    UserEntity? partner,
    CoupleEntity? couple,
  }) {
    return AuthViewState(
      state: state ?? this.state,
      currentUser: currentUser ?? this.currentUser,
      errorMessage: errorMessage ?? this.errorMessage,
      isLoading: isLoading ?? this.isLoading,
      coupleId: coupleId ?? this.coupleId,
      partner: partner ?? this.partner,
      couple: couple ?? this.couple,
    );
  }

  bool get isAuthenticated =>
      state == AuthState.authenticated && currentUser != null;
  bool get isUnauthenticated => state == AuthState.unauthenticated;
  bool get hasError => state == AuthState.error;
  bool get isInitial => state == AuthState.initial;
  bool get hasCouple => coupleId != null && coupleId!.isNotEmpty;
  bool get hasPartner => partner != null;
}

@Riverpod(keepAlive: true)
class AuthNotifier extends _$AuthNotifier {
  late SignInWithGoogleUseCase _signInWithGoogleUseCase;
  late SignOutUseCase _signOutUseCase;
  late DeleteAccountUseCase _deleteAccountUseCase;
  late GetCurrentUserUseCase _getCurrentUserUseCase;
  late UpdateProfileUseCase _updateProfileUseCase;
  late WatchAuthStateUseCase _watchAuthStateUseCase;
  late ReminderRepository _reminderRepository;
  late UserRepository _userRepository;
  late GetPartnerUseCase _getPartnerUseCase;
  late GetCoupleIdByUserIdUseCase _getCoupleIdByUserIdUseCase;
  late LocalStorageService _localStorageService;
  late FCMTokenManager _fcmTokenManager;

  @override
  AuthViewState build() {
    _signInWithGoogleUseCase = ref.read(signInWithGoogleUseCaseProvider);
    _signOutUseCase = ref.read(signOutUseCaseProvider);
    _deleteAccountUseCase = ref.read(deleteAccountUseCaseProvider);
    _getCurrentUserUseCase = ref.read(getCurrentUserUseCaseProvider);
    _updateProfileUseCase = ref.read(updateProfileUseCaseProvider);
    _watchAuthStateUseCase = ref.read(watchAuthStateUseCaseProvider);
    _userRepository = ref.read(userRepositoryProvider);
    _getPartnerUseCase = ref.read(getPartnerUseCaseProvider);
    _getCoupleIdByUserIdUseCase = ref.read(getCoupleIdByUserIdUseCaseProvider);
    _localStorageService = ref.read(localStorageServiceProvider);
    _fcmTokenManager = FCMTokenManager(ref.read(userRepositoryProvider));
    _reminderRepository = ReminderRepositoryImpl(
      ref.read(firestoreProvider),
      ConnectivityService(),
    );

    final subscription = _watchAuthStateUseCase.call().listen(
      (user) async {
        if (user != null) {
          state = state.copyWith(
            currentUser: user,
            state: AuthState.authenticated,
          );
        } else {
          state = state.copyWith(
            currentUser: null,
            state: AuthState.unauthenticated,
            partner: null,
            couple: null,
          );
        }
      },
      onError: (error) {
        _handleError(error);
      },
    );

    ref.onDispose(() => subscription.cancel());

    return const AuthViewState(state: AuthState.initial);
  }

  Future<void> signInWithGoogle() async {
    _clearError();
    _setLoading(true);

    try {
      final res = await _signInWithGoogleUseCase.call();

      if (res.data != null) {
        final user = res.data as UserEntity;
        await _localStorageService.saveUser(user, StorageKeys.user);

        final coupleIdResponse = await _getCoupleIdByUserIdUseCase.call(
          user.uid,
        );

        if (coupleIdResponse.isSuccess) {
          _localStorageService.saveCoupleId(coupleId: coupleIdResponse.data);
        }

        state = state.copyWith(
          currentUser: user,
          state: AuthState.authenticated,
        );

        await _fcmTokenManager.updateFCMTokenOnAuth(user.uid);
        _recreateAllAlarms(user.uid, coupleIdResponse.data);
      } else {
        state = state.copyWith(
          state: AuthState.unauthenticated,
          errorMessage: TransKeys.an_error_occurred.tr(),
        );
      }
    } catch (e) {
      _handleError(e);
    } finally {
      _setLoading(false);
    }
  }

  Future<void> _recreateAllAlarms(String userId, String? coupleId) async {
    try {
      final results = await Future.wait([
        _reminderRepository.getRemindersByUser(userId),
        if (coupleId != null) _reminderRepository.getRemindersByUser(coupleId),
      ]);

      final allReminders = results
          .expand((res) => res.data?.toList() ?? <ReminderEntity>[])
          .toList();

      for (var r in allReminders) {
        try {
          final bool isValidStatus =
              r.reminderStatus == ReminderStatus.doing &&
              (r.approvalStatus != ApprovalStatus.pending);

          if (!isValidStatus) {
            continue;
          }

          DateTime? nextReminderDate;

          if (r.days != null && r.days!.isNotEmpty) {
            nextReminderDate = DateTimeUtils.getNextReminderDate(
              r.reminderDate,
              r.days!,
            );
          } else if (r.reminderDate.isAfter(DateTime.now())) {
            nextReminderDate = r.reminderDate;
          }

          if (nextReminderDate != null &&
              nextReminderDate.isAfter(DateTime.now())) {
            await AlarmService.scheduleWithRollback(
              reminderDate: nextReminderDate,
              alarmId: r.alarmId,
            );
          } else {
            _reminderRepository.updateReminder(
              r.copyWith(
                reminderStatus: ReminderStatus.overdue,
                updatedAt: DateTime.now(),
              ),
            );
          }
        } catch (e) {}
      }
    } catch (e) {}
  }

  Future<void> signOut() async {
    _clearError();
    _setLoading(true);

    try {
      await _fcmTokenManager.clearFCMTokenOnSignOut(state.currentUser!.uid);
      await _signOutUseCase.call();
      state = state.copyWith(
        currentUser: null,
        state: AuthState.unauthenticated,
        partner: null,
        couple: null,
      );
      await _localStorageService.clearUser();
      await _localStorageService.clearCoupleInfo();
    } catch (e) {
      _handleError(e);
    } finally {
      _setLoading(false);
    }
  }

  Future<void> deleteAccount() async {
    _setLoading(true);
    _clearError();

    try {
      await _deleteAccountUseCase.call();
      state = state.copyWith(
        currentUser: null,
        state: AuthState.unauthenticated,
        partner: null,
        couple: null,
      );
      await _localStorageService.clearUser();
      await _localStorageService.clearCoupleInfo();
    } catch (e) {
      _handleError(e);
    } finally {
      _setLoading(false);
    }
  }

  Future<void> updateProfile({String? displayName, String? photoURL}) async {
    _setLoading(true);
    _clearError();

    try {
      await _updateProfileUseCase.call(
        displayName: displayName,
        photoURL: photoURL,
      );

      final res = await _getCurrentUserUseCase.call();
      state = state.copyWith(currentUser: res.data);

      if (res.data != null) {
        await _localStorageService.saveUser(
          res.data as UserEntity,
          StorageKeys.user,
        );
      }
    } catch (e) {
      _handleError(e);
    } finally {
      _setLoading(false);
    }
  }

  Future<void> updateFCMToken(String fcmToken) async {
    if (state.currentUser == null) return;

    try {
      await _userRepository.updateUserFCMToken(
        state.currentUser!.uid,
        fcmToken,
      );

      final updatedUser = state.currentUser!.copyWith(fcmToken: fcmToken);
      state = state.copyWith(currentUser: updatedUser);
      await _localStorageService.saveUser(updatedUser, StorageKeys.user);
    } catch (e) {
      _handleError(e);
    }
  }

  Future<void> refreshUser() async {
    if (state.state != AuthState.authenticated) return;

    try {
      final res = await _getCurrentUserUseCase.call();
      if (res.data != null) {
        state = state.copyWith(currentUser: res.data);
        await _localStorageService.saveUser(
          res.data as UserEntity,
          StorageKeys.user,
        );
      }
    } catch (e) {
      _handleError(e);
    }
  }

  Future<void> refreshCoupleInfo() async {
    if (state.currentUser == null) return;
  }

  Future<void> loadUserFromLocalStorage() async {
    try {
      final user = _localStorageService.getObject(StorageKeys.user);
      if (user != null) {
        state = state.copyWith(
          currentUser: user,
          state: AuthState.authenticated,
        );
      }
    } catch (e) {
      debugPrint('Error loading user from local storage: $e');
    }
  }

  void _setLoading(bool loading) {
    state = state.copyWith(
      isLoading: loading,
      state: loading ? AuthState.loading : state.state,
    );
  }

  void _clearError() {
    state = state.copyWith(
      errorMessage: null,
      state: state.hasError
          ? (state.currentUser != null
                ? AuthState.authenticated
                : AuthState.unauthenticated)
          : state.state,
    );
  }

  void _handleError(dynamic error) {
    state = state.copyWith(
      errorMessage: error.toString(),
      state: AuthState.error,
      isLoading: false,
    );
    debugPrint('AuthNotifier Error: $error');
  }

  Future<bool> validateSession() async {
    try {
      final res = await _getCurrentUserUseCase.call();
      if (res.data == null) {
        state = state.copyWith(
          currentUser: null,
          state: AuthState.unauthenticated,
          partner: null,
          couple: null,
        );
        await _localStorageService.clearUser();
        await _localStorageService.clearCoupleInfo();
        return false;
      }
      return true;
    } catch (e) {
      _handleError(e);
      return false;
    }
  }
}

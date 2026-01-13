import 'package:couple_note/core/config/app_constants.dart';
import 'package:couple_note/core/constants/trans_keys.dart';
import 'package:couple_note/core/services/alarm/alarm_service.dart';
import 'package:couple_note/core/services/lib/core/local_storage_service.dart';
import 'package:couple_note/core/services/lib/core/services/fcm_manager.dart';
import 'package:couple_note/core/utils/datetime_utils.dart';
import 'package:couple_note/domain/entities/reminder.dart';
import 'package:couple_note/domain/entities/user.dart';
import 'package:couple_note/domain/entities/couples.dart';
import 'package:couple_note/domain/repositories/reminder_repository.dart';
import 'package:couple_note/domain/repositories/user_repository.dart';
import 'package:couple_note/domain/repositories/couple_repository.dart';
import 'package:couple_note/domain/usecases/auth/delete_account_usecase.dart';
import 'package:couple_note/domain/usecases/auth/get_current_user_usecase.dart';
import 'package:couple_note/domain/usecases/auth/sign_in_with_gg_usecase.dart';
import 'package:couple_note/domain/usecases/auth/sign_out_usecase.dart';
import 'package:couple_note/domain/usecases/auth/update_profile_usecase.dart';
import 'package:couple_note/domain/usecases/auth/watch_auth_state_usecase.dart';
import 'package:couple_note/domain/usecases/couple/get_coupleId_by_user_id.dart';
import 'package:couple_note/domain/usecases/couple/get_couple_by_user_id.dart';
import 'package:couple_note/domain/usecases/couple/get_partner.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';

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

  // Helper getters
  bool get isAuthenticated =>
      state == AuthState.authenticated && currentUser != null;
  bool get isUnauthenticated => state == AuthState.unauthenticated;
  bool get hasError => state == AuthState.error;
  bool get isInitial => state == AuthState.initial;
  bool get hasCouple => coupleId != null && coupleId!.isNotEmpty;
  bool get hasPartner => partner != null;
}

// Notifier class
class AuthViewModel extends StateNotifier<AuthViewState> {
  final SignInWithGoogleUseCase _signInWithGoogleUseCase;
  final SignOutUseCase _signOutUseCase;
  final DeleteAccountUseCase _deleteAccountUseCase;
  final GetCurrentUserUseCase _getCurrentUserUseCase;
  final UpdateProfileUseCase _updateProfileUseCase;
  final WatchAuthStateUseCase _watchAuthStateUseCase;
  final ReminderRepository _reminderRepository;
  final UserRepository _userRepository;
  final GetPartnerUseCase _getPartnerUseCase;
  final GetCoupleIdByUserIdUseCase _getCoupleIdByUserIdUseCase;
  final LocalStorageService _localStorageService;
  final FCMTokenManager _fcmTokenManager;

  AuthViewModel({
    required SignInWithGoogleUseCase signInWithGoogleUseCase,
    required SignOutUseCase signOutUseCase,
    required DeleteAccountUseCase deleteAccountUseCase,
    required GetCurrentUserUseCase getCurrentUserUseCase,
    required UpdateProfileUseCase updateProfileUseCase,
    required WatchAuthStateUseCase watchAuthStateUseCase,
    required ReminderRepository reminderRepository,
    required UserRepository userRepository,
    required CoupleRepository coupleRepository,
    required GetPartnerUseCase getPartnerUseCase,
    required GetCoupleIdByUserIdUseCase getCoupleIdByUserIdUseCase,
    required LocalStorageService localStorageService,
    required FCMTokenManager fcmTokenManager,
  }) : _fcmTokenManager = fcmTokenManager,
       _signInWithGoogleUseCase = signInWithGoogleUseCase,
       _signOutUseCase = signOutUseCase,
       _deleteAccountUseCase = deleteAccountUseCase,
       _getCurrentUserUseCase = getCurrentUserUseCase,
       _updateProfileUseCase = updateProfileUseCase,
       _watchAuthStateUseCase = watchAuthStateUseCase,
       _getCoupleIdByUserIdUseCase = getCoupleIdByUserIdUseCase,
       _getPartnerUseCase = getPartnerUseCase,
       _reminderRepository = reminderRepository,
       _userRepository = userRepository,
       _localStorageService = localStorageService,
       super(const AuthViewState(state: AuthState.initial)) {
    _initialize();
  }

  void _initialize() {
    _watchAuthStateUseCase.call().listen(
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

      // Refresh current user
      final res = await _getCurrentUserUseCase.call();
      state = state.copyWith(currentUser: res.data);

      // Update local storage
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

      // Update local user
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

  // Helper methods
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

    debugPrint('AuthViewModel Error: $error');
  }

  // Method to validate user session
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

import 'package:couple_note/core/constants/trans_keys.dart';
import 'package:couple_note/domain/usecases/couple/delete_couple.dart';
import 'package:couple_note/domain/usecases/couple/get_couple_by_user_id.dart';
import 'package:couple_note/domain/usecases/invitation/get_pending_invitation.dart';
import 'package:couple_note/domain/usecases/invitation/update_invitation_status_usecase.dart';
import 'package:couple_note/domain/usecases/reminder/delete_pending_reminder.dart';
import 'package:couple_note/domain/usecases/reminder/move_couple_reminder_to_personal.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';

class ConnectionState {
  final bool isLoading;
  final String? error;

  const ConnectionState({this.isLoading = false, this.error});

  ConnectionState copyWith({bool? isLoading, String? error}) {
    return ConnectionState(
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
    );
  }
}

class ConnectViewModel extends StateNotifier<ConnectionState> {
  final GetCoupleByUserIdUseCase getCoupleByUserIdUseCase;
  final GetPendingInvitationsUseCase getPendingInvitationsUseCase;
  final UpdateInvitationStatusUseCase updateInvitationStatusUseCase;
  final DeleteCoupleUseCase deleteCoupleUseCase;

  final MoveCoupleReminderToPersonal moveCoupleReminderToPersonal;
  final DeletePendingReminder deletePendingReminder;
  final Ref ref;
  ConnectViewModel({
    required this.getCoupleByUserIdUseCase,
    required this.getPendingInvitationsUseCase,
    required this.updateInvitationStatusUseCase,
    required this.deleteCoupleUseCase,
    required this.moveCoupleReminderToPersonal,
    required this.deletePendingReminder,
    required this.ref,
  }) : super(const ConnectionState()) {}

  void clearError() {
    state = state.copyWith(error: null);
  }

  Future<bool> disconnect(
    String currentUserId,
    String loverId,
    String coupleId,
  ) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final results = await Future.wait([
        deletePendingReminder(currentUserId, loverId),
        moveCoupleReminderToPersonal(currentUserId, loverId, coupleId),
      ]);

      final allSuccess = results.every((result) => result.isSuccess);

      if (!allSuccess) {
        state = state.copyWith(
          isLoading: false,
          error: TransKeys.an_error_occurred.tr(),
        );
        return false;
      }

      final deleteCoupleResult = await deleteCoupleUseCase(coupleId);

      if (deleteCoupleResult.isSuccess) {
        state = const ConnectionState(isLoading: false);
      } else {
        state = state.copyWith(
          isLoading: false,
          error: TransKeys.an_error_occurred.tr(),
        );
      }

      return true;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: TransKeys.an_error_occurred.tr(),
      );
      return false;
    }
  }
}

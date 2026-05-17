import 'package:couple_note/core/config/app_constants.dart';
import 'package:couple_note/core/constants/trans_keys.dart';
import 'package:couple_note/features/invitation/domain/entities/invitation.dart';
import 'package:couple_note/features/invitation/domain/repository/invitation_repository.dart';
import 'package:couple_note/features/couple/domain/usecases/delete_couple.dart';
import 'package:couple_note/features/couple/domain/usecases/get_couple_by_user_id.dart';
import 'package:couple_note/features/invitation/domain/usecases/get_pending_invitation.dart';
import 'package:couple_note/features/invitation/domain/usecases/update_invitation_status_usecase.dart';
import 'package:couple_note/features/reminder/domain/usecases/delete_pending_reminder.dart';
import 'package:couple_note/features/reminder/domain/usecases/move_couple_reminder_to_personal.dart';
import 'package:couple_note/features/couple/presentation/provider/couple_provider.dart';
import 'package:couple_note/features/connect/presentation/provider/scanner_provider.dart';
import 'package:couple_note/features/reminder/presentation/provider/reminder_provider.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'connect_notifier.g.dart';

class ConnectState {
  final bool isLoading;
  final String? error;

  const ConnectState({this.isLoading = false, this.error});

  ConnectState copyWith({bool? isLoading, String? error}) {
    return ConnectState(
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
    );
  }
}

@Riverpod(keepAlive: true)
class ConnectNotifier extends _$ConnectNotifier {
  late GetCoupleByUserIdUseCase _getCoupleByUserIdUseCase;
  late GetPendingInvitationsUseCase _getPendingInvitationsUseCase;
  late UpdateInvitationStatusUseCase _updateInvitationStatusUseCase;
  late DeleteCoupleUseCase _deleteCoupleUseCase;
  late MoveCoupleReminderToPersonal _moveCoupleReminderToPersonal;
  late DeletePendingReminder _deletePendingReminder;

  @override
  ConnectState build() {
    _getCoupleByUserIdUseCase = ref.read(getCoupleByUserIdUseCaseProvider);
    _getPendingInvitationsUseCase = ref.read(
      getPendingInvitationsUseCaseProvider,
    );
    _updateInvitationStatusUseCase = ref.read(updateInvitationStatusProvider);
    _deleteCoupleUseCase = ref.read(deleteCoupleUseCaseProvider);

    _moveCoupleReminderToPersonal = ref.read(
      moveCoupleReminderToPersonalUseCaseProvider,
    );
    _deletePendingReminder = ref.read(deletePendingReminderUseCaseProvider);
    return const ConnectState();
  }

  void clearError() {
    state = state.copyWith(error: null);
  }

  Stream<List<InvitationWithUser>> getPendingInvitationsUseCase(String userId) {
    return _getPendingInvitationsUseCase(userId);
  }

  Future<void> updateInvitationStatusUseCase(
    InvitationEntity invitation,
    ApprovalStatus status,
  ) async {
    await _updateInvitationStatusUseCase(invitation, status);
  }

  Future<bool> disconnect(
    String currentUserId,
    String loverId,
    String coupleId,
  ) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final results = await Future.wait([
        _deletePendingReminder(currentUserId, loverId),
        _moveCoupleReminderToPersonal(currentUserId, loverId, coupleId),
      ]);

      final allSuccess = results.every((result) => result.isSuccess);

      if (!allSuccess) {
        state = state.copyWith(
          isLoading: false,
          error: TransKeys.an_error_occurred.tr(),
        );
        return false;
      }

      final deleteCoupleResult = await _deleteCoupleUseCase(coupleId);

      if (deleteCoupleResult.isSuccess) {
        state = const ConnectState(isLoading: false);
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

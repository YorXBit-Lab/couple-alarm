import 'package:couple_note/core/config/app_constants.dart';
import 'package:couple_note/features/invitation/domain/entities/invitation.dart';
import 'package:couple_note/features/invitation/domain/repository/invitation_repository.dart';

class UpdateInvitationStatusUseCase {
  final InvitationRepository _invitationRepository;

  UpdateInvitationStatusUseCase(this._invitationRepository);

  Future<void> call(InvitationEntity invitation, ApprovalStatus status) async {
    await _invitationRepository.updateInvitationStatus(invitation, status);
  }
}

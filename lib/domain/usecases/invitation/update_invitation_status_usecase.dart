import 'package:couple_note/core/config/app_constants.dart';
import 'package:couple_note/domain/entities/invitation.dart';
import 'package:couple_note/domain/repositories/invitation_repository.dart';

class UpdateInvitationStatusUseCase {
  final InvitationRepository _invitationRepository;

  UpdateInvitationStatusUseCase(this._invitationRepository);

  Future<void> call(InvitationEntity invitation, ApprovalStatus status) async {
    await _invitationRepository.updateInvitationStatus(invitation, status);
  }
}

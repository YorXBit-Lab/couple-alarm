import 'package:couple_note/features/invitation/domain/entities/invitation.dart';
import 'package:couple_note/features/invitation/domain/repository/invitation_repository.dart';

class CreateInvitationUseCase {
  final InvitationRepository _invitationRepository;

  CreateInvitationUseCase(this._invitationRepository);

  Future<String> call(InvitationEntity invitation) async {
    try {
      final invitationId = await _invitationRepository.createInvitation(
        invitation,
      );
      return invitationId;
    } catch (e) {
      throw Exception('Failed to create invitation: $e');
    }
  }
}

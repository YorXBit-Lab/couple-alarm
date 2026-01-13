import 'package:couple_note/domain/entities/invitation.dart';
import 'package:couple_note/domain/repositories/invitation_repository.dart';

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

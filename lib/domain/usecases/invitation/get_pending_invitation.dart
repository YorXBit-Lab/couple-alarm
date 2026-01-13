import 'package:couple_note/domain/repositories/invitation_repository.dart';

class GetPendingInvitationsUseCase {
  final InvitationRepository _invitationRepository;

  GetPendingInvitationsUseCase(this._invitationRepository);

  Stream<List<InvitationWithUser>> call(String userId) {
    return _invitationRepository.getPendingInvitationsWithUsers(userId);
  }
}

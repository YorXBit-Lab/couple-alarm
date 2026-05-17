import 'package:couple_note/features/invitation/domain/repository/invitation_repository.dart';

class GetPendingInvitationsUseCase {
  final InvitationRepository _invitationRepository;

  GetPendingInvitationsUseCase(this._invitationRepository);

  Stream<List<InvitationWithUser>> call(String userId) {
    return _invitationRepository.getPendingInvitationsWithUsers(userId);
  }
}

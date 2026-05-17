import 'package:couple_note/core/config/app_constants.dart';
import 'package:couple_note/features/invitation/domain/entities/invitation.dart';
import 'package:couple_note/features/user/domain/entities/user.dart';

class InvitationWithUser {
  final InvitationEntity invitation;
  final UserEntity? fromUser;
  final UserEntity? toUser;

  const InvitationWithUser({
    required this.invitation,
    this.fromUser,
    this.toUser,
  });
}

abstract class InvitationRepository {
  Future<String> createInvitation(InvitationEntity invitation);
  Future<void> updateInvitationStatus(
    InvitationEntity invitation,
    ApprovalStatus status,
  );
  Future<InvitationEntity?> getInvitationById(String id);
  Future<InvitationEntity?> getInvitationByCode(String code);
  Stream<List<InvitationWithUser>> getPendingInvitationsWithUsers(
    String userId,
  );
  Future<void> sendInvitationNotification(InvitationEntity invitation);
  Future<void> sendInvitationResponseNotification({
    required String invitationId,
    required String status,
  });
}

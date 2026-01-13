import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:couple_note/core/config/app_constants.dart';
import 'package:couple_note/core/services/fcm_service.dart';
import 'package:couple_note/domain/entities/couples.dart';
import 'package:couple_note/domain/entities/invitation.dart';
import 'package:couple_note/domain/entities/user.dart';
import 'package:couple_note/domain/repositories/couple_repository.dart';
import 'package:couple_note/domain/repositories/invitation_repository.dart';
import 'package:couple_note/data/models/invitation_model.dart';
import 'package:couple_note/domain/repositories/user_repository.dart';

class InvitationRepositoryImpl implements InvitationRepository {
  final FirebaseFirestore _firestore;
  final String _collection = 'invitations';
  final UserRepository _userRepository;
  final CoupleRepository _coupleRepository;
  InvitationRepositoryImpl(
    this._firestore,
    this._userRepository,
    this._coupleRepository,
  );

  @override
  Future<String> createInvitation(InvitationEntity invitation) async {
    final existingQuery = await _firestore
        .collection(_collection)
        .where('fromUserId', isEqualTo: invitation.fromUserId)
        .where('toUserId', isEqualTo: invitation.toUserId)
        .where('status', isEqualTo: 'pending')
        .limit(1)
        .get();

    if (existingQuery.docs.isNotEmpty) {
      throw Exception('Bạn đã gửi lời mời cho người này rồi!');
    }

    final isExistingToUser = await _userRepository.getUserById(
      invitation.toUserId,
    );
    if (isExistingToUser.isFailure) {
      throw Exception('Người dùng không tồn tại');
    }

    final invitationModel = InvitationModel(
      id: invitation.id ?? '',
      createdAt: invitation.createdAt,
      expiredAt: invitation.expiredAt ?? DateTime.now().add(Duration(days: 7)),
      fromUserId: invitation.fromUserId,
      respondedAt: invitation.respondedAt,
      status: invitation.status,
      toUserId: invitation.toUserId,
    );

    final doc = await _firestore
        .collection(_collection)
        .add(invitationModel.toMap());

    await sendInvitationNotification(invitation);

    return doc.id;
  }

  Future<void> clearButKeepFirst() async {
    final collection = _firestore.collection(_collection);

    final snapshots = await collection.get();

    if (snapshots.docs.isEmpty) return;

    final firstDoc = snapshots.docs.first;

    for (var doc in snapshots.docs) {
      if (doc.id != firstDoc.id) {
        await doc.reference.delete();
      }
    }
  }

  @override
  Future<void> sendInvitationNotification(InvitationEntity invitation) async {
    try {
      final fromUser = await _userRepository.getUserById(invitation.fromUserId);
      final toUser = await _userRepository.getUserById(invitation.toUserId);

      if (toUser.data?.fcmToken == null ||
          toUser.data?.fcmToken?.isEmpty == true) {
        print(
          'User ${toUser.data?.displayName ?? 'unknown'} chưa có FCM token',
        );
        return;
      }

      final title = 'Lời mời mới';
      final body =
          '${fromUser.data?.displayName ?? 'Unknown'} đã gửi lời mời cho bạn';

      await FCMService.sendNotificationToToken(
        fcmToken: toUser.data?.fcmToken ?? '',
        title: title,
        body: body,
        navigationPath: '/scanner',
        data: {'type': NotificationType.todo},
      );
    } catch (e) {
      print('Lỗi khi gửi thông báo lời mời: $e');
    }
  }

  Future<void> sendInvitationResponseNotification({
    required String invitationId,
    required String status,
  }) async {
    try {
      final invitationDoc = await _firestore
          .collection(_collection)
          .doc(invitationId)
          .get();

      if (!invitationDoc.exists) return;

      final invitationData = invitationDoc.data()!;
      final fromUserId = invitationData['fromUserId'];
      final toUserId = invitationData['toUserId'];

      final fromUser = await _userRepository.getUserById(fromUserId);
      final toUser = await _userRepository.getUserById(toUserId);

      if (fromUser.data?.fcmToken == null) return;

      final title = status == 'accepted'
          ? 'Lời mời được chấp nhận'
          : 'Lời mời bị từ chối';
      final body =
          '${toUser.data?.displayName} đã ${status == 'accepted' ? 'chấp nhận' : 'từ chối'} lời mời của bạn';

      await FCMService.sendNotificationToToken(
        fcmToken: fromUser.data!.fcmToken!,
        title: title,
        body: body,
        data: {
          'type': NotificationType.invite,
          'invitationId': invitationId,
          'status': status,
        },
      );
    } catch (e) {
      print('Lỗi khi gửi thông báo phản hồi: $e');
    }
  }

  @override
  Future<void> updateInvitationStatus(
    InvitationEntity invitation,
    ApprovalStatus status,
  ) async {
    await _firestore.collection(_collection).doc(invitation.id).update({
      'status': status.value,
      'respondedAt': FieldValue.serverTimestamp(),
    });

    if (status == ApprovalStatus.accepted) {
      await _coupleRepository.createCouple(
        CoupleEntity(
          member1: invitation.toUserId,
          member2: invitation.fromUserId,
          createdAt: DateTime.now(),
        ),
      );
    }
  }

  @override
  Future<InvitationEntity?> getInvitationById(String id) async {
    final doc = await _firestore.collection(_collection).doc(id).get();
    if (!doc.exists || doc.data() == null) return null;
    return InvitationModel.fromMap(doc.data()!, doc.id);
  }

  @override
  Future<InvitationEntity?> getInvitationByCode(String code) async {
    final query = await _firestore
        .collection(_collection)
        .where('inviteCode', isEqualTo: code)
        .where('status', isEqualTo: 'pending')
        .limit(1)
        .get();

    if (query.docs.isEmpty) return null;
    final doc = query.docs.first;
    return InvitationModel.fromMap(doc.data(), doc.id);
  }

  @override
  Stream<List<InvitationWithUser>> getPendingInvitationsWithUsers(
    String userId,
  ) {
    return _firestore
        .collection(_collection)
        .where(
          Filter.or(
            Filter('toUserId', isEqualTo: userId),
            Filter('fromUserId', isEqualTo: userId),
          ),
        )
        .where('status', isEqualTo: 'pending')
        .snapshots()
        .asyncMap((snapshot) async {
          List<InvitationModel> invitations = snapshot.docs
              .map((doc) => InvitationModel.fromMap(doc.data(), doc.id))
              .toList();

          if (invitations.isEmpty) return [];

          // Get unique fromUserIds and toUserIds
          Set<String> userIds = {};
          for (var inv in invitations) {
            userIds.add(inv.fromUserId);
            userIds.add(inv.toUserId);
          }

          // Fetch all users
          Map<String, UserEntity> usersMap = {};
          try {
            for (String userId in userIds) {
              final user = await _userRepository.getUserById(userId);
              if (user.data != null) {
                usersMap[userId] = user.data!;
              }
            }
          } catch (e) {
            print('Error fetching users: $e');
          }

          return invitations.map((invitation) {
            return InvitationWithUser(
              invitation: invitation,
              fromUser: usersMap[invitation.fromUserId],
              toUser: usersMap[invitation.toUserId],
            );
          }).toList();
        });
  }
}

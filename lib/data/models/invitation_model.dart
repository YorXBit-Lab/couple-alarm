import 'package:couple_note/core/config/app_constants.dart';
import 'package:couple_note/core/utils/datetime_utils.dart';
import 'package:couple_note/domain/entities/invitation.dart';

class InvitationModel extends InvitationEntity {
  InvitationModel({
    required String id,
    required DateTime createdAt,
    DateTime? expiredAt,
    required String fromUserId,
    DateTime? respondedAt,
    InvitationStatus status = InvitationStatus.pending,
    required String toUserId,
  }) : super(
         id: id,
         createdAt: createdAt,
         expiredAt: expiredAt,
         fromUserId: fromUserId,
         respondedAt: respondedAt,
         status: status,
         toUserId: toUserId,
       );

  factory InvitationModel.fromMap(Map<String, dynamic> map, String id) {
    return InvitationModel(
      id: id,
      createdAt: DateTimeUtils.toDateTime((map['createdAt'])) ?? DateTime.now(),
      expiredAt: DateTimeUtils.toDateTime((map['expiredAt'])),
      fromUserId: map['fromUserId'] ?? '',
      respondedAt: DateTimeUtils.toDateTime((map['respondedAt'])),
      status: InvitationStatus.fromString(map['status']),
      toUserId: map['toUserId'] ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'createdAt': createdAt,
      'expiredAt': expiredAt,
      'fromUserId': fromUserId,
      'respondedAt': respondedAt,
      'status': status.name,
      'toUserId': toUserId,
    };
  }
}

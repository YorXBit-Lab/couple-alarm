import 'package:couple_note/core/config/app_constants.dart';

class InvitationEntity {
  final String? id;
  final DateTime createdAt;
  final DateTime? expiredAt;
  final String fromUserId;
  final DateTime? respondedAt;
  final InvitationStatus status;

  final String toUserId;

  InvitationEntity({
    this.id,
    required this.createdAt,
    this.expiredAt,
    required this.fromUserId,
    this.respondedAt,
    this.status = InvitationStatus.pending,
    required this.toUserId,
  });

  InvitationEntity copyWith({
    String? id,
    DateTime? createdAt,
    DateTime? expiredAt,
    String? fromUserId,
    DateTime? respondedAt,
    InvitationStatus? status,
    String? toUserId,
  }) {
    return InvitationEntity(
      id: id ?? this.id,
      createdAt: createdAt ?? this.createdAt,
      expiredAt: expiredAt ?? this.expiredAt,
      fromUserId: fromUserId ?? this.fromUserId,
      respondedAt: respondedAt ?? this.respondedAt,
      status: status ?? this.status,
      toUserId: toUserId ?? this.toUserId,
    );
  }
}

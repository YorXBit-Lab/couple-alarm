class CoupleEntity {
  final String? id;
  final String? coupleName;
  final String? coupleAvatar;
  final DateTime? loveStartDate;
  final DateTime createdAt;
  final String member1;
  final String member2;

  CoupleEntity({
    this.id,
    this.coupleName,
    this.coupleAvatar,
    this.loveStartDate,
    required this.createdAt,
    required this.member1,
    required this.member2,
  });

  CoupleEntity copyWith({
    String? id,
    String? coupleName,
    String? coupleAvatar,
    DateTime? loveStartDate,
    String? createdBy,
    DateTime? createdAt,
    String? member1,
    String? member2,
  }) {
    return CoupleEntity(
      id: id ?? this.id,
      coupleName: coupleName ?? this.coupleName,
      coupleAvatar: coupleAvatar ?? this.coupleAvatar,
      loveStartDate: loveStartDate ?? this.loveStartDate,
      createdAt: createdAt ?? this.createdAt,
      member1: member1 ?? this.member1,
      member2: member2 ?? this.member2,
    );
  }
}

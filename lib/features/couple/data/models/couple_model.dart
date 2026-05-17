import 'package:couple_note/core/utils/datetime_utils.dart';
import 'package:couple_note/features/couple/domain/entities/couples.dart';

class CoupleModel extends CoupleEntity {
  CoupleModel({
    String? id,
    String? coupleName,
    String? coupleAvatar,
    DateTime? loveStartDate,
    required DateTime createdAt,
    required String member1,
    required String member2,
  }) : super(
         id: id,
         coupleName: coupleName,
         coupleAvatar: coupleAvatar,
         loveStartDate: loveStartDate,
         createdAt: createdAt,
         member1: member1,
         member2: member2,
       );

  factory CoupleModel.fromMap(Map<String, dynamic> map, String id) {
    return CoupleModel(
      id: id,
      coupleName: map['coupleName'],
      coupleAvatar: map['coupleAvatar'],
      loveStartDate: DateTimeUtils.toDateTime((map['loveStartDate'])),
      createdAt: DateTimeUtils.toDateTime((map['createdAt'])) ?? DateTime.now(),
      member1: map['member1'] ?? '',
      member2: map['member2'] ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'coupleName': coupleName,
      'coupleAvatar': coupleAvatar,
      'loveStartDate': loveStartDate,
      'createdAt': createdAt,
      'member1': member1,
      'member2': member2,
    };
  }
}

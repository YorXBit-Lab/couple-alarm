import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';

class UserEntity extends Equatable {
  final String uid;
  final String? nickname;
  final String? avatar;
  final String email;
  final String displayName;
  final String? photoURL;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? fcmToken;
  final String? coupleId;
  final bool? isAutoApproveReminder;
  final String? languageCode;

  const UserEntity({
    required this.uid,
    required this.email,
    this.nickname,
    this.avatar,
    required this.displayName,
    this.photoURL,
    required this.createdAt,
    required this.updatedAt,
    this.fcmToken,
    this.coupleId,
    this.languageCode,
    this.isAutoApproveReminder,
  });

  UserEntity copyWith({
    String? uid,
    String? email,
    String? displayName,
    String? nickname,
    String? avatar,
    String? photoURL,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? fcmToken,
    String? languageCode,
    String? coupleId,
    bool? isAutoApproveReminder,
  }) {
    return UserEntity(
      uid: uid ?? this.uid,
      email: email ?? this.email,
      nickname: nickname ?? this.nickname,
      avatar: avatar ?? this.avatar,
      displayName: displayName ?? this.displayName,
      photoURL: photoURL ?? this.photoURL,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      fcmToken: fcmToken ?? this.fcmToken,
      coupleId: coupleId ?? this.coupleId,
      languageCode: languageCode ?? this.languageCode,
      isAutoApproveReminder:
          isAutoApproveReminder ?? this.isAutoApproveReminder,
    );
  }

  // ✅ Convert from Firestore Map or local storage
  factory UserEntity.fromMap(Map<String, dynamic> map) {
    return UserEntity(
      uid: map['uid'],
      email: map['email'],
      nickname: map['nickname'],
      avatar: map['avatar'],
      displayName: map['displayName'],
      photoURL: map['photoURL'],
      createdAt: map['createdAt'] is Timestamp
          ? (map['createdAt'] as Timestamp).toDate()
          : DateTime.parse(map['createdAt']),
      updatedAt: map['updatedAt'] is Timestamp
          ? (map['updatedAt'] as Timestamp).toDate()
          : DateTime.parse(map['updatedAt']),
      fcmToken: map['fcmToken'],
      coupleId: map['coupleId'],
      languageCode: map['languageCode'],
      isAutoApproveReminder: map['isAutoApproveReminder'] as bool?,
    );
  }

  // ✅ Convert to Map for local storage
  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'email': email,
      'nickname': nickname,
      'avatar': avatar,
      'displayName': displayName,
      'photoURL': photoURL,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'fcmToken': fcmToken,
      'coupleId': coupleId,
      'languageCode': languageCode,
      'isAutoApproveReminder': isAutoApproveReminder,
    };
  }

  @override
  List<Object?> get props => [
    uid,
    email,
    nickname,
    avatar,
    displayName,
    photoURL,
    createdAt,
    updatedAt,
    fcmToken,
    languageCode,
    coupleId,
    isAutoApproveReminder,
  ];
}

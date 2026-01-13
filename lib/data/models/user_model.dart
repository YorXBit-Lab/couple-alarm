import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:couple_note/domain/entities/user.dart';

class UserModel extends UserEntity {
  const UserModel({
    required super.uid,
    super.nickname,
    super.avatar,
    required super.email,
    required super.displayName,
    super.photoURL,
    required super.createdAt,
    required super.updatedAt,
    super.fcmToken,

    super.languageCode = 'en',
    super.coupleId,
    super.isAutoApproveReminder,
  });

  factory UserModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return UserModel(
      uid: doc.id,
      email: data['email'] ?? '',
      nickname: data['nickname'] ?? '',
      avatar: data['avatar'] ?? '',
      displayName: data['displayName'] ?? '',
      photoURL: data['photoURL'],
      languageCode: data['languageCode'],
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      updatedAt: (data['updatedAt'] as Timestamp).toDate(),
      fcmToken: data['fcmToken'],
      coupleId: data['coupleId'],
      isAutoApproveReminder: data['isAutoApproveReminder'] as bool? ?? false,
    );
  }

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      uid: json['uid'] ?? '',
      email: json['email'] ?? '',
      nickname: json['nickname'],
      avatar: json['avatar'],
      displayName: json['displayName'] ?? '',
      photoURL: json['photoURL'],
      languageCode: json['languageCode'],
      createdAt: json['createdAt'] is Timestamp
          ? (json['createdAt'] as Timestamp).toDate()
          : DateTime.parse(json['createdAt']),
      updatedAt: json['updatedAt'] is Timestamp
          ? (json['updatedAt'] as Timestamp).toDate()
          : DateTime.parse(json['updatedAt']),
      fcmToken: json['fcmToken'],
      coupleId: json['coupleId'],
      isAutoApproveReminder: json['isAutoApproveReminder'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'uid': uid,
      'email': email,
      'nickname': nickname,
      'avatar': avatar,
      'languageCode': languageCode,
      'displayName': displayName,
      'photoURL': photoURL,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'fcmToken': fcmToken,
      'coupleId': coupleId,
      'isAutoApproveReminder': isAutoApproveReminder,
    };
  }

  Map<String, dynamic> toFirestore() {
    return {
      'email': email,
      'nickname': nickname,
      'avatar': avatar,
      'displayName': displayName,
      'languageCode': languageCode,
      'photoURL': photoURL,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
      'fcmToken': fcmToken,
      'coupleId': coupleId,
      'isAutoApproveReminder': isAutoApproveReminder,
    };
  }

  factory UserModel.fromFirebaseUser(
    firebase_auth.User firebaseUser, {
    String? coupleId,
    String? fcmToken,
    String? nickname,
    bool? isAutoApproveReminder,
    String languageCode = 'en',
    bool isOnline = true,
  }) {
    final now = DateTime.now();
    return UserModel(
      uid: firebaseUser.uid,
      email: firebaseUser.email ?? '',
      nickname: nickname,
      avatar: '',
      displayName: firebaseUser.displayName ?? '',
      photoURL: firebaseUser.photoURL,
      languageCode: languageCode,
      createdAt: now,
      updatedAt: now,
      fcmToken: fcmToken,
      coupleId: coupleId,
      isAutoApproveReminder: isAutoApproveReminder ?? false,
    );
  }

  UserModel copyWith({
    String? uid,
    String? email,
    String? nickname,
    String? avatar,
    String? displayName,
    String? photoURL,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? coupleId,
    String? languageCode,
    String? fcmToken,
    bool? isAutoApproveReminder,
    bool? isOnline,
    DateTime? lastSeen,
  }) {
    return UserModel(
      uid: uid ?? this.uid,
      email: email ?? this.email,
      nickname: nickname ?? this.nickname,
      avatar: avatar ?? this.avatar,
      displayName: displayName ?? this.displayName,
      photoURL: photoURL ?? this.photoURL,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      languageCode: languageCode ?? this.languageCode,
      fcmToken: fcmToken ?? this.fcmToken,
      coupleId: coupleId ?? this.coupleId,
      isAutoApproveReminder:
          isAutoApproveReminder ?? this.isAutoApproveReminder,
    );
  }
}

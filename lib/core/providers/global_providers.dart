import 'package:couple_note/core/constants/trans_keys.dart';
import 'package:couple_note/core/services/cloudfare_r2_service.dart';
import 'package:couple_note/core/services/local_storage_service.dart';
import 'package:couple_note/core/services/upload_avatar_service.dart';
import 'package:couple_note/core/utils/utils.dart';
import 'package:couple_note/core/common/user_tab_model.dart';
import 'package:couple_note/features/invitation/data/repository/invitation_repository_impl.dart';
import 'package:couple_note/features/invitation/domain/repository/invitation_repository.dart';
import 'package:couple_note/features/user/domain/entities/user.dart';
import 'package:couple_note/features/couple/presentation/provider/couple_provider.dart';
import 'package:couple_note/features/user/presentation/provider/user_provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:shared_preferences/shared_preferences.dart';

part 'global_providers.g.dart';

@riverpod
FirebaseFirestore firestore(Ref ref) => FirebaseFirestore.instance;

@riverpod
FirebaseStorage firebaseStorage(Ref ref) => FirebaseStorage.instance;

// Must be overridden in ProviderScope with actual SharedPreferences instance
final sharedPreferencesProvider = Provider<SharedPreferences>((ref) {
  throw UnimplementedError('SharedPreferences phải được override trong main()');
});

@riverpod
LocalStorageService localStorageService(Ref ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  return LocalStorageService(prefs);
}

@riverpod
InvitationRepository invitationRepository(Ref ref) {
  return InvitationRepositoryImpl(
    ref.watch(firestoreProvider),
    ref.read(userRepositoryProvider),
    ref.read(coupleRepositoryProvider),
  );
}

@riverpod
List<UserTab> tabs(Ref ref, (UserEntity?, String) params) {
  final (partner, _) = params;
  return [
    UserTab(key: 'all', label: 'All', icon: Icons.apps_rounded),
    UserTab(key: 'mine', label: TransKeys.mine.tr(), icon: Icons.person),
    UserTab(key: 'partner', label: getName(partner), icon: Icons.favorite),
    UserTab(key: 'couple', label: 'Us', icon: Icons.people_alt_rounded),
  ];
}

@riverpod
R2StorageService r2StorageService(Ref ref) => R2StorageService();

@riverpod
AvatarUploadService avatarUploadService(Ref ref) {
  return AvatarUploadService(ref.read(r2StorageServiceProvider));
}

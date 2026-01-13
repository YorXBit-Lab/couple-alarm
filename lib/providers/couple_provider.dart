import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:couple_note/data/repositories/couple_repository_impl.dart';
import 'package:couple_note/domain/repositories/couple_repository.dart';
import 'package:couple_note/providers/auth_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final coupleRepositoryProvider = Provider<CoupleRepository>((ref) {
  return CoupleRepositoryImpl(
    FirebaseFirestore.instance,
    ref.read(userRepositoryProvider),
  );
});

final connectionStatusProvider = Provider<bool>((ref) {
  final couple = ref.watch(coupleProvider);

  return couple.value?.data != null;
});

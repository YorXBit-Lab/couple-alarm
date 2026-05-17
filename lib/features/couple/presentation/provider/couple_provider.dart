import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:couple_note/features/couple/data/repository/couple_repository_impl.dart';
import 'package:couple_note/features/couple/domain/repository/couple_repository.dart';
import 'package:couple_note/features/couple/domain/usecases/create_couple.dart';
import 'package:couple_note/features/couple/domain/usecases/delete_couple.dart';
import 'package:couple_note/features/couple/domain/usecases/get_all_couples.dart';
import 'package:couple_note/features/couple/domain/usecases/get_coupleId_by_user_id.dart';
import 'package:couple_note/features/couple/domain/usecases/get_couple_by_id.dart';
import 'package:couple_note/features/couple/domain/usecases/get_couple_by_user_id.dart';
import 'package:couple_note/features/couple/domain/usecases/get_couples_by_member.dart';
import 'package:couple_note/features/couple/domain/usecases/get_partner.dart';
import 'package:couple_note/features/couple/domain/usecases/update_couple.dart';
import 'package:couple_note/features/user/presentation/provider/user_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'couple_provider.g.dart';

@riverpod
CoupleRepository coupleRepository(Ref ref) {
  return CoupleRepositoryImpl(
    FirebaseFirestore.instance,
    ref.read(userRepositoryProvider),
  );
}

@riverpod
CreateCoupleUseCase createCoupleUseCase(Ref ref) {
  return CreateCoupleUseCase(ref.read(coupleRepositoryProvider));
}

@riverpod
GetPartnerUseCase getPartnerUseCase(Ref ref) {
  return GetPartnerUseCase(ref.read(coupleRepositoryProvider));
}

@riverpod
DeleteCoupleUseCase deleteCoupleUseCase(Ref ref) {
  return DeleteCoupleUseCase(ref.read(coupleRepositoryProvider));
}

@riverpod
GetAllCouplesUseCase getAllCouplesUseCase(Ref ref) {
  return GetAllCouplesUseCase(ref.read(coupleRepositoryProvider));
}

@riverpod
GetCoupleByIdUseCase getCoupleByIdUseCase(Ref ref) {
  return GetCoupleByIdUseCase(ref.read(coupleRepositoryProvider));
}

@riverpod
GetCoupleByUserIdUseCase getCoupleByUserIdUseCase(Ref ref) {
  return GetCoupleByUserIdUseCase(ref.read(coupleRepositoryProvider));
}

@riverpod
GetCoupleIdByUserIdUseCase getCoupleIdByUserIdUseCase(Ref ref) {
  return GetCoupleIdByUserIdUseCase(ref.read(coupleRepositoryProvider));
}

@riverpod
GetCouplesByMemberUseCase getCouplesByMemberUseCase(Ref ref) {
  return GetCouplesByMemberUseCase(ref.read(coupleRepositoryProvider));
}

@riverpod
UpdateCoupleUseCase updateCoupleUseCase(Ref ref) {
  return UpdateCoupleUseCase(ref.read(coupleRepositoryProvider));
}

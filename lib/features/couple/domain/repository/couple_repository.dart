import 'package:couple_note/core/common/api_response.dart';
import 'package:couple_note/features/couple/domain/entities/couples.dart';
import 'package:couple_note/features/user/domain/entities/user.dart';

abstract class CoupleRepository {
  Future<ApiResponse<List<CoupleEntity>>> getAllCouples();
  Future<ApiResponse<CoupleEntity?>> getCoupleById(String id);
  Future<ApiResponse<CoupleEntity>> createCouple(CoupleEntity couple);
  Future<ApiResponse<CoupleEntity>> updateCouple(CoupleEntity couple);
  Future<ApiResponse<void>> deleteCouple(String coupleId);
  Stream<ApiResponse<CoupleEntity?>> getCoupleByUserId(String userId);
  Future<ApiResponse<String?>> getCoupleIdByUserId(String userId);
  Future<ApiResponse<List<CoupleEntity>>> getCouplesByMember(String userId);
  Stream<ApiResponse<UserEntity?>?> getPartner(String currentUserId);
}

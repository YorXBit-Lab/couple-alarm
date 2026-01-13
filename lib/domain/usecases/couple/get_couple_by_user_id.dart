import 'package:couple_note/core/common/api_response.dart';
import 'package:couple_note/domain/entities/couples.dart';
import 'package:couple_note/domain/repositories/couple_repository.dart';

class GetCoupleByUserIdUseCase {
  final CoupleRepository repository;

  GetCoupleByUserIdUseCase(this.repository);

  Stream<ApiResponse<CoupleEntity?>> call(String userId) {
    return repository.getCoupleByUserId(userId);
  }
}

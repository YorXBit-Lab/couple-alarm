import 'package:couple_note/core/common/api_response.dart';
import 'package:couple_note/features/couple/domain/repository/couple_repository.dart';

class GetCoupleIdByUserIdUseCase {
  final CoupleRepository repository;

  GetCoupleIdByUserIdUseCase(this.repository);

  Future<ApiResponse<String?>> call(String userId) {
    return repository.getCoupleIdByUserId(userId);
  }
}

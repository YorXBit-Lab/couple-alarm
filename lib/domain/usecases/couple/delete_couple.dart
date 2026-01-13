import 'package:couple_note/core/common/api_response.dart';
import 'package:couple_note/domain/repositories/couple_repository.dart';

class DeleteCoupleUseCase {
  final CoupleRepository repository;

  DeleteCoupleUseCase(this.repository);

  Future<ApiResponse<void>> call(String coupleId) {
    return repository.deleteCouple(coupleId);
  }
}

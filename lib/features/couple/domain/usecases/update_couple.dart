import 'package:couple_note/core/common/api_response.dart';
import 'package:couple_note/features/couple/domain/entities/couples.dart';
import 'package:couple_note/features/couple/domain/repository/couple_repository.dart';

class UpdateCoupleUseCase {
  final CoupleRepository repository;

  UpdateCoupleUseCase(this.repository);

  Future<ApiResponse<CoupleEntity>> call(CoupleEntity couple) {
    return repository.updateCouple(couple);
  }
}

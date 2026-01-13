import 'package:couple_note/core/common/api_response.dart';
import 'package:couple_note/domain/entities/couples.dart';
import 'package:couple_note/domain/repositories/couple_repository.dart';

class CreateCoupleUseCase {
  final CoupleRepository repository;

  CreateCoupleUseCase(this.repository);

  Future<ApiResponse<CoupleEntity>> call(CoupleEntity couple) {
    return repository.createCouple(couple);
  }
}

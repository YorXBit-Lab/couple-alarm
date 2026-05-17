import 'package:couple_note/core/common/api_response.dart';
import 'package:couple_note/features/couple/domain/entities/couples.dart';
import 'package:couple_note/features/couple/domain/repository/couple_repository.dart';

class GetCoupleByIdUseCase {
  final CoupleRepository repository;

  GetCoupleByIdUseCase(this.repository);

  Future<ApiResponse<CoupleEntity?>> call(String id) {
    return repository.getCoupleById(id);
  }
}

import 'package:couple_note/core/common/api_response.dart';
import 'package:couple_note/features/couple/domain/entities/couples.dart';
import 'package:couple_note/features/couple/domain/repository/couple_repository.dart';

class GetAllCouplesUseCase {
  final CoupleRepository repository;

  GetAllCouplesUseCase(this.repository);

  Future<ApiResponse<List<CoupleEntity>>> call() {
    return repository.getAllCouples();
  }
}

import 'package:couple_note/core/common/api_response.dart';
import 'package:couple_note/domain/entities/couples.dart';
import 'package:couple_note/domain/repositories/couple_repository.dart';

class GetCouplesByMemberUseCase {
  final CoupleRepository repository;

  GetCouplesByMemberUseCase(this.repository);

  Future<ApiResponse<List<CoupleEntity>>> call(String userId) {
    return repository.getCouplesByMember(userId);
  }
}

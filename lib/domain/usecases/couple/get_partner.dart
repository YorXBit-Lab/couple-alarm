import 'package:couple_note/core/common/api_response.dart';
import 'package:couple_note/domain/entities/user.dart';
import 'package:couple_note/domain/repositories/couple_repository.dart';

class GetPartnerUseCase {
  final CoupleRepository repository;

  GetPartnerUseCase(this.repository);

  Stream<ApiResponse<UserEntity?>?> call(String currentUserId) {
    return repository.getPartner(currentUserId);
  }
}

import 'package:couple_note/core/common/api_response.dart';
import 'package:couple_note/features/user/domain/entities/user.dart';
import 'package:couple_note/features/auth/domain/repository/auth_repository.dart';

class GetCurrentUserUseCase {
  final AuthRepository _authRepository;

  GetCurrentUserUseCase(this._authRepository);

  Future<ApiResponse<UserEntity?>> call() async {
    return await _authRepository.getCurrentUser();
  }
}

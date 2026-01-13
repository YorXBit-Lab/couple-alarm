import 'package:couple_note/core/common/api_response.dart';
import 'package:couple_note/domain/repositories/auth_repository.dart';

class SignOutUseCase {
  final AuthRepository _authRepository;

  SignOutUseCase(this._authRepository);

  Future<ApiResponse<void>> call() async {
    return await _authRepository.signOut();
  }
}

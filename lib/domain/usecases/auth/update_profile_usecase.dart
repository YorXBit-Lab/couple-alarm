import 'package:couple_note/core/common/api_response.dart';
import 'package:couple_note/domain/repositories/auth_repository.dart';

class UpdateProfileUseCase {
  final AuthRepository _authRepository;

  UpdateProfileUseCase(this._authRepository);

  Future<ApiResponse<void>> call({
    String? displayName,
    String? photoURL,
  }) async {
    return await _authRepository.updateProfile(
      displayName: displayName,
      photoURL: photoURL,
    );
  }
}

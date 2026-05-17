import 'package:couple_note/core/common/api_response.dart';
import 'package:couple_note/features/user/domain/repository/user_repository.dart';

class UpdateNicknameUseCase {
  final UserRepository _userRepository;

  UpdateNicknameUseCase(this._userRepository);

  Future<ApiResponse<bool>> call(String uid, String nickname) {
    return _userRepository.updateNickname(uid, nickname);
  }
}

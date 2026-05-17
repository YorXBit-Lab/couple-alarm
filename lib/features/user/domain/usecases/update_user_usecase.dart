import 'package:couple_note/core/common/api_response.dart';
import 'package:couple_note/features/user/domain/entities/user.dart';
import 'package:couple_note/features/user/domain/repository/user_repository.dart';

class UpdateUserUseCase {
  final UserRepository _userRepository;

  UpdateUserUseCase(this._userRepository);

  Future<ApiResponse<UserEntity>> call(UserEntity user) {
    return _userRepository.updateUser(user);
  }
}

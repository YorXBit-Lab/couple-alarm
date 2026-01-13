import 'package:couple_note/core/common/api_response.dart';
import 'package:couple_note/domain/repositories/user_repository.dart';

class UpdateIsAutoApproveReminderUseCase {
  final UserRepository _userRepository;

  UpdateIsAutoApproveReminderUseCase(this._userRepository);

  Future<ApiResponse<bool>> call(String uid, bool isAutoApproveReminder) {
    return _userRepository.updateIsAutoApproveReminder(
      uid,
      isAutoApproveReminder,
    );
  }
}

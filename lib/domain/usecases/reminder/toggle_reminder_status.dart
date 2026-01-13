import 'package:couple_note/core/utils/result.dart';
import 'package:couple_note/domain/entities/reminder.dart';
import 'package:couple_note/domain/repositories/reminder_repository.dart';

class ToggleReminderStatusUseCase {
  final ReminderRepository _repository;

  ToggleReminderStatusUseCase(this._repository);

  Future<Result<ReminderEntity>> call(
    ReminderEntity reminder,
    String userId,
  ) async {
    try {
      final apiResponse = await _repository.updateReminder(reminder);

      if (apiResponse.isSuccess) {
        return Result.success(reminder);
      } else {
        return Result.error('Cập nhật reminder thất bại');
      }
    } catch (e) {
      return Result.error('Lỗi khi cập nhật reminder: ${e.toString()}');
    }
  }
}

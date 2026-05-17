import 'package:couple_note/core/common/api_response.dart';
import 'package:couple_note/features/reminder/domain/entities/reminder.dart';
import 'package:couple_note/features/reminder/domain/repository/reminder_repository.dart';

class DeleteReminder {
  final ReminderRepository repository;

  DeleteReminder(this.repository);

  Future<ApiResponse<void>> call(ReminderEntity reminder, String userId) {
    return repository.deleteReminder(reminder, userId);
  }
}

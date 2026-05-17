import 'package:couple_note/core/common/api_response.dart';
import 'package:couple_note/features/reminder/domain/entities/reminder.dart';
import 'package:couple_note/features/reminder/domain/repository/reminder_repository.dart';

class UpdateReminder {
  final ReminderRepository repository;

  UpdateReminder(this.repository);

  Future<ApiResponse<ReminderEntity>> call(ReminderEntity reminder) {
    return repository.updateReminder(reminder);
  }
}

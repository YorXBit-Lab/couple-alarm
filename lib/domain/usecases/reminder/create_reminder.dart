import 'package:couple_note/core/common/api_response.dart';
import 'package:couple_note/domain/entities/reminder.dart';
import 'package:couple_note/domain/repositories/reminder_repository.dart';

class CreateReminder {
  final ReminderRepository repository;

  CreateReminder(this.repository);

  Future<ApiResponse<ReminderEntity>> call(ReminderEntity reminder) {
    return repository.createReminder(reminder);
  }
}

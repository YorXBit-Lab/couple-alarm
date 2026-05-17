import 'package:couple_note/core/common/api_response.dart';
import 'package:couple_note/features/reminder/domain/entities/reminder.dart';
import 'package:couple_note/features/reminder/domain/repository/reminder_repository.dart';

class GetRemindersByUser {
  final ReminderRepository repository;

  GetRemindersByUser(this.repository);

  Future<ApiResponse<List<ReminderEntity>>> call(String userId) {
    return repository.getRemindersByUser(userId);
  }
}

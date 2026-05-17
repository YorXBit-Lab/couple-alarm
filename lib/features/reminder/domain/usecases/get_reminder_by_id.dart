import 'package:couple_note/core/common/api_response.dart';
import 'package:couple_note/features/reminder/domain/entities/reminder.dart';
import 'package:couple_note/features/reminder/domain/repository/reminder_repository.dart';

class GetReminderById {
  final ReminderRepository repository;

  GetReminderById(this.repository);

  Future<ApiResponse<ReminderEntity>> call(String id) {
    return repository.getReminderById(id);
  }
}

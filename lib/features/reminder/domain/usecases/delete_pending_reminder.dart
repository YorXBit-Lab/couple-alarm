import 'package:couple_note/core/common/api_response.dart';
import 'package:couple_note/features/reminder/domain/repository/reminder_repository.dart';

class DeletePendingReminder {
  final ReminderRepository repository;

  DeletePendingReminder(this.repository);

  Future<ApiResponse<void>> call(String currentUserId, String loverId) {
    return repository.deletePendingReminder(currentUserId, loverId);
  }
}

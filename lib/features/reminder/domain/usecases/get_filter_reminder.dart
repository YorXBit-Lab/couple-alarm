import 'package:couple_note/core/common/api_response.dart';
import 'package:couple_note/features/reminder/domain/entities/reminder.dart';
import 'package:couple_note/features/reminder/domain/repository/reminder_repository.dart';

class GetFiltereRemindersWithOptionsUseCase {
  final ReminderRepository _repository;

  GetFiltereRemindersWithOptionsUseCase(this._repository);

  Stream<ApiResponse<List<ReminderEntity>>> call(
    String userId,
    ReminderFilterOptions filterOptions,
    String currentUserId,
  ) {
    return _repository.getRemindersWithFilter(
      userId,
      filterOptions,
      currentUserId,
    );
  }
}

import 'package:couple_note/core/common/api_response.dart';
import 'package:couple_note/domain/repositories/reminder_repository.dart';

class MoveCoupleReminderToPersonal {
  final ReminderRepository repository;

  MoveCoupleReminderToPersonal(this.repository);

  Future<ApiResponse<void>> call(
    String currentUserId,
    String loverId,
    String coupleId,
  ) {
    return repository.moveCoupleReminderToPersonal(
      currentUserId,
      loverId,
      coupleId,
    );
  }
}

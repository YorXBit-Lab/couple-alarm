import 'package:couple_note/core/providers/global_providers.dart';
import 'package:couple_note/core/services/connectivity_service.dart';
import 'package:couple_note/features/reminder/data/repository/reminder_repository_impl.dart';
import 'package:couple_note/features/reminder/domain/repository/reminder_repository.dart';
import 'package:couple_note/features/reminder/domain/usecases/create_reminder.dart';
import 'package:couple_note/features/reminder/domain/usecases/delete_pending_reminder.dart';
import 'package:couple_note/features/reminder/domain/usecases/delete_reminder.dart';
import 'package:couple_note/features/reminder/domain/usecases/get_filter_reminder.dart';
import 'package:couple_note/features/reminder/domain/usecases/get_reminder_by_id.dart';
import 'package:couple_note/features/reminder/domain/usecases/get_reminders_by_user.dart';
import 'package:couple_note/features/reminder/domain/usecases/move_couple_reminder_to_personal.dart';
import 'package:couple_note/features/reminder/domain/usecases/toggle_reminder_status.dart';
import 'package:couple_note/features/reminder/domain/usecases/update_reminder.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'reminder_provider.g.dart';

@riverpod
ReminderRepository reminderRepository(Ref ref) {
  return ReminderRepositoryImpl(
    ref.read(firestoreProvider),
    ConnectivityService(),
  );
}

@riverpod
CreateReminder createReminderUseCase(Ref ref) {
  return CreateReminder(ref.read(reminderRepositoryProvider));
}

@riverpod
DeleteReminder deleteReminderUseCase(Ref ref) {
  return DeleteReminder(ref.read(reminderRepositoryProvider));
}

@riverpod
GetReminderById getReminderByIdUseCase(Ref ref) {
  return GetReminderById(ref.read(reminderRepositoryProvider));
}

@riverpod
GetRemindersByUser getRemindersByUserUseCase(Ref ref) {
  return GetRemindersByUser(ref.read(reminderRepositoryProvider));
}

@riverpod
UpdateReminder updateReminderUseCase(Ref ref) {
  return UpdateReminder(ref.read(reminderRepositoryProvider));
}

@riverpod
ToggleReminderStatusUseCase toggleReminderStatusUseCase(Ref ref) {
  return ToggleReminderStatusUseCase(ref.read(reminderRepositoryProvider));
}

@riverpod
GetFiltereRemindersWithOptionsUseCase getFilteredRemindersWithOptionsUseCase(
  Ref ref,
) {
  return GetFiltereRemindersWithOptionsUseCase(
    ref.read(reminderRepositoryProvider),
  );
}

@riverpod
MoveCoupleReminderToPersonal moveCoupleReminderToPersonalUseCase(Ref ref) {
  return MoveCoupleReminderToPersonal(ref.read(reminderRepositoryProvider));
}

@riverpod
DeletePendingReminder deletePendingReminderUseCase(Ref ref) {
  return DeletePendingReminder(ref.read(reminderRepositoryProvider));
}

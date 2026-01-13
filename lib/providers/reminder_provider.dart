import 'package:couple_note/domain/entities/reminder.dart';
import 'package:couple_note/domain/usecases/reminder/create_reminder.dart';
import 'package:couple_note/domain/usecases/reminder/delete_pending_reminder.dart';
import 'package:couple_note/domain/usecases/reminder/delete_reminder.dart';
import 'package:couple_note/domain/usecases/reminder/get_filter_reminder.dart';
import 'package:couple_note/domain/usecases/reminder/get_reminder_by_id.dart';
import 'package:couple_note/domain/usecases/reminder/get_reminders_by_user.dart';
import 'package:couple_note/domain/usecases/reminder/move_couple_reminder_to_personal.dart';
import 'package:couple_note/domain/usecases/reminder/toggle_reminder_status.dart';
import 'package:couple_note/domain/usecases/reminder/update_reminder.dart';
import 'package:couple_note/di/dependency_injection.dart';
import 'package:couple_note/presentation/viewmodels/reminder_viewmodel.dart';
import 'package:couple_note/providers/auth_provider.dart';
import 'package:couple_note/providers/connect_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';

// ========================================
// Use Case Providers
// ========================================

final createReminderUseCaseProvider = Provider<CreateReminder>((ref) {
  final repository = ref.watch(reminderRepositoryProvider);
  return CreateReminder(repository);
});

final deleteReminderUseCaseProvider = Provider<DeleteReminder>((ref) {
  final repository = ref.watch(reminderRepositoryProvider);
  return DeleteReminder(repository);
});

final getReminderByIdUseCaseProvider = Provider<GetReminderById>((ref) {
  final repository = ref.watch(reminderRepositoryProvider);
  return GetReminderById(repository);
});

final getRemindersByUserUseCaseProvider = Provider<GetRemindersByUser>((ref) {
  final repository = ref.watch(reminderRepositoryProvider);
  return GetRemindersByUser(repository);
});

final updateReminderUseCaseProvider = Provider<UpdateReminder>((ref) {
  final repository = ref.watch(reminderRepositoryProvider);
  return UpdateReminder(repository);
});

final toggleReminderStatusUseCaseProvider =
    Provider<ToggleReminderStatusUseCase>((ref) {
      final repository = ref.watch(reminderRepositoryProvider);
      return ToggleReminderStatusUseCase(repository);
    });

final getFilteredRemindersWithOptionsUseCaseProvider =
    Provider<GetFiltereRemindersWithOptionsUseCase>((ref) {
      final repository = ref.watch(reminderRepositoryProvider);
      return GetFiltereRemindersWithOptionsUseCase(repository);
    });

final moveCoupleReminderToPersonalUseCaseProvider =
    Provider<MoveCoupleReminderToPersonal>((ref) {
      final repository = ref.watch(reminderRepositoryProvider);
      return MoveCoupleReminderToPersonal(repository);
    });

final deletePendingReminderUseCaseProvider = Provider<DeletePendingReminder>((
  ref,
) {
  final repository = ref.watch(reminderRepositoryProvider);
  return DeletePendingReminder(repository);
});
// ========================================
// Reminder ViewModel Provider
// ========================================

final reminderListViewModelProvider =
    StateNotifierProvider<ReminderViewModel, ReminderState>((ref) {
      final partner = ref.watch(partnerProvider).value?.data;
      final currentUser = ref.watch(currentUserProvider);

      return ReminderViewModel(
        useCases: ReminderUseCases(
          createReminderUseCase: ref.watch(createReminderUseCaseProvider),
          deleteReminderUseCase: ref.watch(deleteReminderUseCaseProvider),
          getReminderByIdUseCase: ref.watch(getReminderByIdUseCaseProvider),
          getRemindersByUserUseCase: ref.watch(
            getRemindersByUserUseCaseProvider,
          ),
          updateReminderUseCase: ref.watch(updateReminderUseCaseProvider),
          toggleReminderStatusUseCase: ref.watch(
            toggleReminderStatusUseCaseProvider,
          ),
          getRemindersWithFilterUseCase: ref.watch(
            getFilteredRemindersWithOptionsUseCaseProvider,
          ),
        ),
        connectivityService: ref.watch(connectivityServiceProvider),

        currentUserTabId: currentUser?.uid,
        partner: partner,
        ref: ref,
      );
    });

// ========================================
// Derived State Providers (Computed)
// ========================================

final reminderLoadingProvider = Provider<bool>((ref) {
  return ref.watch(reminderListViewModelProvider).isLoading;
});

final reminderActionLoadingProvider = Provider<bool>((ref) {
  return ref.watch(reminderListViewModelProvider).isActionLoading;
});

final reminderErrorProvider = Provider<String?>((ref) {
  return ref.watch(reminderListViewModelProvider).errorMessage;
});

final reminderListProvider = Provider<List<ReminderEntity>>((ref) {
  return ref.watch(reminderListViewModelProvider).reminders;
});

final selectedReminderProvider = Provider<ReminderEntity?>((ref) {
  return ref.watch(reminderListViewModelProvider).selectedReminder;
});

final currentReminderTabProvider = Provider<String>((ref) {
  return ref.watch(reminderListViewModelProvider).currentTab;
});

final hasActiveReminderFiltersProvider = Provider<bool>((ref) {
  final vm = ref.watch(reminderListViewModelProvider.notifier);
  return vm.hasActiveFilters;
});

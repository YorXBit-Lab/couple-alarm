import 'package:couple_note/core/services/lib/core/services/connectivity_service.dart';
import 'package:couple_note/di/dependency_injection.dart';
import 'package:couple_note/presentation/viewmodels/connect_viewmodel.dart';
import 'package:couple_note/providers/reminder_provider.dart';
import 'package:couple_note/providers/scanner_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';

final connectionViewModelProvider =
    StateNotifierProvider<ConnectViewModel, ConnectionState>((ref) {
      return ConnectViewModel(
        getCoupleByUserIdUseCase: ref.read(getCoupleByUserIdUseCaseProvider),
        getPendingInvitationsUseCase: ref.read(
          getPendingInvitationsUseCaseProvider,
        ),
        updateInvitationStatusUseCase: ref.read(updateInvitationStatusProvider),
        deleteCoupleUseCase: ref.read(deleteCoupleUseCaseProvider),

        moveCoupleReminderToPersonal: ref.read(
          moveCoupleReminderToPersonalUseCaseProvider,
        ),
        deletePendingReminder: ref.read(deletePendingReminderUseCaseProvider),
        ref: ref,
      );
    });

final connectivityServiceProvider = Provider<ConnectivityService>((ref) {
  final service = ConnectivityService();
  ref.onDispose(() => service.dispose());
  return service;
});

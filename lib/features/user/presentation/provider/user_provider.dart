import 'package:couple_note/core/providers/global_providers.dart';
import 'package:couple_note/features/user/data/repository/user_repository_impl.dart';
import 'package:couple_note/features/user/domain/repository/user_repository.dart';
import 'package:couple_note/features/user/domain/usecases/update_is_auto_approve_reminder_usecase.dart';
import 'package:couple_note/features/user/domain/usecases/update_nickname_usecase.dart';
import 'package:couple_note/features/user/domain/usecases/update_user_usecase.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'user_provider.g.dart';

@riverpod
UserRepository userRepository(Ref ref) {
  return UserRepositoryImpl(ref.watch(firestoreProvider));
}

@riverpod
UpdateNicknameUseCase updateNicknameUseCase(Ref ref) {
  return UpdateNicknameUseCase(ref.watch(userRepositoryProvider));
}

@riverpod
UpdateIsAutoApproveReminderUseCase updateIsAutoApproveReminderUseCase(
  Ref ref,
) {
  return UpdateIsAutoApproveReminderUseCase(ref.watch(userRepositoryProvider));
}

@riverpod
UpdateUserUseCase updateUserUseCase(Ref ref) {
  return UpdateUserUseCase(ref.watch(userRepositoryProvider));
}

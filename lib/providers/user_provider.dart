import 'package:couple_note/core/common/api_response.dart';
import 'package:couple_note/domain/entities/user.dart';
import 'package:couple_note/domain/usecases/user/update_is_auto_approve_reminder_usecase.dart';
import 'package:couple_note/domain/usecases/user/update_nickname_usecase.dart';
import 'package:couple_note/domain/usecases/user/update_user_usecase.dart';
import 'package:couple_note/providers/auth_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final updateNicknameUseCaseProvider = Provider<UpdateNicknameUseCase>((ref) {
  final userRepository = ref.watch(userRepositoryProvider);
  return UpdateNicknameUseCase(userRepository);
});

final updateIsAutoApproveReminderUseCaseProvider =
    Provider<UpdateIsAutoApproveReminderUseCase>((ref) {
      final userRepository = ref.watch(userRepositoryProvider);
      return UpdateIsAutoApproveReminderUseCase(userRepository);
    });

final updateUserUseCaseProvider = Provider<UpdateUserUseCase>((ref) {
  final userRepository = ref.watch(userRepositoryProvider);
  return UpdateUserUseCase(userRepository);
});

final currentUserStreamProvider = StreamProvider<ApiResponse<UserEntity?>>((
  ref,
) {
  final authState = ref.watch(authViewModelProvider);
  final userId = authState.currentUser?.uid;

  if (userId == null || userId.isEmpty) {
    return Stream.value(ApiResponse<UserEntity?>.success(null));
  }

  final repository = ref.read(userRepositoryProvider);
  return repository.watchUser(userId);
});

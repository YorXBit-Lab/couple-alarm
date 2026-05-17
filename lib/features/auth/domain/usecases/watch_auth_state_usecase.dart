import 'package:couple_note/features/user/domain/entities/user.dart';
import 'package:couple_note/features/auth/domain/repository/auth_repository.dart';

class WatchAuthStateUseCase {
  final AuthRepository _authRepository;

  WatchAuthStateUseCase(this._authRepository);

  Stream<UserEntity?> call() {
    return _authRepository.authStateChanges;
  }
}

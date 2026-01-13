import 'package:couple_note/domain/entities/user.dart';
import 'package:couple_note/domain/repositories/auth_repository.dart';

class WatchAuthStateUseCase {
  final AuthRepository _authRepository;

  WatchAuthStateUseCase(this._authRepository);

  Stream<UserEntity?> call() {
    return _authRepository.authStateChanges;
  }
}

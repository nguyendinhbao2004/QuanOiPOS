import '../entities/login_result.dart';
import '../repositories/auth_repository.dart';

class RestoreSessionUseCase {
  final AuthRepository _repository;

  const RestoreSessionUseCase(this._repository);

  Future<LoginResult?> call() {
    return _repository.restoreSession();
  }
}

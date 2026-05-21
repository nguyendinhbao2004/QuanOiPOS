import '../entities/login_result.dart';
import '../repositories/auth_repository.dart';

class LoginUseCase {
  final AuthRepository _repository;

  const LoginUseCase(this._repository);

  Future<LoginResult> call({required String email, required String password}) {
    return _repository.login(email: email, password: password);
  }
}

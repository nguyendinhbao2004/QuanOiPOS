import '../repositories/auth_repository.dart';

class ConfirmRegistrationUseCase {
  final AuthRepository _repository;

  const ConfirmRegistrationUseCase(this._repository);

  Future<void> call({required String email, required String otpCode}) {
    return _repository.confirmRegistration(email: email, otpCode: otpCode);
  }
}

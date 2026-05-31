import '../entities/current_user_profile.dart';
import '../repositories/auth_repository.dart';

class UpdateCurrentUserProfileUseCase {
  final AuthRepository _repository;

  const UpdateCurrentUserProfileUseCase(this._repository);

  Future<CurrentUserProfile> call({
    required String fullName,
    required String phone,
  }) {
    return _repository.updateCurrentUserProfile(
      fullName: fullName,
      phone: phone,
    );
  }
}

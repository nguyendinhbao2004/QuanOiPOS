import '../entities/current_user_profile.dart';
import '../repositories/auth_repository.dart';

class LoadCurrentUserProfileUseCase {
  final AuthRepository _repository;

  const LoadCurrentUserProfileUseCase(this._repository);

  Future<CurrentUserProfile> call() {
    return _repository.getCurrentUserProfile();
  }
}

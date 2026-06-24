import '../repositories/store_invitation_repository.dart';

class AcceptStoreInvitationUseCase {
  final StoreInvitationRepository _repository;

  const AcceptStoreInvitationUseCase(this._repository);

  Future<String> call(int invitationId) {
    return _repository.acceptInvitation(invitationId);
  }
}

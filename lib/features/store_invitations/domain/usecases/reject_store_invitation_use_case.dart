import '../repositories/store_invitation_repository.dart';

class RejectStoreInvitationUseCase {
  final StoreInvitationRepository _repository;

  const RejectStoreInvitationUseCase(this._repository);

  Future<String> call(int invitationId) {
    return _repository.rejectInvitation(invitationId);
  }
}

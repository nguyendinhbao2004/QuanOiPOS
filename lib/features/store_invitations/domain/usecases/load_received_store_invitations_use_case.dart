import '../entities/received_store_invitation.dart';
import '../repositories/store_invitation_repository.dart';

class LoadReceivedStoreInvitationsUseCase {
  final StoreInvitationRepository _repository;

  const LoadReceivedStoreInvitationsUseCase(this._repository);

  Future<List<ReceivedStoreInvitation>> call() {
    return _repository.loadReceivedInvitations();
  }
}

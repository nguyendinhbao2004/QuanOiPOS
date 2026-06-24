import '../entities/received_store_invitation.dart';

abstract class StoreInvitationRepository {
  Future<List<ReceivedStoreInvitation>> loadReceivedInvitations();

  Future<String> acceptInvitation(int invitationId);

  Future<String> rejectInvitation(int invitationId);
}

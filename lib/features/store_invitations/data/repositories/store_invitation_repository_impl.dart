import '../../domain/entities/received_store_invitation.dart';
import '../../domain/repositories/store_invitation_repository.dart';
import '../datasources/store_invitation_remote_data_source.dart';

class StoreInvitationRepositoryImpl implements StoreInvitationRepository {
  final StoreInvitationRemoteDataSource _remoteDataSource;

  const StoreInvitationRepositoryImpl(this._remoteDataSource);

  @override
  Future<List<ReceivedStoreInvitation>> loadReceivedInvitations() async {
    final invitations = await _remoteDataSource.getReceivedInvitations();
    return invitations.map((invitation) => invitation.toEntity()).toList();
  }

  @override
  Future<String> acceptInvitation(int invitationId) {
    return _remoteDataSource.acceptInvitation(invitationId);
  }

  @override
  Future<String> rejectInvitation(int invitationId) {
    return _remoteDataSource.rejectInvitation(invitationId);
  }
}

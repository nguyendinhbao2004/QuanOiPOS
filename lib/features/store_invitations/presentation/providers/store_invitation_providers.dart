import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/di/injection.dart';
import '../../data/datasources/store_invitation_remote_data_source.dart';
import '../../domain/entities/received_store_invitation.dart';
import '../../domain/repositories/store_invitation_repository.dart';
import '../../domain/usecases/accept_store_invitation_use_case.dart';
import '../../domain/usecases/load_received_store_invitations_use_case.dart';
import '../../domain/usecases/reject_store_invitation_use_case.dart';
import '../controllers/store_invitations_notifier.dart';
import '../controllers/store_invitations_state.dart';

final storeInvitationRemoteDataSourceProvider =
    Provider<StoreInvitationRemoteDataSource>((ref) {
      return locator<StoreInvitationRemoteDataSource>();
    });

final storeInvitationRepositoryProvider = Provider<StoreInvitationRepository>((
  ref,
) {
  return locator<StoreInvitationRepository>();
});

final loadReceivedStoreInvitationsUseCaseProvider =
    Provider<LoadReceivedStoreInvitationsUseCase>((ref) {
      if (locator.isRegistered<LoadReceivedStoreInvitationsUseCase>()) {
        return locator<LoadReceivedStoreInvitationsUseCase>();
      }

      return const LoadReceivedStoreInvitationsUseCase(
        _NoopStoreInvitationRepository(),
      );
    });

final acceptStoreInvitationUseCaseProvider =
    Provider<AcceptStoreInvitationUseCase>((ref) {
      if (locator.isRegistered<AcceptStoreInvitationUseCase>()) {
        return locator<AcceptStoreInvitationUseCase>();
      }

      return const AcceptStoreInvitationUseCase(
        _NoopStoreInvitationRepository(),
      );
    });

final rejectStoreInvitationUseCaseProvider =
    Provider<RejectStoreInvitationUseCase>((ref) {
      if (locator.isRegistered<RejectStoreInvitationUseCase>()) {
        return locator<RejectStoreInvitationUseCase>();
      }

      return const RejectStoreInvitationUseCase(
        _NoopStoreInvitationRepository(),
      );
    });

final storeInvitationsNotifierProvider =
    NotifierProvider.autoDispose<
      StoreInvitationsNotifier,
      StoreInvitationsState
    >(StoreInvitationsNotifier.new);

class _NoopStoreInvitationRepository implements StoreInvitationRepository {
  const _NoopStoreInvitationRepository();

  @override
  Future<String> acceptInvitation(int invitationId) async {
    return 'Chấp nhận lời mời thành công';
  }

  @override
  Future<List<ReceivedStoreInvitation>> loadReceivedInvitations() async {
    return const [];
  }

  @override
  Future<String> rejectInvitation(int invitationId) async {
    return 'Từ chối lời mời thành công';
  }
}

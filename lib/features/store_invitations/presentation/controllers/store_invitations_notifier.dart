import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/store_invitation_providers.dart';
import 'store_invitations_state.dart';

class StoreInvitationsNotifier
    extends AutoDisposeNotifier<StoreInvitationsState> {
  bool _initialLoadStarted = false;

  @override
  StoreInvitationsState build() {
    Future.microtask(loadInvitations);
    return const StoreInvitationsState.initial();
  }

  Future<void> loadInvitations() async {
    if (_initialLoadStarted && state.status == StoreInvitationsStatus.loading) {
      return;
    }

    _initialLoadStarted = true;
    state = state.copyWith(
      status: StoreInvitationsStatus.loading,
      clearError: true,
      clearProcessingInvitation: true,
    );

    try {
      final invitations = await ref.read(
        loadReceivedStoreInvitationsUseCaseProvider,
      )();
      state = state.copyWith(
        status: StoreInvitationsStatus.ready,
        invitations: invitations,
        clearError: true,
        clearProcessingInvitation: true,
      );
    } catch (error) {
      state = state.copyWith(
        status: StoreInvitationsStatus.error,
        errorMessage: _cleanError(error),
        clearProcessingInvitation: true,
      );
    }
  }

  Future<String> acceptInvitation(int invitationId) async {
    return _runInvitationAction(
      invitationId: invitationId,
      action: () =>
          ref.read(acceptStoreInvitationUseCaseProvider)(invitationId),
    );
  }

  Future<String> rejectInvitation(int invitationId) async {
    return _runInvitationAction(
      invitationId: invitationId,
      action: () =>
          ref.read(rejectStoreInvitationUseCaseProvider)(invitationId),
    );
  }

  Future<String> _runInvitationAction({
    required int invitationId,
    required Future<String> Function() action,
  }) async {
    state = state.copyWith(
      processingInvitationId: invitationId,
      clearError: true,
    );

    try {
      final message = await action();
      final invitations = state.invitations
          .where((item) => item.invitationId != invitationId)
          .toList();
      state = state.copyWith(
        status: StoreInvitationsStatus.ready,
        invitations: invitations,
        clearError: true,
        clearProcessingInvitation: true,
      );
      return message;
    } catch (error) {
      state = state.copyWith(
        errorMessage: _cleanError(error),
        clearProcessingInvitation: true,
      );
      rethrow;
    }
  }

  String _cleanError(Object error) {
    return error.toString().replaceFirst('Exception: ', '');
  }
}

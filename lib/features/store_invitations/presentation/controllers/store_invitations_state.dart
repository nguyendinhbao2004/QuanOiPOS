import '../../domain/entities/received_store_invitation.dart';

enum StoreInvitationsStatus { initial, loading, ready, error }

class StoreInvitationsState {
  final StoreInvitationsStatus status;
  final List<ReceivedStoreInvitation> invitations;
  final String? errorMessage;
  final int? processingInvitationId;

  const StoreInvitationsState({
    required this.status,
    this.invitations = const [],
    this.errorMessage,
    this.processingInvitationId,
  });

  const StoreInvitationsState.initial()
    : status = StoreInvitationsStatus.initial,
      invitations = const [],
      errorMessage = null,
      processingInvitationId = null;

  bool get isLoading => status == StoreInvitationsStatus.loading;

  List<ReceivedStoreInvitation> get pendingInvitations {
    final invitations =
        this.invitations.where((item) => item.isPending).toList()
          ..sort((left, right) {
            final leftTime = left.createdAt ?? left.expiresAt ?? DateTime(0);
            final rightTime = right.createdAt ?? right.expiresAt ?? DateTime(0);
            return rightTime.compareTo(leftTime);
          });
    return invitations;
  }

  int get pendingCount => pendingInvitations.length;

  bool isProcessing(int invitationId) {
    return processingInvitationId == invitationId;
  }

  StoreInvitationsState copyWith({
    StoreInvitationsStatus? status,
    List<ReceivedStoreInvitation>? invitations,
    String? errorMessage,
    int? processingInvitationId,
    bool clearError = false,
    bool clearProcessingInvitation = false,
  }) {
    return StoreInvitationsState(
      status: status ?? this.status,
      invitations: invitations ?? this.invitations,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      processingInvitationId: clearProcessingInvitation
          ? null
          : (processingInvitationId ?? this.processingInvitationId),
    );
  }
}

enum LastActiveStoreStatus { bootstrapping, ready, error }

class LastActiveStoreState {
  final LastActiveStoreStatus status;
  final int? lastStoreId;
  final String? errorMessage;

  const LastActiveStoreState({
    required this.status,
    this.lastStoreId,
    this.errorMessage,
  });

  const LastActiveStoreState.bootstrapping()
    : status = LastActiveStoreStatus.bootstrapping,
      lastStoreId = null,
      errorMessage = null;

  bool get isBootstrapping => status == LastActiveStoreStatus.bootstrapping;

  LastActiveStoreState copyWith({
    LastActiveStoreStatus? status,
    int? lastStoreId,
    String? errorMessage,
    bool clearLastStore = false,
    bool clearError = false,
  }) {
    return LastActiveStoreState(
      status: status ?? this.status,
      lastStoreId: clearLastStore ? null : (lastStoreId ?? this.lastStoreId),
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }
}

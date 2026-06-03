import '../../domain/entities/store.dart';

enum CreateStoreStatus { initial, submitting, success, failure }

class CreateStoreState {
  final CreateStoreStatus status;
  final Store? store;
  final String? errorMessage;

  const CreateStoreState({required this.status, this.store, this.errorMessage});

  const CreateStoreState.initial()
    : status = CreateStoreStatus.initial,
      store = null,
      errorMessage = null;

  bool get isSubmitting => status == CreateStoreStatus.submitting;

  CreateStoreState copyWith({
    CreateStoreStatus? status,
    Store? store,
    String? errorMessage,
    bool clearError = false,
  }) {
    return CreateStoreState(
      status: status ?? this.status,
      store: store ?? this.store,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }
}

import '../../domain/entities/store_access_context.dart';

enum StoreAccessStatus { initial, loading, ready, forbidden, error }

class StoreAccessState {
  final StoreAccessStatus status;
  final StoreAccessContext? context;
  final String? errorMessage;

  const StoreAccessState({
    required this.status,
    this.context,
    this.errorMessage,
  });

  const StoreAccessState.initial()
    : status = StoreAccessStatus.initial,
      context = null,
      errorMessage = null;

  bool get isLoading =>
      status == StoreAccessStatus.initial ||
      status == StoreAccessStatus.loading;

  bool can(String permissionCode) {
    return context?.can(permissionCode) ?? false;
  }

  StoreAccessState copyWith({
    StoreAccessStatus? status,
    StoreAccessContext? context,
    String? errorMessage,
    bool clearError = false,
  }) {
    return StoreAccessState(
      status: status ?? this.status,
      context: context ?? this.context,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }
}

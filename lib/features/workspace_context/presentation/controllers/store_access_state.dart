import '../../domain/entities/store_access_context.dart';

enum StoreAccessStatus { initial, loading, ready, forbidden, error }

class StoreAccessState {
  final StoreAccessStatus status;
  final StoreAccessContext? context;
  final String? errorMessage;
  final String? refreshErrorMessage;
  final bool isFromCache;
  final bool isRefreshing;

  const StoreAccessState({
    required this.status,
    this.context,
    this.errorMessage,
    this.refreshErrorMessage,
    this.isFromCache = false,
    this.isRefreshing = false,
  });

  const StoreAccessState.initial()
    : status = StoreAccessStatus.initial,
      context = null,
      errorMessage = null,
      refreshErrorMessage = null,
      isFromCache = false,
      isRefreshing = false;

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
    String? refreshErrorMessage,
    bool? isFromCache,
    bool? isRefreshing,
    bool clearContext = false,
    bool clearError = false,
    bool clearRefreshError = false,
  }) {
    return StoreAccessState(
      status: status ?? this.status,
      context: clearContext ? null : (context ?? this.context),
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      refreshErrorMessage: clearRefreshError
          ? null
          : (refreshErrorMessage ?? this.refreshErrorMessage),
      isFromCache: isFromCache ?? this.isFromCache,
      isRefreshing: isRefreshing ?? this.isRefreshing,
    );
  }
}

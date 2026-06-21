import '../../domain/entities/system_admin_dashboard.dart';

enum DashboardBlockStatus { loading, ready, empty, error }

class DashboardBlockState<T> {
  final DashboardBlockStatus status;
  final SystemAdminDashboardQuery query;
  final T? data;
  final String? errorMessage;
  final bool isRefreshing;

  const DashboardBlockState({
    required this.status,
    required this.query,
    this.data,
    this.errorMessage,
    this.isRefreshing = false,
  });

  factory DashboardBlockState.initial() => DashboardBlockState(
    status: DashboardBlockStatus.loading,
    query: initialDashboardQuery(),
  );

  DashboardBlockState<T> copyWith({
    DashboardBlockStatus? status,
    SystemAdminDashboardQuery? query,
    T? data,
    String? errorMessage,
    bool? isRefreshing,
    bool clearError = false,
  }) => DashboardBlockState(
    status: status ?? this.status,
    query: query ?? this.query,
    data: data ?? this.data,
    errorMessage: clearError ? null : errorMessage ?? this.errorMessage,
    isRefreshing: isRefreshing ?? this.isRefreshing,
  );
}

class DashboardPaymentsState {
  final DashboardBlockStatus status;
  final SystemAdminDashboardQuery query;
  final SubscriptionPaymentPage? data;
  final int pageIndex;
  final int pageSize;
  final String? errorMessage;
  final bool isRefreshing;

  const DashboardPaymentsState({
    required this.status,
    required this.query,
    this.data,
    this.pageIndex = 1,
    this.pageSize = 10,
    this.errorMessage,
    this.isRefreshing = false,
  });

  factory DashboardPaymentsState.initial() => DashboardPaymentsState(
    status: DashboardBlockStatus.loading,
    query: initialDashboardQuery(),
  );

  DashboardPaymentsState copyWith({
    DashboardBlockStatus? status,
    SystemAdminDashboardQuery? query,
    SubscriptionPaymentPage? data,
    int? pageIndex,
    String? errorMessage,
    bool? isRefreshing,
    bool clearError = false,
  }) => DashboardPaymentsState(
    status: status ?? this.status,
    query: query ?? this.query,
    data: data ?? this.data,
    pageIndex: pageIndex ?? this.pageIndex,
    pageSize: pageSize,
    errorMessage: clearError ? null : errorMessage ?? this.errorMessage,
    isRefreshing: isRefreshing ?? this.isRefreshing,
  );
}

SystemAdminDashboardQuery initialDashboardQuery() {
  final now = DateTime.now().toUtc();
  return SystemAdminDashboardQuery(
    from: DateTime.utc(now.year, now.month),
    to: DateTime.utc(now.year, now.month, now.day),
    groupBy: DashboardGroupBy.day,
    paymentStatus: DashboardPaymentStatus.all,
  );
}

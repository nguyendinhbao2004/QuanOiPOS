import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../mock/system_admin_dashboard_mock_data.dart';

class SystemAdminDashboardState {
  final DashboardLoadStatus status;
  final DashboardFilters filters;
  final SystemAdminDashboardData? data;
  final int pageIndex;
  final int pageSize;

  const SystemAdminDashboardState({
    required this.status,
    required this.filters,
    required this.data,
    this.pageIndex = 0,
    this.pageSize = 5,
  });

  List<SubscriptionPaymentItem> get filteredPayments {
    final source = data?.payments ?? const <SubscriptionPaymentItem>[];
    return source.where((payment) {
      final inPlan = filters.planId == null || payment.planId == filters.planId;
      final inStatus =
          filters.paymentStatus == DashboardPaymentStatus.all ||
          payment.status == filters.paymentStatus;
      final localCreatedAt = payment.createdAt.toLocal();
      final afterFrom = !localCreatedAt.isBefore(filters.from);
      final beforeTo = localCreatedAt.isBefore(
        filters.to.add(const Duration(days: 1)),
      );
      return inPlan && inStatus && afterFrom && beforeTo;
    }).toList();
  }

  int get pageCount {
    if (filteredPayments.isEmpty) return 1;
    return (filteredPayments.length / pageSize).ceil();
  }

  List<SubscriptionPaymentItem> get visiblePayments {
    final start = pageIndex * pageSize;
    if (start >= filteredPayments.length) return const [];
    final end = (start + pageSize).clamp(0, filteredPayments.length);
    return filteredPayments.sublist(start, end);
  }

  SystemAdminDashboardState copyWith({
    DashboardLoadStatus? status,
    DashboardFilters? filters,
    SystemAdminDashboardData? data,
    int? pageIndex,
  }) {
    return SystemAdminDashboardState(
      status: status ?? this.status,
      filters: filters ?? this.filters,
      data: data ?? this.data,
      pageIndex: pageIndex ?? this.pageIndex,
      pageSize: pageSize,
    );
  }
}

class SystemAdminDashboardMockNotifier
    extends Notifier<SystemAdminDashboardState> {
  @override
  SystemAdminDashboardState build() {
    return SystemAdminDashboardState(
      status: DashboardLoadStatus.ready,
      filters: DashboardFilters(
        from: DateTime(2026, 6),
        to: DateTime(2026, 6, 11),
        groupBy: DashboardGroupBy.day,
        planId: null,
        paymentStatus: DashboardPaymentStatus.all,
      ),
      data: SystemAdminDashboardMockData.data,
    );
  }

  void setDateRange(DateTime from, DateTime to) {
    state = state.copyWith(
      filters: state.filters.copyWith(from: from, to: to),
      pageIndex: 0,
    );
  }

  void setGroupBy(DashboardGroupBy value) {
    state = state.copyWith(
      filters: state.filters.copyWith(groupBy: value),
      pageIndex: 0,
    );
  }

  void setPlan(int? planId) {
    state = state.copyWith(
      filters: state.filters.copyWith(
        planId: planId,
        clearPlan: planId == null,
      ),
      pageIndex: 0,
    );
  }

  void setPaymentStatus(DashboardPaymentStatus value) {
    state = state.copyWith(
      filters: state.filters.copyWith(paymentStatus: value),
      pageIndex: 0,
    );
  }

  void previousPage() {
    if (state.pageIndex > 0) {
      state = state.copyWith(pageIndex: state.pageIndex - 1);
    }
  }

  void nextPage() {
    if (state.pageIndex + 1 < state.pageCount) {
      state = state.copyWith(pageIndex: state.pageIndex + 1);
    }
  }

  void retry() {
    state = state.copyWith(
      status: DashboardLoadStatus.ready,
      data: SystemAdminDashboardMockData.data,
      pageIndex: 0,
    );
  }
}

final systemAdminDashboardMockProvider =
    NotifierProvider<
      SystemAdminDashboardMockNotifier,
      SystemAdminDashboardState
    >(SystemAdminDashboardMockNotifier.new);

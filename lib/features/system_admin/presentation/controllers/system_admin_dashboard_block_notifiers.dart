import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/system_admin_dashboard.dart';
import 'system_admin_dashboard_block_state.dart';

abstract class DashboardBlockNotifier<T>
    extends Notifier<DashboardBlockState<T>> {
  int _requestVersion = 0;

  Future<T> fetch(SystemAdminDashboardQuery query);
  bool isEmpty(T data);

  @override
  DashboardBlockState<T> build() {
    Future.microtask(load);
    return DashboardBlockState<T>.initial();
  }

  Future<void> load() async {
    final requestVersion = ++_requestVersion;
    final hasData = state.data != null;
    state = state.copyWith(
      status: hasData
          ? DashboardBlockStatus.ready
          : DashboardBlockStatus.loading,
      isRefreshing: hasData,
      clearError: true,
    );
    try {
      final data = await fetch(state.query);
      if (requestVersion != _requestVersion) return;
      state = state.copyWith(
        status: isEmpty(data)
            ? DashboardBlockStatus.empty
            : DashboardBlockStatus.ready,
        data: data,
        isRefreshing: false,
        clearError: true,
      );
    } catch (error) {
      if (requestVersion != _requestVersion) return;
      state = state.copyWith(
        status: hasData
            ? DashboardBlockStatus.ready
            : DashboardBlockStatus.error,
        errorMessage: error.toString().replaceFirst('Exception: ', ''),
        isRefreshing: false,
      );
    }
  }

  Future<void> setDateRange(DateTime from, DateTime to) => _updateQuery(
    state.query.copyWith(
      from: DateTime.utc(from.year, from.month, from.day),
      to: DateTime.utc(to.year, to.month, to.day),
    ),
  );
  Future<void> setGroupBy(DashboardGroupBy groupBy) =>
      _updateQuery(state.query.copyWith(groupBy: groupBy));
  Future<void> setPlan(int? planId) => _updateQuery(
    state.query.copyWith(planId: planId, clearPlan: planId == null),
  );

  Future<void> _updateQuery(SystemAdminDashboardQuery query) async {
    state = state.copyWith(query: query);
    await load();
  }
}

class OverviewNotifier extends DashboardBlockNotifier<DashboardOverview> {
  final Future<DashboardOverview> Function(SystemAdminDashboardQuery) _loader;
  OverviewNotifier(this._loader);
  @override
  Future<DashboardOverview> fetch(SystemAdminDashboardQuery query) =>
      _loader(query);
  @override
  bool isEmpty(DashboardOverview data) => false;
}

class RevenueNotifier extends DashboardBlockNotifier<List<RevenuePoint>> {
  final Future<List<RevenuePoint>> Function(SystemAdminDashboardQuery) _loader;
  RevenueNotifier(this._loader);
  @override
  Future<List<RevenuePoint>> fetch(SystemAdminDashboardQuery query) =>
      _loader(query);
  @override
  bool isEmpty(List<RevenuePoint> data) => data.isEmpty;
}

class RevenueByPlanNotifier extends DashboardBlockNotifier<List<PlanRevenue>> {
  final Future<List<PlanRevenue>> Function(SystemAdminDashboardQuery) _loader;
  RevenueByPlanNotifier(this._loader);
  @override
  Future<List<PlanRevenue>> fetch(SystemAdminDashboardQuery query) =>
      _loader(query);
  @override
  bool isEmpty(List<PlanRevenue> data) => data.isEmpty;
}

class AccountGrowthNotifier
    extends DashboardBlockNotifier<List<AccountGrowthPoint>> {
  final Future<List<AccountGrowthPoint>> Function(SystemAdminDashboardQuery)
  _loader;
  AccountGrowthNotifier(this._loader);
  @override
  Future<List<AccountGrowthPoint>> fetch(SystemAdminDashboardQuery query) =>
      _loader(query);
  @override
  bool isEmpty(List<AccountGrowthPoint> data) => data.isEmpty;
}

class DistributionNotifier
    extends DashboardBlockNotifier<SubscriptionDistributionData> {
  final Future<SubscriptionDistributionData> Function(SystemAdminDashboardQuery)
  _loader;
  DistributionNotifier(this._loader);
  @override
  Future<SubscriptionDistributionData> fetch(SystemAdminDashboardQuery query) =>
      _loader(query);
  @override
  bool isEmpty(SubscriptionDistributionData data) => data.segments.isEmpty;
}

class PaymentsNotifier extends Notifier<DashboardPaymentsState> {
  final Future<SubscriptionPaymentPage> Function(
    SystemAdminDashboardQuery, {
    required int pageIndex,
    required int pageSize,
  })
  _loader;
  int _requestVersion = 0;
  PaymentsNotifier(this._loader);
  @override
  DashboardPaymentsState build() {
    Future.microtask(load);
    return DashboardPaymentsState.initial();
  }

  Future<void> load() async {
    final requestVersion = ++_requestVersion;
    final hasData = state.data != null;
    state = state.copyWith(
      status: hasData
          ? DashboardBlockStatus.ready
          : DashboardBlockStatus.loading,
      isRefreshing: hasData,
      clearError: true,
    );
    try {
      final data = await _loader(
        state.query,
        pageIndex: state.pageIndex,
        pageSize: state.pageSize,
      );
      if (requestVersion != _requestVersion) return;
      state = state.copyWith(
        status: data.items.isEmpty
            ? DashboardBlockStatus.empty
            : DashboardBlockStatus.ready,
        data: data,
        isRefreshing: false,
        clearError: true,
      );
    } catch (error) {
      if (requestVersion != _requestVersion) return;
      state = state.copyWith(
        status: hasData
            ? DashboardBlockStatus.ready
            : DashboardBlockStatus.error,
        errorMessage: error.toString().replaceFirst('Exception: ', ''),
        isRefreshing: false,
      );
    }
  }

  Future<void> setDateRange(DateTime from, DateTime to) => _updateQuery(
    state.query.copyWith(
      from: DateTime.utc(from.year, from.month, from.day),
      to: DateTime.utc(to.year, to.month, to.day),
    ),
  );
  Future<void> setPlan(int? planId) => _updateQuery(
    state.query.copyWith(planId: planId, clearPlan: planId == null),
  );
  Future<void> setPaymentStatus(DashboardPaymentStatus? status) => _updateQuery(
    state.query.copyWith(
      paymentStatus: status,
      clearPaymentStatus: status == null,
    ),
  );
  Future<void> previousPage() async {
    if (state.pageIndex > 1) {
      state = state.copyWith(pageIndex: state.pageIndex - 1);
      await load();
    }
  }

  Future<void> nextPage() async {
    if (state.pageIndex < (state.data?.totalPages ?? 1)) {
      state = state.copyWith(pageIndex: state.pageIndex + 1);
      await load();
    }
  }

  Future<void> _updateQuery(SystemAdminDashboardQuery query) async {
    state = state.copyWith(query: query, pageIndex: 1);
    await load();
  }
}

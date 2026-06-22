import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../core/di/injection.dart';
import '../../../domain/entities/system_admin_dashboard.dart';
import '../../../domain/usecases/load_system_admin_dashboard_blocks_use_cases.dart';
import '../../domain/entities/system_admin_subscription_plan.dart';
import '../../domain/usecases/system_admin_package_management_use_cases.dart';
import 'system_admin_package_management_state.dart';

class SystemAdminPackageManagementNotifier
    extends Notifier<SystemAdminPackageManagementState> {
  static const _pageSize = 10;
  bool _initialLoadStarted = false;

  @override
  SystemAdminPackageManagementState build() {
    if (!_initialLoadStarted) {
      _initialLoadStarted = true;
      Future.microtask(load);
    }
    return const SystemAdminPackageManagementState.initial();
  }

  Future<void> load({int? pageIndex}) async {
    final hasData = state.summary != null && state.page != null;
    state = state.copyWith(
      status: SystemAdminPackageManagementStatus.loading,
      isMutating: false,
      clearError: true,
    );
    final requestedPage = pageIndex ?? state.page?.pageIndex ?? 1;
    try {
      final results = await Future.wait<Object>([
        locator<LoadSystemAdminPlanSummaryUseCase>()(),
        locator<LoadSystemAdminPlansUseCase>()(
          status: state.filter,
          pageIndex: requestedPage,
          pageSize: _pageSize,
        ),
      ]);
      var page = results[1] as SystemAdminPlanPage;
      if (page.items.isEmpty && page.totalItems > 0 && page.pageIndex > 1) {
        page = await locator<LoadSystemAdminPlansUseCase>()(
          status: state.filter,
          pageIndex: page.totalPages,
          pageSize: _pageSize,
        );
      }
      final revenue = await _loadMonthlyRevenue();
      state = state.copyWith(
        status: SystemAdminPackageManagementStatus.ready,
        summary: results[0] as SystemAdminPlanSummary,
        page: page,
        monthlyRevenue: revenue,
        clearError: true,
      );
    } catch (error) {
      state = state.copyWith(
        status: hasData
            ? SystemAdminPackageManagementStatus.ready
            : SystemAdminPackageManagementStatus.error,
        errorMessage: _cleanError(error),
      );
    }
  }

  Future<void> setFilter(SystemAdminPlanStatus filter) async {
    if (filter == state.filter && state.page != null) return;
    state = state.copyWith(filter: filter);
    await load(pageIndex: 1);
  }

  Future<void> nextPage() async {
    final page = state.page;
    if (page != null && page.pageIndex < page.totalPages) {
      await load(pageIndex: page.pageIndex + 1);
    }
  }

  Future<void> previousPage() async {
    final page = state.page;
    if (page != null && page.pageIndex > 1) {
      await load(pageIndex: page.pageIndex - 1);
    }
  }

  Future<SystemAdminSubscriptionPlan> loadPlan(int id) =>
      locator<LoadSystemAdminPlanUseCase>()(id);

  Future<void> createPlan(UpsertSystemAdminSubscriptionPlan plan) =>
      _mutate(() => locator<CreateSystemAdminPlanUseCase>()(plan));
  Future<void> updatePlan(int id, UpsertSystemAdminSubscriptionPlan plan) =>
      _mutate(() => locator<UpdateSystemAdminPlanUseCase>()(id, plan));
  Future<void> activatePlan(int id) =>
      _mutate(() => locator<ActivateSystemAdminPlanUseCase>()(id));
  Future<void> deactivatePlan(int id) =>
      _mutate(() => locator<DeactivateSystemAdminPlanUseCase>()(id));
  Future<void> deletePlan(int id) =>
      _mutate(() => locator<DeleteSystemAdminPlanUseCase>()(id));

  Future<void> _mutate(Future<void> Function() action) async {
    state = state.copyWith(isMutating: true, clearError: true);
    try {
      await action();
      await load();
    } catch (error) {
      state = state.copyWith(
        isMutating: false,
        errorMessage: _cleanError(error),
      );
      rethrow;
    }
  }

  Future<double?> _loadMonthlyRevenue() async {
    final now = DateTime.now().toUtc();
    final query = SystemAdminDashboardQuery(
      from: DateTime.utc(now.year, now.month),
      to: DateTime.utc(now.year, now.month + 1, 0),
      groupBy: DashboardGroupBy.day,
    );
    try {
      return (await locator<LoadSystemAdminDashboardOverviewUseCase>()(
        query,
      )).subscriptionRevenue;
    } catch (_) {
      return null;
    }
  }

  String _cleanError(Object error) =>
      error.toString().replaceFirst('Exception: ', '');
}

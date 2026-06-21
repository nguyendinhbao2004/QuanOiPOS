import '../entities/system_admin_dashboard.dart';
import '../repositories/system_admin_dashboard_repository.dart';

class LoadSystemAdminDashboardOverviewUseCase {
  final SystemAdminDashboardRepository _repository;
  const LoadSystemAdminDashboardOverviewUseCase(this._repository);
  Future<DashboardOverview> call(SystemAdminDashboardQuery query) =>
      _repository.loadOverview(query);
}

class LoadSystemAdminRevenueSeriesUseCase {
  final SystemAdminDashboardRepository _repository;
  const LoadSystemAdminRevenueSeriesUseCase(this._repository);
  Future<List<RevenuePoint>> call(SystemAdminDashboardQuery query) =>
      _repository.loadRevenueSeries(query);
}

class LoadSystemAdminRevenueByPlanUseCase {
  final SystemAdminDashboardRepository _repository;
  const LoadSystemAdminRevenueByPlanUseCase(this._repository);
  Future<List<PlanRevenue>> call(SystemAdminDashboardQuery query) =>
      _repository.loadRevenueByPlan(query);
}

class LoadSystemAdminAccountGrowthUseCase {
  final SystemAdminDashboardRepository _repository;
  const LoadSystemAdminAccountGrowthUseCase(this._repository);
  Future<List<AccountGrowthPoint>> call(SystemAdminDashboardQuery query) =>
      _repository.loadAccountGrowth(query);
}

class LoadSystemAdminDistributionUseCase {
  final SystemAdminDashboardRepository _repository;
  const LoadSystemAdminDistributionUseCase(this._repository);
  Future<SubscriptionDistributionData> call(SystemAdminDashboardQuery query) =>
      _repository.loadDistribution(query);
}

class LoadSystemAdminPaymentsUseCase {
  final SystemAdminDashboardRepository _repository;
  const LoadSystemAdminPaymentsUseCase(this._repository);
  Future<SubscriptionPaymentPage> call(
    SystemAdminDashboardQuery query, {
    required int pageIndex,
    required int pageSize,
  }) =>
      _repository.loadPayments(query, pageIndex: pageIndex, pageSize: pageSize);
}

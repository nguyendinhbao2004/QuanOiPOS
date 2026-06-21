import '../entities/system_admin_dashboard.dart';

abstract class SystemAdminDashboardRepository {
  Future<DashboardOverview> loadOverview(SystemAdminDashboardQuery query);
  Future<List<RevenuePoint>> loadRevenueSeries(SystemAdminDashboardQuery query);
  Future<List<PlanRevenue>> loadRevenueByPlan(SystemAdminDashboardQuery query);
  Future<List<AccountGrowthPoint>> loadAccountGrowth(
    SystemAdminDashboardQuery query,
  );
  Future<SubscriptionDistributionData> loadDistribution(
    SystemAdminDashboardQuery query,
  );
  Future<SubscriptionPaymentPage> loadPayments(
    SystemAdminDashboardQuery query, {
    required int pageIndex,
    required int pageSize,
  });
}

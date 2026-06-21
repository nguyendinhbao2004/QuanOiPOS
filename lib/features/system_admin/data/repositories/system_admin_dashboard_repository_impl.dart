import '../../domain/entities/system_admin_dashboard.dart';
import '../../domain/repositories/system_admin_dashboard_repository.dart';
import '../datasources/system_admin_dashboard_remote_data_source.dart';

class SystemAdminDashboardRepositoryImpl
    implements SystemAdminDashboardRepository {
  final SystemAdminDashboardRemoteDataSource _remoteDataSource;
  const SystemAdminDashboardRepositoryImpl(this._remoteDataSource);
  @override
  Future<DashboardOverview> loadOverview(
    SystemAdminDashboardQuery query,
  ) async => (await _remoteDataSource.loadOverview(query)).value;

  @override
  Future<List<RevenuePoint>> loadRevenueSeries(
    SystemAdminDashboardQuery query,
  ) async => (await _remoteDataSource.loadRevenueSeries(query)).value;

  @override
  Future<List<PlanRevenue>> loadRevenueByPlan(
    SystemAdminDashboardQuery query,
  ) async => (await _remoteDataSource.loadRevenueByPlan(query)).value;

  @override
  Future<List<AccountGrowthPoint>> loadAccountGrowth(
    SystemAdminDashboardQuery query,
  ) async => (await _remoteDataSource.loadAccountGrowth(query)).value;

  @override
  Future<SubscriptionDistributionData> loadDistribution(
    SystemAdminDashboardQuery query,
  ) async {
    final response = await _remoteDataSource.loadDistribution(query);
    return SubscriptionDistributionData(
      segments: response.segments,
      trialSubscriptions: response.trialSubscriptions,
    );
  }

  @override
  Future<SubscriptionPaymentPage> loadPayments(
    SystemAdminDashboardQuery query, {
    required int pageIndex,
    required int pageSize,
  }) async => (await _remoteDataSource.loadPayments(
    query,
    pageIndex: pageIndex,
    pageSize: pageSize,
  )).value;
}

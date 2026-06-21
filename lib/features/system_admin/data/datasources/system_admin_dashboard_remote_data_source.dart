import '../../../../core/network/dio/dio_client.dart';
import '../../domain/entities/system_admin_dashboard.dart';
import '../models/system_admin_dashboard_models.dart';

class SystemAdminDashboardRemoteDataSource {
  final DioClient _dioClient;
  const SystemAdminDashboardRemoteDataSource(this._dioClient);

  Future<SystemAdminDashboardOverviewModel> loadOverview(
    SystemAdminDashboardQuery query,
  ) => _get(
    '/system-admin/dashboard/overview',
    query.toQueryParameters(),
    SystemAdminDashboardOverviewModel.fromJson,
    'Không thể tải tổng quan dashboard',
  );
  Future<RevenueSeriesModel> loadRevenueSeries(
    SystemAdminDashboardQuery query,
  ) => _get(
    '/system-admin/dashboard/subscription-revenue',
    query.toQueryParameters(),
    RevenueSeriesModel.fromJson,
    'Không thể tải chuỗi doanh thu',
  );
  Future<PlanRevenueModel> loadRevenueByPlan(SystemAdminDashboardQuery query) =>
      _get(
        '/system-admin/dashboard/revenue-by-plan',
        query.toQueryParameters(),
        PlanRevenueModel.fromJson,
        'Không thể tải doanh thu theo gói',
      );
  Future<AccountGrowthModel> loadAccountGrowth(
    SystemAdminDashboardQuery query,
  ) => _get(
    '/system-admin/dashboard/account-growth',
    query.toQueryParameters(),
    AccountGrowthModel.fromJson,
    'Không thể tải tăng trưởng tài khoản',
  );
  Future<SubscriptionDistributionModel> loadDistribution(
    SystemAdminDashboardQuery query,
  ) => _get(
    '/system-admin/dashboard/subscription-distribution',
    query.toQueryParameters(),
    SubscriptionDistributionModel.fromJson,
    'Không thể tải phân bổ subscription',
  );
  Future<SubscriptionPaymentPageModel> loadPayments(
    SystemAdminDashboardQuery query, {
    required int pageIndex,
    required int pageSize,
  }) => _get(
    '/system-admin/subscription-payments',
    {
      ...query.toQueryParameters(),
      'pageIndex': pageIndex,
      'pageSize': pageSize,
    },
    SubscriptionPaymentPageModel.fromJson,
    'Không thể tải danh sách thanh toán',
  );

  Future<T> _get<T>(
    String path,
    Map<String, dynamic> parameters,
    T Function(Object?) parser,
    String fallback,
  ) async {
    final response = await _dioClient.getResponse<T>(
      path,
      queryParameters: parameters,
      dataFromJson: parser,
    );
    if (response.succeeded && response.data != null) return response.data!;
    throw Exception(
      response.message?.trim().isNotEmpty == true
          ? response.message
          : response.errors.isNotEmpty
          ? response.errors.first
          : fallback,
    );
  }
}

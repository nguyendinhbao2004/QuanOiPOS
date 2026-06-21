import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/di/injection.dart';
import '../../../subscription/domain/entities/service_package.dart';
import '../../../subscription/domain/usecases/load_subscription_plans_use_case.dart';
import '../../data/datasources/system_admin_dashboard_remote_data_source.dart';
import '../../domain/entities/system_admin_dashboard.dart';
import '../../domain/repositories/system_admin_dashboard_repository.dart';
import '../../domain/usecases/load_system_admin_dashboard_blocks_use_cases.dart';
import '../controllers/system_admin_dashboard_block_notifiers.dart';
import '../controllers/system_admin_dashboard_block_state.dart';

final systemAdminDashboardRemoteDataSourceProvider =
    Provider<SystemAdminDashboardRemoteDataSource>(
      (ref) => locator<SystemAdminDashboardRemoteDataSource>(),
    );
final systemAdminDashboardRepositoryProvider =
    Provider<SystemAdminDashboardRepository>(
      (ref) => locator<SystemAdminDashboardRepository>(),
    );
final systemAdminDashboardPlansProvider = FutureProvider<List<ServicePackage>>((
  ref,
) async {
  final plans = await locator<LoadSubscriptionPlansUseCase>()();
  return plans.where((plan) => int.tryParse(plan.id) != null).toList();
});

final systemAdminOverviewProvider =
    NotifierProvider<OverviewNotifier, DashboardBlockState<DashboardOverview>>(
      () => OverviewNotifier(
        (query) => locator<LoadSystemAdminDashboardOverviewUseCase>()(query),
      ),
    );
final systemAdminRevenueProvider =
    NotifierProvider<RevenueNotifier, DashboardBlockState<List<RevenuePoint>>>(
      () => RevenueNotifier(
        (query) => locator<LoadSystemAdminRevenueSeriesUseCase>()(query),
      ),
    );
final systemAdminRevenueByPlanProvider =
    NotifierProvider<
      RevenueByPlanNotifier,
      DashboardBlockState<List<PlanRevenue>>
    >(
      () => RevenueByPlanNotifier(
        (query) => locator<LoadSystemAdminRevenueByPlanUseCase>()(query),
      ),
    );
final systemAdminAccountGrowthProvider =
    NotifierProvider<
      AccountGrowthNotifier,
      DashboardBlockState<List<AccountGrowthPoint>>
    >(
      () => AccountGrowthNotifier(
        (query) => locator<LoadSystemAdminAccountGrowthUseCase>()(query),
      ),
    );
final systemAdminDistributionProvider =
    NotifierProvider<
      DistributionNotifier,
      DashboardBlockState<SubscriptionDistributionData>
    >(
      () => DistributionNotifier(
        (query) => locator<LoadSystemAdminDistributionUseCase>()(query),
      ),
    );
final systemAdminPaymentsProvider =
    NotifierProvider<PaymentsNotifier, DashboardPaymentsState>(
      () => PaymentsNotifier(
        (query, {required pageIndex, required pageSize}) =>
            locator<LoadSystemAdminPaymentsUseCase>()(
              query,
              pageIndex: pageIndex,
              pageSize: pageSize,
            ),
      ),
    );

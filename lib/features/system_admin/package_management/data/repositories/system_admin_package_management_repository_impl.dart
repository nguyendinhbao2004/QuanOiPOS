import '../../domain/entities/system_admin_subscription_plan.dart';
import '../../domain/repositories/system_admin_package_management_repository.dart';
import '../datasources/system_admin_package_management_remote_data_source.dart';
import '../models/system_admin_subscription_plan_models.dart';

class SystemAdminPackageManagementRepositoryImpl
    implements SystemAdminPackageManagementRepository {
  final SystemAdminPackageManagementRemoteDataSource _remoteDataSource;
  const SystemAdminPackageManagementRepositoryImpl(this._remoteDataSource);

  @override
  Future<SystemAdminPlanSummary> loadSummary() async =>
      (await _remoteDataSource.loadSummary()).toEntity();
  @override
  Future<SystemAdminPlanPage> loadPlans({
    required SystemAdminPlanStatus status,
    required int pageIndex,
    required int pageSize,
  }) async => (await _remoteDataSource.loadPlans(
    status: status.apiValue,
    pageIndex: pageIndex,
    pageSize: pageSize,
  )).toEntity();
  @override
  Future<SystemAdminSubscriptionPlan> loadPlan(int id) async =>
      (await _remoteDataSource.loadPlan(id)).toEntity();
  @override
  Future<SystemAdminSubscriptionPlan> createPlan(
    UpsertSystemAdminSubscriptionPlan plan,
  ) async => (await _remoteDataSource.createPlan(
    UpsertSystemAdminSubscriptionPlanModel(plan),
  )).toEntity();
  @override
  Future<SystemAdminSubscriptionPlan> updatePlan(
    int id,
    UpsertSystemAdminSubscriptionPlan plan,
  ) async => (await _remoteDataSource.updatePlan(
    id,
    UpsertSystemAdminSubscriptionPlanModel(plan),
  )).toEntity();
  @override
  Future<void> activatePlan(int id) => _remoteDataSource.activatePlan(id);
  @override
  Future<void> deactivatePlan(int id) => _remoteDataSource.deactivatePlan(id);
  @override
  Future<void> deletePlan(int id) => _remoteDataSource.deletePlan(id);
}

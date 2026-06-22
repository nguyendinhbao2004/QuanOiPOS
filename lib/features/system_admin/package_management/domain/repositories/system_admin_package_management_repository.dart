import '../entities/system_admin_subscription_plan.dart';

abstract class SystemAdminPackageManagementRepository {
  Future<SystemAdminPlanSummary> loadSummary();
  Future<SystemAdminPlanPage> loadPlans({
    required SystemAdminPlanStatus status,
    required int pageIndex,
    required int pageSize,
  });
  Future<SystemAdminSubscriptionPlan> loadPlan(int id);
  Future<SystemAdminSubscriptionPlan> createPlan(
    UpsertSystemAdminSubscriptionPlan plan,
  );
  Future<SystemAdminSubscriptionPlan> updatePlan(
    int id,
    UpsertSystemAdminSubscriptionPlan plan,
  );
  Future<void> activatePlan(int id);
  Future<void> deactivatePlan(int id);
  Future<void> deletePlan(int id);
}

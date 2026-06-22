import '../entities/system_admin_subscription_plan.dart';
import '../repositories/system_admin_package_management_repository.dart';

class LoadSystemAdminPlanSummaryUseCase {
  final SystemAdminPackageManagementRepository _repository;
  const LoadSystemAdminPlanSummaryUseCase(this._repository);
  Future<SystemAdminPlanSummary> call() => _repository.loadSummary();
}

class LoadSystemAdminPlansUseCase {
  final SystemAdminPackageManagementRepository _repository;
  const LoadSystemAdminPlansUseCase(this._repository);
  Future<SystemAdminPlanPage> call({
    required SystemAdminPlanStatus status,
    required int pageIndex,
    required int pageSize,
  }) => _repository.loadPlans(
    status: status,
    pageIndex: pageIndex,
    pageSize: pageSize,
  );
}

class LoadSystemAdminPlanUseCase {
  final SystemAdminPackageManagementRepository _repository;
  const LoadSystemAdminPlanUseCase(this._repository);
  Future<SystemAdminSubscriptionPlan> call(int id) => _repository.loadPlan(id);
}

class CreateSystemAdminPlanUseCase {
  final SystemAdminPackageManagementRepository _repository;
  const CreateSystemAdminPlanUseCase(this._repository);
  Future<SystemAdminSubscriptionPlan> call(
    UpsertSystemAdminSubscriptionPlan plan,
  ) => _repository.createPlan(plan);
}

class UpdateSystemAdminPlanUseCase {
  final SystemAdminPackageManagementRepository _repository;
  const UpdateSystemAdminPlanUseCase(this._repository);
  Future<SystemAdminSubscriptionPlan> call(
    int id,
    UpsertSystemAdminSubscriptionPlan plan,
  ) => _repository.updatePlan(id, plan);
}

class ActivateSystemAdminPlanUseCase {
  final SystemAdminPackageManagementRepository _repository;
  const ActivateSystemAdminPlanUseCase(this._repository);
  Future<void> call(int id) => _repository.activatePlan(id);
}

class DeactivateSystemAdminPlanUseCase {
  final SystemAdminPackageManagementRepository _repository;
  const DeactivateSystemAdminPlanUseCase(this._repository);
  Future<void> call(int id) => _repository.deactivatePlan(id);
}

class DeleteSystemAdminPlanUseCase {
  final SystemAdminPackageManagementRepository _repository;
  const DeleteSystemAdminPlanUseCase(this._repository);
  Future<void> call(int id) => _repository.deletePlan(id);
}

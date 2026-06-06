import '../entities/permission_group.dart';
import '../repositories/staff_management_repository.dart';

class LoadStaffPermissionGroupsUseCase {
  final StaffManagementRepository _repository;

  const LoadStaffPermissionGroupsUseCase(this._repository);

  Future<List<PermissionGroup>> call(int storeId) {
    return _repository.loadPermissionGroups(storeId);
  }
}

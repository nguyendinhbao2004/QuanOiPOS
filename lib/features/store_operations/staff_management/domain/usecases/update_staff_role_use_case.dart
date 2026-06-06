import '../entities/staff_role.dart';
import '../repositories/staff_management_repository.dart';

class UpdateStaffRoleUseCase {
  final StaffManagementRepository _repository;

  const UpdateStaffRoleUseCase(this._repository);

  Future<StaffRole> call({
    required int storeId,
    required int roleId,
    required String name,
    required List<int> permissionIds,
  }) {
    return _repository.updateRole(
      storeId: storeId,
      roleId: roleId,
      name: name,
      permissionIds: permissionIds,
    );
  }
}

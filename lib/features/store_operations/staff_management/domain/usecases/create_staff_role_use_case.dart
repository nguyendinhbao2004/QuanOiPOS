import '../entities/staff_role.dart';
import '../repositories/staff_management_repository.dart';

class CreateStaffRoleUseCase {
  final StaffManagementRepository _repository;

  const CreateStaffRoleUseCase(this._repository);

  Future<StaffRole> call({
    required int storeId,
    required String name,
    required List<int> permissionIds,
  }) {
    return _repository.createRole(
      storeId: storeId,
      name: name,
      permissionIds: permissionIds,
    );
  }
}

import '../repositories/staff_management_repository.dart';

class DeleteStaffRoleUseCase {
  final StaffManagementRepository _repository;

  const DeleteStaffRoleUseCase(this._repository);

  Future<void> call({required int storeId, required int roleId}) {
    return _repository.deleteRole(storeId: storeId, roleId: roleId);
  }
}

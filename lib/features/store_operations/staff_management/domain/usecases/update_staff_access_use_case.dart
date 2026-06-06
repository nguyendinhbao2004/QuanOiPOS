import '../repositories/staff_management_repository.dart';

class UpdateStaffAccessUseCase {
  final StaffManagementRepository _repository;

  const UpdateStaffAccessUseCase(this._repository);

  Future<void> call({
    required int storeId,
    required int storeUserId,
    required int roleId,
    required List<int> permissionIds,
  }) {
    return _repository.updateStaffAccess(
      storeId: storeId,
      storeUserId: storeUserId,
      roleId: roleId,
      permissionIds: permissionIds,
    );
  }
}

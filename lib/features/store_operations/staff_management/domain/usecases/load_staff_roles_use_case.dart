import '../entities/staff_role.dart';
import '../repositories/staff_management_repository.dart';

class LoadStaffRolesUseCase {
  final StaffManagementRepository _repository;

  const LoadStaffRolesUseCase(this._repository);

  Future<List<StaffRole>> call(int storeId) {
    return _repository.loadRoles(storeId);
  }
}

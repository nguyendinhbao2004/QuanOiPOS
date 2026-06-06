import '../entities/staff_member.dart';
import '../repositories/staff_management_repository.dart';

class LoadStaffMembersUseCase {
  final StaffManagementRepository _repository;

  const LoadStaffMembersUseCase(this._repository);

  Future<List<StaffMember>> call(int storeId) {
    return _repository.loadStaff(storeId);
  }
}

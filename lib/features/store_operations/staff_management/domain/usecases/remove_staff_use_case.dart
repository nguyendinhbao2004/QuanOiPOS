import '../repositories/staff_management_repository.dart';

class RemoveStaffUseCase {
  final StaffManagementRepository _repository;

  const RemoveStaffUseCase(this._repository);

  Future<void> call({required int storeId, required int storeUserId}) {
    return _repository.removeStaff(storeId: storeId, storeUserId: storeUserId);
  }
}

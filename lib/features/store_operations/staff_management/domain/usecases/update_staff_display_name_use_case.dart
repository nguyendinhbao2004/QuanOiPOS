import '../repositories/staff_management_repository.dart';

class UpdateStaffDisplayNameUseCase {
  final StaffManagementRepository _repository;

  const UpdateStaffDisplayNameUseCase(this._repository);

  Future<void> call({
    required int storeId,
    required int storeUserId,
    required String displayName,
  }) {
    return _repository.updateStaffDisplayName(
      storeId: storeId,
      storeUserId: storeUserId,
      displayName: displayName,
    );
  }
}

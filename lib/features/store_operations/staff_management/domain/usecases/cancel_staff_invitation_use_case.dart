import '../repositories/staff_management_repository.dart';

class CancelStaffInvitationUseCase {
  final StaffManagementRepository _repository;

  const CancelStaffInvitationUseCase(this._repository);

  Future<void> call({required int storeId, required int invitationId}) {
    return _repository.cancelInvitation(
      storeId: storeId,
      invitationId: invitationId,
    );
  }
}

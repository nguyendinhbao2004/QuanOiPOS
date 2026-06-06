import '../entities/staff_invitation.dart';
import '../repositories/staff_management_repository.dart';

class InviteStaffUseCase {
  final StaffManagementRepository _repository;

  const InviteStaffUseCase(this._repository);

  Future<StaffInvitation> call({
    required int storeId,
    required String invitedEmail,
    required String displayName,
    required int roleId,
    required List<int> permissionIds,
  }) {
    return _repository.inviteStaff(
      storeId: storeId,
      invitedEmail: invitedEmail,
      displayName: displayName,
      roleId: roleId,
      permissionIds: permissionIds,
    );
  }
}

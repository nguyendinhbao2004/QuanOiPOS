import '../entities/permission_group.dart';
import '../entities/staff_invitation.dart';
import '../entities/staff_member.dart';
import '../entities/staff_role.dart';

abstract class StaffManagementRepository {
  Future<List<StaffRole>> loadRoles(int storeId);

  Future<List<StaffMember>> loadStaff(int storeId);

  Future<List<PermissionGroup>> loadPermissionGroups(int storeId);

  Future<StaffInvitation> inviteStaff({
    required int storeId,
    required String invitedEmail,
    required String displayName,
    required int roleId,
    required List<int> permissionIds,
  });

  Future<void> cancelInvitation({
    required int storeId,
    required int invitationId,
  });

  Future<void> updateStaffDisplayName({
    required int storeId,
    required int storeUserId,
    required String displayName,
  });

  Future<void> updateStaffAccess({
    required int storeId,
    required int storeUserId,
    required int roleId,
    required List<int> permissionIds,
  });

  Future<void> removeStaff({required int storeId, required int storeUserId});

  Future<StaffRole> createRole({
    required int storeId,
    required String name,
    required List<int> permissionIds,
  });

  Future<StaffRole> updateRole({
    required int storeId,
    required int roleId,
    required String name,
    required List<int> permissionIds,
  });

  Future<void> deleteRole({required int storeId, required int roleId});
}

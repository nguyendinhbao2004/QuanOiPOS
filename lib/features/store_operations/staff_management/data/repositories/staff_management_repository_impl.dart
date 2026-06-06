import '../../domain/entities/permission_group.dart';
import '../../domain/entities/staff_invitation.dart';
import '../../domain/entities/staff_member.dart';
import '../../domain/entities/staff_role.dart';
import '../../domain/entities/staff_status.dart';
import '../../domain/repositories/staff_management_repository.dart';
import '../datasources/staff_management_remote_data_source.dart';
import '../models/staff_request_models.dart';

class StaffManagementRepositoryImpl implements StaffManagementRepository {
  final StaffManagementRemoteDataSource _remoteDataSource;

  const StaffManagementRepositoryImpl(this._remoteDataSource);

  @override
  Future<List<StaffRole>> loadRoles(int storeId) async {
    final roles = await _remoteDataSource.getRoles(storeId);
    final entities = roles.map((role) => role.toEntity()).toList();
    entities.sort((left, right) {
      if (left.isSystemRole != right.isSystemRole) {
        return left.isSystemRole ? -1 : 1;
      }

      return left.name.compareTo(right.name);
    });
    return entities;
  }

  @override
  Future<List<StaffMember>> loadStaff(int storeId) async {
    final staff = await _remoteDataSource.getStaff(storeId);
    final entities = staff.map((member) => member.toEntity()).toList();
    entities.sort((left, right) {
      if (left.isOwner != right.isOwner) {
        return left.isOwner ? -1 : 1;
      }

      if (left.status != right.status) {
        return left.status.isActive ? -1 : 1;
      }

      return left.primaryName.compareTo(right.primaryName);
    });
    return entities;
  }

  @override
  Future<List<PermissionGroup>> loadPermissionGroups(int storeId) async {
    final groups = await _remoteDataSource.getPermissionGroups(storeId);
    final entities = groups.map((group) => group.toEntity()).toList();
    entities.sort((left, right) => left.groupName.compareTo(right.groupName));
    return entities;
  }

  @override
  Future<StaffInvitation> inviteStaff({
    required int storeId,
    required String invitedEmail,
    required String displayName,
    required int roleId,
    required List<int> permissionIds,
  }) async {
    final invitation = await _remoteDataSource.inviteStaff(
      InviteStaffRequestModel(
        storeId: storeId,
        invitedEmail: invitedEmail,
        displayName: displayName,
        roleId: roleId,
        permissionIds: permissionIds,
      ),
    );
    return invitation.toEntity();
  }

  @override
  Future<void> cancelInvitation({
    required int storeId,
    required int invitationId,
  }) {
    return _remoteDataSource.cancelInvitation(
      storeId: storeId,
      invitationId: invitationId,
    );
  }

  @override
  Future<void> updateStaffDisplayName({
    required int storeId,
    required int storeUserId,
    required String displayName,
  }) {
    return _remoteDataSource.updateStaffDisplayName(
      storeId: storeId,
      storeUserId: storeUserId,
      request: UpdateStaffDisplayNameRequestModel(displayName: displayName),
    );
  }

  @override
  Future<void> updateStaffAccess({
    required int storeId,
    required int storeUserId,
    required int roleId,
    required List<int> permissionIds,
  }) {
    return _remoteDataSource.updateStaffAccess(
      storeId: storeId,
      storeUserId: storeUserId,
      request: UpdateStaffAccessRequestModel(
        roleId: roleId,
        permissionIds: permissionIds,
      ),
    );
  }

  @override
  Future<void> removeStaff({required int storeId, required int storeUserId}) {
    return _remoteDataSource.removeStaff(
      storeId: storeId,
      storeUserId: storeUserId,
    );
  }

  @override
  Future<StaffRole> createRole({
    required int storeId,
    required String name,
    required List<int> permissionIds,
  }) async {
    final role = await _remoteDataSource.createRole(
      storeId: storeId,
      request: StaffRoleRequestModel(name: name, permissionIds: permissionIds),
    );
    return role.toEntity();
  }

  @override
  Future<StaffRole> updateRole({
    required int storeId,
    required int roleId,
    required String name,
    required List<int> permissionIds,
  }) async {
    final role = await _remoteDataSource.updateRole(
      storeId: storeId,
      roleId: roleId,
      request: StaffRoleRequestModel(name: name, permissionIds: permissionIds),
    );
    return role.toEntity();
  }

  @override
  Future<void> deleteRole({required int storeId, required int roleId}) {
    return _remoteDataSource.deleteRole(storeId: storeId, roleId: roleId);
  }
}

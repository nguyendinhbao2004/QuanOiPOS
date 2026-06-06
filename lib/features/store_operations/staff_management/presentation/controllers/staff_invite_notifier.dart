import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/staff_management_providers.dart';
import 'staff_invite_state.dart';
import 'staff_management_access.dart';

class StaffInviteNotifier
    extends AutoDisposeFamilyNotifier<StaffInviteState, StaffManagementAccess> {
  late final StaffManagementAccess _access;

  @override
  StaffInviteState build(StaffManagementAccess arg) {
    _access = arg;
    Future.microtask(load);
    return const StaffInviteState.initial();
  }

  Future<void> load() async {
    if (!_access.canInviteStaff) {
      state = state.copyWith(
        status: StaffInviteStatus.error,
        errorMessage: 'Bạn chưa có quyền mời nhân viên',
      );
      return;
    }

    state = state.copyWith(status: StaffInviteStatus.loading, clearError: true);
    try {
      final roles = await ref.read(loadStaffRolesUseCaseProvider)(
        _access.storeId,
      );
      final permissionGroups = await ref.read(
        loadStaffPermissionGroupsUseCaseProvider,
      )(_access.storeId);
      state = state.copyWith(
        status: StaffInviteStatus.ready,
        roles: roles,
        permissionGroups: permissionGroups,
        clearError: true,
      );
    } catch (error) {
      state = state.copyWith(
        status: StaffInviteStatus.error,
        errorMessage: _cleanError(error),
      );
    }
  }

  void selectRole(int roleId) {
    final matchingRoles = state.roles.where((item) => item.id == roleId);
    final role = matchingRoles.isEmpty ? null : matchingRoles.first;
    if (role == null) {
      return;
    }

    state = state.copyWith(selectedRole: role);
  }

  Future<void> submit({
    required String displayName,
    required String invitedEmail,
  }) async {
    final role = state.selectedRole;
    if (role == null) {
      throw Exception('Vui lòng chọn vai trò');
    }

    if (!_access.canInviteStaff) {
      throw Exception('Bạn chưa có quyền mời nhân viên');
    }

    state = state.copyWith(
      status: StaffInviteStatus.submitting,
      clearError: true,
    );
    try {
      await ref.read(inviteStaffUseCaseProvider)(
        storeId: _access.storeId,
        invitedEmail: invitedEmail,
        displayName: displayName,
        roleId: role.id,
        permissionIds: role.permissionIds,
      );
      state = state.copyWith(status: StaffInviteStatus.success);
    } catch (error) {
      state = state.copyWith(
        status: StaffInviteStatus.error,
        errorMessage: _cleanError(error),
      );
      rethrow;
    }
  }

  String _cleanError(Object error) {
    return error.toString().replaceFirst('Exception: ', '');
  }
}

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/staff_management_providers.dart';
import 'staff_management_access.dart';
import 'staff_role_form_state.dart';

class StaffRoleFormArgs {
  final StaffManagementAccess access;
  final int? roleId;

  const StaffRoleFormArgs({required this.access, required this.roleId});

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is StaffRoleFormArgs &&
            access == other.access &&
            roleId == other.roleId;
  }

  @override
  int get hashCode => Object.hash(access, roleId);
}

class StaffRoleFormNotifier
    extends AutoDisposeFamilyNotifier<StaffRoleFormState, StaffRoleFormArgs> {
  late final StaffRoleFormArgs _args;

  @override
  StaffRoleFormState build(StaffRoleFormArgs arg) {
    _args = arg;
    Future.microtask(load);
    return const StaffRoleFormState.initial();
  }

  Future<void> load() async {
    if (!_args.access.canManageRoles) {
      state = state.copyWith(
        status: StaffRoleFormStatus.error,
        errorMessage: 'Bạn chưa có quyền quản lý vai trò',
      );
      return;
    }

    state = state.copyWith(
      status: StaffRoleFormStatus.loading,
      clearError: true,
    );
    try {
      final groups = await ref.read(loadStaffPermissionGroupsUseCaseProvider)(
        _args.access.storeId,
      );
      final roles = await ref.read(loadStaffRolesUseCaseProvider)(
        _args.access.storeId,
      );
      final roleId = _args.roleId;
      final matchingRoles = roleId == null
          ? roles.where((item) => false)
          : roles.where((item) => item.id == roleId);
      final role = matchingRoles.isEmpty ? null : matchingRoles.first;

      if (roleId != null && role == null) {
        throw Exception('Vai trò không tồn tại');
      }

      state = state.copyWith(
        status: StaffRoleFormStatus.ready,
        role: role,
        permissionGroups: groups,
        selectedPermissionIds: role?.permissionIds.toSet() ?? const {},
        clearRole: role == null,
        clearError: true,
      );
    } catch (error) {
      state = state.copyWith(
        status: StaffRoleFormStatus.error,
        errorMessage: _cleanError(error),
      );
    }
  }

  void togglePermission(int permissionId) {
    if (state.isSystemRole) {
      return;
    }

    final next = Set<int>.from(state.selectedPermissionIds);
    if (!next.add(permissionId)) {
      next.remove(permissionId);
    }

    state = state.copyWith(selectedPermissionIds: next);
  }

  void setGroupPermissions(List<int> permissionIds, bool isSelected) {
    if (state.isSystemRole) {
      return;
    }

    final next = Set<int>.from(state.selectedPermissionIds);
    if (isSelected) {
      next.addAll(permissionIds);
    } else {
      next.removeAll(permissionIds);
    }

    state = state.copyWith(selectedPermissionIds: next);
  }

  Future<void> save(String name) async {
    if (!_args.access.canManageRoles) {
      throw Exception('Bạn chưa có quyền quản lý vai trò');
    }

    if (state.isSystemRole) {
      throw Exception('Vai trò hệ thống không thể chỉnh sửa');
    }

    final cleanName = name.trim();
    if (cleanName.isEmpty) {
      throw Exception('Vui lòng nhập tên vai trò');
    }

    state = state.copyWith(
      status: StaffRoleFormStatus.saving,
      clearError: true,
    );
    try {
      final role = state.role;
      if (role == null) {
        await ref.read(createStaffRoleUseCaseProvider)(
          storeId: _args.access.storeId,
          name: cleanName,
          permissionIds: state.selectedPermissionIds.toList(),
        );
      } else {
        await ref.read(updateStaffRoleUseCaseProvider)(
          storeId: _args.access.storeId,
          roleId: role.id,
          name: cleanName,
          permissionIds: state.selectedPermissionIds.toList(),
        );
      }
      state = state.copyWith(status: StaffRoleFormStatus.ready);
    } catch (error) {
      state = state.copyWith(
        status: StaffRoleFormStatus.error,
        errorMessage: _cleanError(error),
      );
      rethrow;
    }
  }

  Future<void> deleteRole() async {
    final role = state.role;
    if (role == null) {
      return;
    }

    if (role.isSystemRole) {
      throw Exception('Vai trò hệ thống không thể xóa');
    }

    if (!_args.access.canManageRoles) {
      throw Exception('Bạn chưa có quyền quản lý vai trò');
    }

    state = state.copyWith(
      status: StaffRoleFormStatus.deleting,
      clearError: true,
    );
    try {
      await ref.read(deleteStaffRoleUseCaseProvider)(
        storeId: _args.access.storeId,
        roleId: role.id,
      );
    } catch (error) {
      state = state.copyWith(
        status: StaffRoleFormStatus.error,
        errorMessage: _cleanError(error),
      );
      rethrow;
    }
  }

  String _cleanError(Object error) {
    return error.toString().replaceFirst('Exception: ', '');
  }
}

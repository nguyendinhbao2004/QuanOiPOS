import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/staff_member.dart';
import '../providers/staff_management_providers.dart';
import 'staff_detail_state.dart';
import 'staff_management_access.dart';

class StaffDetailArgs {
  final StaffManagementAccess access;
  final int? storeUserId;
  final int? invitationId;

  const StaffDetailArgs({
    required this.access,
    this.storeUserId,
    this.invitationId,
  });

  bool get isPendingInvitation => invitationId != null;

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is StaffDetailArgs &&
            access == other.access &&
            storeUserId == other.storeUserId &&
            invitationId == other.invitationId;
  }

  @override
  int get hashCode => Object.hash(access, storeUserId, invitationId);
}

class StaffDetailNotifier
    extends AutoDisposeFamilyNotifier<StaffDetailState, StaffDetailArgs> {
  late final StaffDetailArgs _args;

  @override
  StaffDetailState build(StaffDetailArgs arg) {
    _args = arg;
    Future.microtask(load);
    return const StaffDetailState.initial();
  }

  Future<void> load() async {
    if (!_args.access.canOpenStaffModule) {
      state = state.copyWith(
        status: StaffDetailStatus.forbidden,
        errorMessage: 'Bạn chưa có quyền quản lý nhân viên',
      );
      return;
    }

    state = state.copyWith(status: StaffDetailStatus.loading, clearError: true);
    try {
      final staff = await ref.read(loadStaffMembersUseCaseProvider)(
        _args.access.storeId,
      );
      final roles = await ref.read(loadStaffRolesUseCaseProvider)(
        _args.access.storeId,
      );
      final groups = await ref.read(loadStaffPermissionGroupsUseCaseProvider)(
        _args.access.storeId,
      );
      final member = _findMember(staff);

      if (member == null) {
        throw Exception('Nhân viên không tồn tại');
      }

      final roleId = member.role?.id;
      final permissionIds = member.permissions.isNotEmpty
          ? member.permissions.map((permission) => permission.id).toSet()
          : (member.role?.permissionIds.toSet() ?? const <int>{});

      state = state.copyWith(
        status: StaffDetailStatus.ready,
        member: member,
        roles: roles,
        permissionGroups: groups,
        selectedRoleId: roleId,
        selectedPermissionIds: permissionIds,
        clearError: true,
      );
    } catch (error) {
      state = state.copyWith(
        status: StaffDetailStatus.error,
        errorMessage: _cleanError(error),
      );
    }
  }

  void selectRole(int roleId) {
    final matchingRoles = state.roles.where((role) => role.id == roleId);
    if (matchingRoles.isEmpty) {
      return;
    }

    state = state.copyWith(
      selectedRoleId: roleId,
      selectedPermissionIds: matchingRoles.first.permissionIds.toSet(),
    );
  }

  void togglePermission(int permissionId) {
    final member = state.member;
    if (member == null || member.isOwner || !_args.access.canUpdateStaff) {
      return;
    }

    final next = Set<int>.from(state.selectedPermissionIds);
    if (!next.add(permissionId)) {
      next.remove(permissionId);
    }

    state = state.copyWith(selectedPermissionIds: next);
  }

  void setGroupPermissions(List<int> permissionIds, bool isSelected) {
    final member = state.member;
    if (member == null || member.isOwner || !_args.access.canUpdateStaff) {
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

  Future<void> updateDisplayName(String displayName) async {
    final member = state.member;
    final storeUserId = member?.storeUserId;
    if (member == null || storeUserId == null) {
      throw Exception('Không thể sửa lời mời đang chờ');
    }

    if (member.isOwner) {
      throw Exception('Không thể sửa chủ sở hữu');
    }

    _ensureAllowed(_args.access.canUpdateStaff, 'Bạn chưa có quyền sửa tên');

    final cleanName = displayName.trim();
    if (cleanName.isEmpty) {
      throw Exception('Vui lòng nhập tên nhân viên');
    }

    await _runMutation(() async {
      await ref.read(updateStaffDisplayNameUseCaseProvider)(
        storeId: _args.access.storeId,
        storeUserId: storeUserId,
        displayName: cleanName,
      );
      await load();
    });
  }

  Future<void> updateStaff(String displayName) async {
    final member = state.member;
    final storeUserId = member?.storeUserId;
    final roleId = state.selectedRoleId;
    if (member == null || storeUserId == null) {
      throw Exception('Không thể sửa lời mời đang chờ');
    }

    if (member.isOwner) {
      throw Exception('Không thể sửa chủ sở hữu');
    }

    _ensureAllowed(
      _args.access.canUpdateStaff,
      'Bạn chưa có quyền cập nhật nhân viên',
    );

    final cleanName = displayName.trim();
    if (cleanName.isEmpty) {
      throw Exception('Vui lòng nhập tên nhân viên');
    }

    if (roleId == null) {
      throw Exception('Vui lòng chọn vai trò');
    }

    await _runMutation(() async {
      await ref.read(updateStaffDisplayNameUseCaseProvider)(
        storeId: _args.access.storeId,
        storeUserId: storeUserId,
        displayName: cleanName,
      );
      await ref.read(updateStaffAccessUseCaseProvider)(
        storeId: _args.access.storeId,
        storeUserId: storeUserId,
        roleId: roleId,
        permissionIds: state.selectedPermissionIds.toList(),
      );
      await load();
    });
  }

  Future<void> updateAccess() async {
    final member = state.member;
    final storeUserId = member?.storeUserId;
    final roleId = state.selectedRoleId;
    if (member == null || storeUserId == null) {
      throw Exception('Không thể sửa lời mời đang chờ');
    }

    if (member.isOwner) {
      throw Exception('Không thể sửa chủ sở hữu');
    }

    _ensureAllowed(
      _args.access.canUpdateStaff,
      'Bạn chưa có quyền sửa quyền nhân viên',
    );

    if (roleId == null) {
      throw Exception('Vui lòng chọn vai trò');
    }

    await _runMutation(() async {
      await ref.read(updateStaffAccessUseCaseProvider)(
        storeId: _args.access.storeId,
        storeUserId: storeUserId,
        roleId: roleId,
        permissionIds: state.selectedPermissionIds.toList(),
      );
      await load();
    });
  }

  Future<void> removeStaff() async {
    final member = state.member;
    final storeUserId = member?.storeUserId;
    if (member == null || storeUserId == null) {
      throw Exception('Không thể xóa lời mời đang chờ');
    }

    if (member.isOwner) {
      throw Exception('Không thể xóa chủ sở hữu');
    }

    _ensureAllowed(_args.access.canRemoveStaff, 'Bạn chưa có quyền xóa');

    await _runMutation(() async {
      await ref.read(removeStaffUseCaseProvider)(
        storeId: _args.access.storeId,
        storeUserId: storeUserId,
      );
    });
  }

  Future<void> cancelInvitation() async {
    final invitationId = state.member?.invitationId;
    if (invitationId == null) {
      throw Exception('Lời mời không tồn tại');
    }

    _ensureAllowed(
      _args.access.canInviteStaff,
      'Bạn chưa có quyền hủy lời mời',
    );

    await _runMutation(() async {
      await ref.read(cancelStaffInvitationUseCaseProvider)(
        storeId: _args.access.storeId,
        invitationId: invitationId,
      );
    });
  }

  StaffMember? _findMember(List<StaffMember> staff) {
    final storeUserId = _args.storeUserId;
    if (storeUserId != null) {
      final matches = staff.where(
        (member) => member.storeUserId == storeUserId,
      );
      return matches.isEmpty ? null : matches.first;
    }

    final invitationId = _args.invitationId;
    if (invitationId != null) {
      final matches = staff.where(
        (member) => member.invitationId == invitationId,
      );
      return matches.isEmpty ? null : matches.first;
    }

    return null;
  }

  Future<void> _runMutation(Future<void> Function() action) async {
    state = state.copyWith(isMutating: true, clearError: true);
    try {
      await action();
    } catch (error) {
      state = state.copyWith(errorMessage: _cleanError(error));
      rethrow;
    } finally {
      state = state.copyWith(isMutating: false);
    }
  }

  void _ensureAllowed(bool isAllowed, String message) {
    if (!isAllowed) {
      throw Exception(message);
    }
  }

  String _cleanError(Object error) {
    return error.toString().replaceFirst('Exception: ', '');
  }
}

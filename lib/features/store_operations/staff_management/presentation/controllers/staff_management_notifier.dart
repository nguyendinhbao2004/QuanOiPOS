import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/staff_member.dart';
import '../providers/staff_management_providers.dart';
import 'staff_management_access.dart';
import 'staff_management_state.dart';

class StaffManagementNotifier
    extends
        AutoDisposeFamilyNotifier<StaffManagementState, StaffManagementAccess> {
  late final StaffManagementAccess _access;
  bool _initialLoadStarted = false;

  @override
  StaffManagementState build(StaffManagementAccess arg) {
    _access = arg;
    Future.microtask(load);
    return const StaffManagementState.initial();
  }

  Future<void> load() async {
    if (_initialLoadStarted && state.status == StaffManagementStatus.loading) {
      return;
    }

    _initialLoadStarted = true;

    if (!_access.canOpenStaffModule) {
      state = state.copyWith(
        status: StaffManagementStatus.forbidden,
        errorMessage: 'Bạn chưa có quyền quản lý nhân viên',
      );
      return;
    }

    state = state.copyWith(
      status: StaffManagementStatus.loading,
      clearError: true,
    );

    try {
      final roles = await ref.read(loadStaffRolesUseCaseProvider)(
        _access.storeId,
      );
      final List<StaffMember> staff = _access.canViewStaff
          ? await ref.read(loadStaffMembersUseCaseProvider)(_access.storeId)
          : const [];

      state = state.copyWith(
        status: StaffManagementStatus.ready,
        staff: staff,
        roles: roles,
        clearError: true,
      );
    } catch (error) {
      state = state.copyWith(
        status: StaffManagementStatus.error,
        errorMessage: _cleanError(error),
      );
    }
  }

  Future<void> cancelInvitation(int invitationId) async {
    _ensureAllowed(_access.canInviteStaff, 'Bạn chưa có quyền hủy lời mời');
    await _runMutation(() async {
      await ref.read(cancelStaffInvitationUseCaseProvider)(
        storeId: _access.storeId,
        invitationId: invitationId,
      );
      await load();
    });
  }

  Future<void> updateDisplayName({
    required int storeUserId,
    required String displayName,
  }) async {
    _ensureAllowed(
      _access.canUpdateStaff,
      'Bạn chưa có quyền sửa tên nhân viên',
    );
    await _runMutation(() async {
      await ref.read(updateStaffDisplayNameUseCaseProvider)(
        storeId: _access.storeId,
        storeUserId: storeUserId,
        displayName: displayName,
      );
      await load();
    });
  }

  Future<void> removeStaff(int storeUserId) async {
    _ensureAllowed(_access.canRemoveStaff, 'Bạn chưa có quyền xóa nhân viên');
    await _runMutation(() async {
      await ref.read(removeStaffUseCaseProvider)(
        storeId: _access.storeId,
        storeUserId: storeUserId,
      );
      await load();
    });
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

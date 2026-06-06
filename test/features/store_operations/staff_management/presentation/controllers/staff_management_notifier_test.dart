import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quan_oi/features/store_operations/staff_management/domain/entities/permission_group.dart';
import 'package:quan_oi/features/store_operations/staff_management/domain/entities/staff_invitation.dart';
import 'package:quan_oi/features/store_operations/staff_management/domain/entities/staff_member.dart';
import 'package:quan_oi/features/store_operations/staff_management/domain/entities/staff_role.dart';
import 'package:quan_oi/features/store_operations/staff_management/domain/entities/staff_status.dart';
import 'package:quan_oi/features/store_operations/staff_management/domain/repositories/staff_management_repository.dart';
import 'package:quan_oi/features/store_operations/staff_management/domain/usecases/cancel_staff_invitation_use_case.dart';
import 'package:quan_oi/features/store_operations/staff_management/domain/usecases/create_staff_role_use_case.dart';
import 'package:quan_oi/features/store_operations/staff_management/domain/usecases/delete_staff_role_use_case.dart';
import 'package:quan_oi/features/store_operations/staff_management/domain/usecases/invite_staff_use_case.dart';
import 'package:quan_oi/features/store_operations/staff_management/domain/usecases/load_staff_members_use_case.dart';
import 'package:quan_oi/features/store_operations/staff_management/domain/usecases/load_staff_permission_groups_use_case.dart';
import 'package:quan_oi/features/store_operations/staff_management/domain/usecases/load_staff_roles_use_case.dart';
import 'package:quan_oi/features/store_operations/staff_management/domain/usecases/remove_staff_use_case.dart';
import 'package:quan_oi/features/store_operations/staff_management/domain/usecases/update_staff_access_use_case.dart';
import 'package:quan_oi/features/store_operations/staff_management/domain/usecases/update_staff_display_name_use_case.dart';
import 'package:quan_oi/features/store_operations/staff_management/domain/usecases/update_staff_role_use_case.dart';
import 'package:quan_oi/features/store_operations/staff_management/presentation/controllers/staff_management_access.dart';
import 'package:quan_oi/features/store_operations/staff_management/presentation/controllers/staff_management_state.dart';
import 'package:quan_oi/features/store_operations/staff_management/presentation/providers/staff_management_providers.dart';

void main() {
  test('loads staff and roles when user has staff view permission', () async {
    final repository = _FakeStaffManagementRepository();
    final container = _container(repository);
    addTearDown(container.dispose);

    final access = _access(canViewStaff: true);
    final subscription = container.listen(
      staffManagementNotifierProvider(access),
      (previous, next) {},
    );
    addTearDown(subscription.close);

    await _flushMicrotasks();

    final state = container.read(staffManagementNotifierProvider(access));
    expect(state.status, StaffManagementStatus.ready);
    expect(state.staff, hasLength(1));
    expect(state.roles, hasLength(1));
  });

  test(
    'remove staff is blocked before repository call without permission',
    () async {
      final repository = _FakeStaffManagementRepository();
      final container = _container(repository);
      addTearDown(container.dispose);

      final access = _access(canViewStaff: true, canRemoveStaff: false);
      container.read(staffManagementNotifierProvider(access));
      await _flushMicrotasks();

      await expectLater(
        container
            .read(staffManagementNotifierProvider(access).notifier)
            .removeStaff(12),
        throwsA(isA<Exception>()),
      );
      expect(repository.removeCalls, 0);
    },
  );
}

ProviderContainer _container(_FakeStaffManagementRepository repository) {
  return ProviderContainer(
    overrides: [
      loadStaffRolesUseCaseProvider.overrideWithValue(
        LoadStaffRolesUseCase(repository),
      ),
      loadStaffMembersUseCaseProvider.overrideWithValue(
        LoadStaffMembersUseCase(repository),
      ),
      loadStaffPermissionGroupsUseCaseProvider.overrideWithValue(
        LoadStaffPermissionGroupsUseCase(repository),
      ),
      inviteStaffUseCaseProvider.overrideWithValue(
        InviteStaffUseCase(repository),
      ),
      cancelStaffInvitationUseCaseProvider.overrideWithValue(
        CancelStaffInvitationUseCase(repository),
      ),
      updateStaffDisplayNameUseCaseProvider.overrideWithValue(
        UpdateStaffDisplayNameUseCase(repository),
      ),
      updateStaffAccessUseCaseProvider.overrideWithValue(
        UpdateStaffAccessUseCase(repository),
      ),
      removeStaffUseCaseProvider.overrideWithValue(
        RemoveStaffUseCase(repository),
      ),
      createStaffRoleUseCaseProvider.overrideWithValue(
        CreateStaffRoleUseCase(repository),
      ),
      updateStaffRoleUseCaseProvider.overrideWithValue(
        UpdateStaffRoleUseCase(repository),
      ),
      deleteStaffRoleUseCaseProvider.overrideWithValue(
        DeleteStaffRoleUseCase(repository),
      ),
    ],
  );
}

StaffManagementAccess _access({
  bool canViewStaff = false,
  bool canInviteStaff = false,
  bool canUpdateStaff = false,
  bool canRemoveStaff = false,
  bool canManageRoles = false,
}) {
  return StaffManagementAccess(
    storeId: 1,
    canViewStaff: canViewStaff,
    canInviteStaff: canInviteStaff,
    canUpdateStaff: canUpdateStaff,
    canRemoveStaff: canRemoveStaff,
    canManageRoles: canManageRoles,
  );
}

Future<void> _flushMicrotasks() async {
  await Future<void>.delayed(Duration.zero);
  await Future<void>.delayed(Duration.zero);
}

class _FakeStaffManagementRepository implements StaffManagementRepository {
  int removeCalls = 0;

  @override
  Future<List<StaffRole>> loadRoles(int storeId) async {
    return const [
      StaffRole(id: 3, storeId: 1, name: 'Thu ngân', isSystemRole: false),
    ];
  }

  @override
  Future<List<StaffMember>> loadStaff(int storeId) async {
    return const [
      StaffMember(
        status: StaffStatus.active,
        storeUserId: 12,
        invitationId: null,
        accountId: 8,
        invitedAccountId: null,
        displayName: 'Bạn Thu ngân',
        accountFullName: 'Nguyen Van A',
        email: 'staff@example.com',
        phone: '090',
        role: StaffRole(
          id: 3,
          storeId: 1,
          name: 'Thu ngân',
          isSystemRole: false,
        ),
        permissions: [],
        joinedAt: null,
        createdAt: null,
        expiresAt: null,
        isOwner: false,
      ),
    ];
  }

  @override
  Future<List<PermissionGroup>> loadPermissionGroups(int storeId) async {
    return const [];
  }

  @override
  Future<StaffInvitation> inviteStaff({
    required int storeId,
    required String invitedEmail,
    required String displayName,
    required int roleId,
    required List<int> permissionIds,
  }) async {
    return StaffInvitation(
      invitationId: 20,
      storeId: storeId,
      invitedEmail: invitedEmail,
      displayName: displayName,
      invitedAccountId: null,
      roleId: roleId,
      invitedByAccountId: 1,
      status: 1,
      createdAt: null,
      expiresAt: null,
      respondedAt: null,
      permissionIds: permissionIds,
      notificationId: null,
    );
  }

  @override
  Future<void> cancelInvitation({
    required int storeId,
    required int invitationId,
  }) async {}

  @override
  Future<void> updateStaffDisplayName({
    required int storeId,
    required int storeUserId,
    required String displayName,
  }) async {}

  @override
  Future<void> updateStaffAccess({
    required int storeId,
    required int storeUserId,
    required int roleId,
    required List<int> permissionIds,
  }) async {}

  @override
  Future<void> removeStaff({
    required int storeId,
    required int storeUserId,
  }) async {
    removeCalls += 1;
  }

  @override
  Future<StaffRole> createRole({
    required int storeId,
    required String name,
    required List<int> permissionIds,
  }) async {
    return StaffRole(id: 4, storeId: storeId, name: name, isSystemRole: false);
  }

  @override
  Future<StaffRole> updateRole({
    required int storeId,
    required int roleId,
    required String name,
    required List<int> permissionIds,
  }) async {
    return StaffRole(
      id: roleId,
      storeId: storeId,
      name: name,
      isSystemRole: false,
    );
  }

  @override
  Future<void> deleteRole({required int storeId, required int roleId}) async {}
}

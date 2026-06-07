import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quan_oi/config/router_config.dart';
import 'package:quan_oi/core/constants/app_permission_codes.dart';
import 'package:quan_oi/core/storage/last_active_store_storage.dart';
import 'package:quan_oi/core/theme/index.dart';
import 'package:quan_oi/features/auth/domain/entities/account_type.dart';
import 'package:quan_oi/features/auth/presentation/controllers/auth_notifier.dart';
import 'package:quan_oi/features/auth/presentation/controllers/auth_state.dart';
import 'package:quan_oi/features/auth/presentation/providers/auth_providers.dart';
import 'package:quan_oi/features/store_operations/staff_management/domain/entities/permission_group.dart';
import 'package:quan_oi/features/store_operations/staff_management/domain/entities/staff_invitation.dart';
import 'package:quan_oi/features/store_operations/staff_management/domain/entities/staff_member.dart';
import 'package:quan_oi/features/store_operations/staff_management/domain/entities/staff_permission.dart';
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
import 'package:quan_oi/features/store_operations/staff_management/presentation/widgets/permission_group_list.dart';
import 'package:quan_oi/features/workspace_context/domain/entities/store.dart';
import 'package:quan_oi/features/workspace_context/domain/entities/store_access_context.dart';
import 'package:quan_oi/features/workspace_context/domain/entities/store_permission.dart';
import 'package:quan_oi/features/workspace_context/domain/repositories/workspace_repository.dart';
import 'package:quan_oi/features/workspace_context/domain/usecases/clear_last_active_store_use_case.dart';
import 'package:quan_oi/features/workspace_context/domain/usecases/create_store_use_case.dart';
import 'package:quan_oi/features/workspace_context/domain/usecases/load_last_active_store_use_case.dart';
import 'package:quan_oi/features/workspace_context/domain/usecases/load_my_stores_use_case.dart';
import 'package:quan_oi/features/workspace_context/domain/usecases/load_store_access_context_use_case.dart';
import 'package:quan_oi/features/workspace_context/domain/usecases/save_last_active_store_use_case.dart';
import 'package:quan_oi/features/workspace_context/presentation/providers/workspace_context_providers.dart';
import 'package:quan_oi/features/store_operations/staff_management/presentation/providers/staff_management_providers.dart';

void main() {
  testWidgets('staff management back button returns to store overview', (
    tester,
  ) async {
    final container = _buildContainer(_FakeStaffManagementRepository());
    addTearDown(container.dispose);
    final router = container.read(routerProvider);
    await _pumpRouter(tester, container);

    router.go('/stores/5/staff');
    await tester.pumpAndSettle();

    expect(find.text('Quản lý nhân viên'), findsOneWidget);

    await tester.tap(find.byIcon(Icons.arrow_back_rounded));
    await tester.pumpAndSettle();

    expect(find.text('Tổng quan hôm nay'), findsOneWidget);
  });

  testWidgets('successful invite refreshes staff list on return', (
    tester,
  ) async {
    final repository = _FakeStaffManagementRepository();
    final container = _buildContainer(repository);
    addTearDown(container.dispose);
    final router = container.read(routerProvider);
    await _pumpRouter(tester, container);

    router.go('/stores/5/staff');
    await tester.pumpAndSettle();
    expect(find.text('Bạn Thu ngân'), findsOneWidget);

    await tester.tap(find.text('Thêm nhân viên'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextFormField).at(0), 'Bạn mới');
    await tester.enterText(find.byType(TextFormField).at(1), 'new@example.com');
    await tester.tap(find.text('Chọn 1 vai trò cho nhân viên'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Thu ngân').last);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Tạo và gửi lời mời'));
    await tester.pumpAndSettle();

    expect(repository.inviteCalls, 1);
    expect(find.text('Bạn mới'), findsOneWidget);
  });

  testWidgets('successful role creation refreshes role tab on return', (
    tester,
  ) async {
    final repository = _FakeStaffManagementRepository();
    final container = _buildContainer(repository);
    addTearDown(container.dispose);
    final router = container.read(routerProvider);
    await _pumpRouter(tester, container);

    router.go('/stores/5/staff');
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('staff_management_tab_staff')), findsOneWidget);
    expect(find.byKey(const Key('staff_management_tab_roles')), findsOneWidget);
    await tester.tap(find.textContaining('Vai trò'));
    await tester.pumpAndSettle();
    expect(find.text('Ca tối'), findsNothing);

    await tester.tap(find.text('Thêm vai trò'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextFormField), 'Ca tối');
    await tester.tap(find.text('Tạo vai trò'));
    await tester.pumpAndSettle();

    expect(repository.createRoleCalls, 1);
    expect(find.text('Ca tối'), findsOneWidget);
  });

  testWidgets('staff tile opens detail without inline action menu', (
    tester,
  ) async {
    final repository = _FakeStaffManagementRepository();
    final container = _buildContainer(repository);
    addTearDown(container.dispose);
    final router = container.read(routerProvider);
    await _pumpRouter(tester, container);

    router.go('/stores/5/staff');
    await tester.pumpAndSettle();

    expect(find.byType(PopupMenuButton), findsNothing);

    await tester.tap(find.text('Bạn Thu ngân'));
    await tester.pumpAndSettle();

    expect(find.text('Chi tiết nhân viên'), findsOneWidget);
    expect(find.text('Thông tin'), findsOneWidget);
  });

  testWidgets('active staff detail single update saves info and access', (
    tester,
  ) async {
    final repository = _FakeStaffManagementRepository();
    final container = _buildContainer(repository);
    addTearDown(container.dispose);
    final router = container.read(routerProvider);
    await _pumpRouter(tester, container);

    router.go('/stores/5/staff/users/12');
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField), 'Bạn Thu ngân ca sáng');
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.byKey(const Key('staff_update_button')));
    await tester.pumpAndSettle();
    expect(find.text('Lưu tên hiển thị'), findsNothing);
    expect(find.text('Lưu vai trò và quyền'), findsNothing);
    expect(find.byKey(const Key('staff_delete_button')), findsOneWidget);

    await tester.tap(find.byKey(const Key('staff_update_button')));
    await tester.pumpAndSettle();

    expect(repository.updateDisplayNameCalls, 1);
    expect(repository.lastDisplayName, 'Bạn Thu ngân ca sáng');
    expect(repository.updateAccessCalls, 1);
    expect(repository.lastRoleId, 3);
    expect(repository.lastPermissionIds, contains(11));
  });

  testWidgets(
    'staff detail hides update button without staff update permission',
    (tester) async {
      final repository = _FakeStaffManagementRepository();
      final container = _buildContainer(repository, canUpdateStaff: false);
      addTearDown(container.dispose);
      final router = container.read(routerProvider);
      await _pumpRouter(tester, container);

      router.go('/stores/5/staff/users/12');
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('staff_update_button')), findsNothing);
    },
  );

  testWidgets('staff detail hides update button for owner', (tester) async {
    final repository = _FakeStaffManagementRepository()..isOwner = true;
    final container = _buildContainer(repository);
    addTearDown(container.dispose);
    final router = container.read(routerProvider);
    await _pumpRouter(tester, container);

    router.go('/stores/5/staff/users/12');
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('staff_update_button')), findsNothing);
  });

  testWidgets('pending detail is read-only and can cancel invitation', (
    tester,
  ) async {
    final repository = _FakeStaffManagementRepository()..hasInvitedStaff = true;
    final container = _buildContainer(repository);
    addTearDown(container.dispose);
    final router = container.read(routerProvider);
    await _pumpRouter(tester, container);

    router.go('/stores/5/staff/invitations/20');
    await tester.pumpAndSettle();

    expect(find.text('Chi tiết lời mời'), findsOneWidget);
    expect(find.byKey(const Key('staff_update_button')), findsNothing);
    expect(
      find.byKey(const Key('staff_cancel_invitation_button')),
      findsOneWidget,
    );

    await tester.tap(find.byKey(const Key('staff_cancel_invitation_button')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Đồng ý'));
    await tester.pumpAndSettle();

    expect(repository.cancelInvitationCalls, 1);
  });

  testWidgets('creating role from invite selector reloads invite roles', (
    tester,
  ) async {
    final repository = _FakeStaffManagementRepository();
    final container = _buildContainer(repository);
    addTearDown(container.dispose);
    final router = container.read(routerProvider);
    await _pumpRouter(tester, container);

    router.go('/stores/5/staff/invite');
    await tester.pumpAndSettle();

    await tester.tap(find.text('Chọn 1 vai trò cho nhân viên'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Thêm vai trò'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextFormField), 'Barista');
    await tester.tap(find.text('Tạo vai trò'));
    await tester.pumpAndSettle();

    expect(repository.createRoleCalls, 1);
    expect(find.text('Thêm nhân viên'), findsOneWidget);

    await tester.tap(find.text('Chọn 1 vai trò cho nhân viên'));
    await tester.pumpAndSettle();

    expect(find.text('Barista'), findsOneWidget);
  });

  testWidgets('permission list shows names without raw permission codes', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: Scaffold(
          body: PermissionGroupList(
            groups: const [
              PermissionGroup(
                groupId: 1,
                groupName: 'Nhân viên',
                description: '',
                permissions: [
                  StaffPermission(
                    id: 11,
                    code: 'STAFF.VIEW',
                    name: 'Xem nhân viên',
                    groupId: 1,
                    groupName: 'Nhân viên',
                  ),
                ],
              ),
            ],
            selectedPermissionIds: const {11},
            isReadOnly: false,
            onTogglePermission: (_) {},
            onSetGroupPermissions: (_, _) {},
          ),
        ),
      ),
    );

    expect(find.text('Xem nhân viên'), findsOneWidget);
    expect(find.text('STAFF.VIEW'), findsNothing);
  });
}

Future<void> _pumpRouter(
  WidgetTester tester,
  ProviderContainer container,
) async {
  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: MaterialApp.router(
        theme: AppTheme.light,
        routerConfig: container.read(routerProvider),
      ),
    ),
  );
}

ProviderContainer _buildContainer(
  _FakeStaffManagementRepository repository, {
  bool canUpdateStaff = true,
}) {
  final workspaceRepository = _FakeWorkspaceRepository(
    canUpdateStaff: canUpdateStaff,
  );
  final lastActiveStoreStorage = _FakeLastActiveStoreStorage();

  return ProviderContainer(
    overrides: [
      authNotifierProvider.overrideWith(
        () => _FixedAuthNotifier(
          const AuthState(
            status: AuthStatus.authenticated,
            accountType: AccountType.storeUser,
            fullName: 'Test User',
            email: 'user@quanoi.test',
          ),
        ),
      ),
      loadMyStoresUseCaseProvider.overrideWithValue(
        LoadMyStoresUseCase(workspaceRepository),
      ),
      createStoreUseCaseProvider.overrideWithValue(
        CreateStoreUseCase(workspaceRepository),
      ),
      loadStoreAccessContextUseCaseProvider.overrideWithValue(
        LoadStoreAccessContextUseCase(workspaceRepository),
      ),
      loadLastActiveStoreUseCaseProvider.overrideWithValue(
        LoadLastActiveStoreUseCase(lastActiveStoreStorage),
      ),
      saveLastActiveStoreUseCaseProvider.overrideWithValue(
        SaveLastActiveStoreUseCase(lastActiveStoreStorage),
      ),
      clearLastActiveStoreUseCaseProvider.overrideWithValue(
        ClearLastActiveStoreUseCase(lastActiveStoreStorage),
      ),
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

class _FixedAuthNotifier extends AuthNotifier {
  final AuthState fixedState;

  _FixedAuthNotifier(this.fixedState);

  @override
  AuthState build() {
    return fixedState;
  }
}

class _FakeWorkspaceRepository implements WorkspaceRepository {
  final bool canUpdateStaff;

  const _FakeWorkspaceRepository({required this.canUpdateStaff});

  @override
  Future<List<Store>> loadMyStores() async => _stores;

  @override
  Future<Store> createStore({
    required String storeName,
    required String phone,
    required String address,
  }) async {
    return _stores.first;
  }

  @override
  Future<Store> loadStoreById(int storeId) async {
    return _stores.firstWhere((store) => store.id == storeId);
  }

  @override
  Future<List<StorePermission>> loadMyStorePermissions(int storeId) async {
    return [
      const StorePermission(
        permissionId: 1,
        code: AppPermissionCodes.dashboardView,
      ),
      const StorePermission(
        permissionId: 2,
        code: AppPermissionCodes.staffView,
      ),
      const StorePermission(
        permissionId: 3,
        code: AppPermissionCodes.staffInvite,
      ),
      const StorePermission(
        permissionId: 4,
        code: AppPermissionCodes.roleManage,
      ),
      if (canUpdateStaff)
        const StorePermission(
          permissionId: 5,
          code: AppPermissionCodes.staffUpdate,
        ),
      const StorePermission(
        permissionId: 6,
        code: AppPermissionCodes.staffRemove,
      ),
    ];
  }

  @override
  Future<StoreAccessContext> loadStoreAccessContext(int storeId) async {
    return StoreAccessContext(
      store: await loadStoreById(storeId),
      permissions: await loadMyStorePermissions(storeId),
    );
  }

  @override
  Future<StoreAccessContext?> loadCachedStoreAccessContext({
    required int accountId,
    required int storeId,
  }) async {
    return null;
  }

  @override
  Future<void> saveStoreAccessContextCache({
    required int accountId,
    required StoreAccessContext context,
  }) async {}

  @override
  Future<void> clearStoreAccessContextCache({
    required int accountId,
    required int storeId,
  }) async {}

  @override
  Future<void> clearAllStoreAccessContextCache() async {}
}

class _FakeStaffManagementRepository implements StaffManagementRepository {
  final List<StaffRole> _roles = [
    const StaffRole(
      id: 3,
      storeId: 5,
      name: 'Thu ngân',
      isSystemRole: false,
      permissions: [
        StaffPermission(
          id: 11,
          code: AppPermissionCodes.staffView,
          name: 'Xem nhân viên',
          groupId: 1,
          groupName: 'Nhân viên',
        ),
      ],
    ),
  ];
  bool hasInvitedStaff = false;
  bool isOwner = false;
  int inviteCalls = 0;
  int createRoleCalls = 0;
  int cancelInvitationCalls = 0;
  int updateDisplayNameCalls = 0;
  int updateAccessCalls = 0;
  String? lastDisplayName;
  int? lastRoleId;
  List<int> lastPermissionIds = const [];

  @override
  Future<List<StaffRole>> loadRoles(int storeId) async {
    return List<StaffRole>.unmodifiable(_roles);
  }

  @override
  Future<List<StaffMember>> loadStaff(int storeId) async {
    return [
      _staffMember('Bạn Thu ngân', StaffStatus.active),
      if (hasInvitedStaff) _staffMember('Bạn mới', StaffStatus.pending),
    ];
  }

  @override
  Future<List<PermissionGroup>> loadPermissionGroups(int storeId) async {
    return const [
      PermissionGroup(
        groupId: 1,
        groupName: 'Nhân viên',
        description: '',
        permissions: [
          StaffPermission(
            id: 11,
            code: AppPermissionCodes.staffView,
            name: 'Xem nhân viên',
            groupId: 1,
            groupName: 'Nhân viên',
          ),
        ],
      ),
    ];
  }

  @override
  Future<StaffInvitation> inviteStaff({
    required int storeId,
    required String invitedEmail,
    required String displayName,
    required int roleId,
    required List<int> permissionIds,
  }) async {
    inviteCalls += 1;
    hasInvitedStaff = true;
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
  }) async {
    cancelInvitationCalls += 1;
  }

  @override
  Future<void> updateStaffDisplayName({
    required int storeId,
    required int storeUserId,
    required String displayName,
  }) async {
    updateDisplayNameCalls += 1;
    lastDisplayName = displayName;
  }

  @override
  Future<void> updateStaffAccess({
    required int storeId,
    required int storeUserId,
    required int roleId,
    required List<int> permissionIds,
  }) async {
    updateAccessCalls += 1;
    lastRoleId = roleId;
    lastPermissionIds = permissionIds;
  }

  @override
  Future<void> removeStaff({
    required int storeId,
    required int storeUserId,
  }) async {}

  @override
  Future<StaffRole> createRole({
    required int storeId,
    required String name,
    required List<int> permissionIds,
  }) async {
    createRoleCalls += 1;
    final role = StaffRole(
      id: 10 + createRoleCalls,
      storeId: storeId,
      name: name,
      isSystemRole: false,
    );
    _roles.add(role);
    return role;
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

  StaffMember _staffMember(String name, StaffStatus status) {
    return StaffMember(
      status: status,
      storeUserId: status.isActive ? 12 : null,
      invitationId: status.isPending ? 20 : null,
      accountId: status.isActive ? 8 : null,
      invitedAccountId: null,
      displayName: name,
      accountFullName: name,
      email: '${name.hashCode}@example.com',
      phone: '090',
      role: _roles.first,
      permissions: const [],
      joinedAt: null,
      createdAt: null,
      expiresAt: null,
      isOwner: isOwner,
    );
  }
}

class _FakeLastActiveStoreStorage implements LastActiveStoreStorage {
  int? lastStoreId;

  @override
  Future<int?> getLastActiveStoreId() async => lastStoreId;

  @override
  Future<void> saveLastActiveStoreId(int storeId) async {
    lastStoreId = storeId;
  }

  @override
  Future<void> clearLastActiveStoreId() async {
    lastStoreId = null;
  }
}

const _stores = [
  Store(
    id: 5,
    ownerAccountId: 8,
    storeName: 'FPT Shipper Vip',
    phone: '0123456789',
    address: 'Gần Đại Học FPT',
    status: StoreStatus.active,
    isDeleted: false,
  ),
];

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../../config/router_config.dart';
import '../../../../../core/constants/app_constants.dart';
import '../../../../../core/constants/app_permission_codes.dart';
import '../../../../../core/theme/index.dart';
import '../../../../workspace_context/presentation/controllers/store_access_state.dart';
import '../../../../workspace_context/presentation/providers/workspace_context_providers.dart';
import '../../domain/entities/staff_member.dart';
import '../../domain/entities/staff_role.dart';
import '../../domain/entities/staff_status.dart';
import '../controllers/staff_management_access.dart';
import '../controllers/staff_management_state.dart';
import '../providers/staff_management_providers.dart';

class StaffManagementPage extends ConsumerWidget {
  final int storeId;

  const StaffManagementPage({super.key, required this.storeId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final accessState = ref.watch(storeAccessNotifierProvider(storeId));

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          tooltip: 'Quay lại',
          onPressed: () => context.goNamed(
            RouteNames.storeOverview,
            pathParameters: {'storeId': storeId.toString()},
          ),
          icon: const Icon(Icons.arrow_back_rounded),
        ),
        title: const Text('Quản lý nhân viên'),
      ),
      body: switch (accessState.status) {
        StoreAccessStatus.initial || StoreAccessStatus.loading => const Center(
          child: CircularProgressIndicator(),
        ),
        StoreAccessStatus.forbidden => _BlockedView(
          message:
              accessState.errorMessage ??
              'Bạn không có quyền truy cập cửa hàng này.',
        ),
        StoreAccessStatus.error => _ErrorView(
          message: accessState.errorMessage ?? 'Không thể tải quyền cửa hàng',
          onRetry: () => ref
              .read(storeAccessNotifierProvider(storeId).notifier)
              .loadAccess(),
        ),
        StoreAccessStatus.ready => _StaffManagementReadyView(
          access: _accessFromState(storeId, accessState),
        ),
      },
    );
  }
}

class _StaffManagementReadyView extends ConsumerStatefulWidget {
  final StaffManagementAccess access;

  const _StaffManagementReadyView({required this.access});

  @override
  ConsumerState<_StaffManagementReadyView> createState() =>
      _StaffManagementReadyViewState();
}

class _StaffManagementReadyViewState
    extends ConsumerState<_StaffManagementReadyView> {
  _StaffManagementTab _selectedTab = _StaffManagementTab.staff;

  @override
  Widget build(BuildContext context) {
    final access = widget.access;
    if (!access.canOpenStaffModule) {
      return const _BlockedView(
        message: 'Bạn chưa có quyền quản lý nhân viên.',
      );
    }

    final state = ref.watch(staffManagementNotifierProvider(access));
    final notifier = ref.read(staffManagementNotifierProvider(access).notifier);
    final isRoleTab = _selectedTab == _StaffManagementTab.roles;
    final canUseFab = isRoleTab ? access.canManageRoles : access.canInviteStaff;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          _StaffManagementTabs(
            selectedTab: _selectedTab,
            staffCount: state.staff.length,
            roleCount: state.roles.length,
            onSelected: (tab) {
              if (_selectedTab == tab) {
                return;
              }
              setState(() => _selectedTab = tab);
            },
          ),
          Expanded(
            child: switch (state.status) {
              StaffManagementStatus.initial || StaffManagementStatus.loading =>
                const Center(child: CircularProgressIndicator()),
              StaffManagementStatus.forbidden => _BlockedView(
                message:
                    state.errorMessage ??
                    'Bạn chưa có quyền quản lý nhân viên.',
              ),
              StaffManagementStatus.error => _ErrorView(
                message: state.errorMessage ?? 'Không thể tải dữ liệu',
                onRetry: notifier.load,
              ),
              StaffManagementStatus.ready => switch (_selectedTab) {
                _StaffManagementTab.staff => _StaffListView(
                  access: access,
                  staff: state.staff,
                ),
                _StaffManagementTab.roles => _RoleListView(
                  access: access,
                  roles: state.roles,
                ),
              },
            },
          ),
        ],
      ),
      floatingActionButton: canUseFab
          ? FloatingActionButton.extended(
              key: Key(
                isRoleTab ? 'add_staff_role_button' : 'add_staff_button',
              ),
              onPressed: () async {
                Object? result;
                if (isRoleTab) {
                  result = await context.pushNamed(
                    RouteNames.storeStaffRoleCreate,
                    pathParameters: {'storeId': access.storeId.toString()},
                  );
                } else {
                  result = await context.pushNamed(
                    RouteNames.storeStaffInvite,
                    pathParameters: {'storeId': access.storeId.toString()},
                  );
                }

                if (result == true && mounted) {
                  await ref
                      .read(staffManagementNotifierProvider(access).notifier)
                      .load();
                }
              },
              icon: const Icon(Icons.add_rounded),
              label: Text(isRoleTab ? 'Thêm vai trò' : 'Thêm nhân viên'),
            )
          : null,
    );
  }
}

enum _StaffManagementTab { staff, roles }

extension _StaffManagementTabLabel on _StaffManagementTab {
  String label(int count) {
    return switch (this) {
      _StaffManagementTab.staff => 'Nhân viên ($count)',
      _StaffManagementTab.roles => 'Vai trò ($count)',
    };
  }
}

class _StaffManagementTabs extends StatelessWidget {
  final _StaffManagementTab selectedTab;
  final int staffCount;
  final int roleCount;
  final ValueChanged<_StaffManagementTab> onSelected;

  const _StaffManagementTabs({
    required this.selectedTab,
    required this.staffCount,
    required this.roleCount,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.surface,
      child: Row(
        children: [
          for (final tab in _StaffManagementTab.values)
            Expanded(
              child: InkWell(
                key: Key('staff_management_tab_${tab.name}'),
                onTap: () => onSelected(tab),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    vertical: AppConstants.spacingSm,
                  ),
                  decoration: BoxDecoration(
                    border: Border(
                      bottom: BorderSide(
                        color: selectedTab == tab
                            ? AppColors.primary
                            : AppColors.border,
                        width: selectedTab == tab ? 2.5 : 1,
                      ),
                    ),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    tab.label(
                      tab == _StaffManagementTab.staff ? staffCount : roleCount,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.labelSm.copyWith(
                      color: selectedTab == tab
                          ? AppColors.primary
                          : AppColors.textMuted,
                      fontWeight: selectedTab == tab
                          ? FontWeight.w700
                          : FontWeight.w500,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _StaffListView extends ConsumerWidget {
  final StaffManagementAccess access;
  final List<StaffMember> staff;

  const _StaffListView({required this.access, required this.staff});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (!access.canViewStaff) {
      return const _BlockedView(
        message: 'Bạn chưa có quyền xem danh sách nhân viên.',
      );
    }

    if (staff.isEmpty) {
      return const _EmptyView(
        icon: Icons.group_outlined,
        message: 'Chưa có nhân viên hoặc lời mời nào.',
      );
    }

    return RefreshIndicator(
      onRefresh: () =>
          ref.read(staffManagementNotifierProvider(access).notifier).load(),
      child: ListView.separated(
        padding: const EdgeInsets.fromLTRB(
          AppConstants.spacingMd,
          AppConstants.spacingMd,
          AppConstants.spacingMd,
          AppConstants.spacingXxl,
        ),
        itemBuilder: (context, index) {
          final member = staff[index];
          return _StaffListTile(access: access, member: member);
        },
        separatorBuilder: (context, index) =>
            const SizedBox(height: AppConstants.spacingSm),
        itemCount: staff.length,
      ),
    );
  }
}

class _StaffListTile extends ConsumerWidget {
  final StaffManagementAccess access;
  final StaffMember member;

  const _StaffListTile({required this.access, required this.member});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isPending = member.status.isPending;

    return Card(
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: AppColors.primaryLight,
          foregroundColor: AppColors.primary,
          child: Text(_initials(member.primaryName)),
        ),
        title: Text(member.primaryName),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (member.contactText.isNotEmpty) Text(member.contactText),
            const SizedBox(height: AppConstants.spacingXs),
            Wrap(
              spacing: AppConstants.spacingXs,
              runSpacing: AppConstants.spacingXs,
              children: [
                _ChipLabel(
                  text: member.isOwner
                      ? 'Chủ sở hữu'
                      : (member.role?.name ?? 'Chưa có vai trò'),
                ),
                if (isPending) const _ChipLabel(text: 'Đang chờ'),
              ],
            ),
          ],
        ),
        trailing: const Icon(Icons.chevron_right_rounded),
        onTap: () async {
          final result = await _openStaffDetail(context, access, member);
          if (result == true && context.mounted) {
            await ref
                .read(staffManagementNotifierProvider(access).notifier)
                .load();
          }
        },
      ),
    );
  }
}

class _RoleListView extends ConsumerWidget {
  final StaffManagementAccess access;
  final List<StaffRole> roles;

  const _RoleListView({required this.access, required this.roles});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (roles.isEmpty) {
      return const _EmptyView(
        icon: Icons.admin_panel_settings_outlined,
        message: 'Chưa có vai trò nào.',
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(
        AppConstants.spacingMd,
        AppConstants.spacingMd,
        AppConstants.spacingMd,
        AppConstants.spacingXxl,
      ),
      itemBuilder: (context, index) {
        final role = roles[index];
        return Card(
          child: ListTile(
            leading: Icon(
              role.isSystemRole
                  ? Icons.verified_user_outlined
                  : Icons.badge_outlined,
              color: AppColors.primary,
            ),
            title: Text(role.name),
            subtitle: Text(
              role.isSystemRole
                  ? 'Vai trò hệ thống'
                  : '${role.permissions.length} quyền',
            ),
            trailing: const Icon(Icons.chevron_right_rounded),
            onTap: () async {
              final result = await context.pushNamed(
                RouteNames.storeStaffRoleDetail,
                pathParameters: {
                  'storeId': access.storeId.toString(),
                  'roleId': role.id.toString(),
                },
              );

              if (result == true && context.mounted) {
                await ref
                    .read(staffManagementNotifierProvider(access).notifier)
                    .load();
              }
            },
          ),
        );
      },
      separatorBuilder: (context, index) =>
          const SizedBox(height: AppConstants.spacingSm),
      itemCount: roles.length,
    );
  }
}

class _ChipLabel extends StatelessWidget {
  final String text;

  const _ChipLabel({required this.text});

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.muted,
        borderRadius: BorderRadius.circular(AppTheme.radiusSm),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppConstants.spacingSm,
          vertical: AppConstants.spacingXs,
        ),
        child: Text(text, style: AppTextStyles.caption),
      ),
    );
  }
}

class _EmptyView extends StatelessWidget {
  final IconData icon;
  final String message;

  const _EmptyView({required this.icon, required this.message});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppConstants.spacingLg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: AppColors.textMuted, size: 44),
            const SizedBox(height: AppConstants.spacingMd),
            Text(
              message,
              style: AppTextStyles.bodySm,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _BlockedView extends StatelessWidget {
  final String message;

  const _BlockedView({required this.message});

  @override
  Widget build(BuildContext context) {
    return _EmptyView(icon: Icons.lock_outline_rounded, message: message);
  }
}

class _ErrorView extends StatelessWidget {
  final String message;
  final Future<void> Function() onRetry;

  const _ErrorView({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppConstants.spacingLg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.error_outline_rounded,
              color: AppColors.error,
              size: 44,
            ),
            const SizedBox(height: AppConstants.spacingMd),
            Text(message, textAlign: TextAlign.center),
            const SizedBox(height: AppConstants.spacingLg),
            ElevatedButton(onPressed: onRetry, child: const Text('Thử lại')),
          ],
        ),
      ),
    );
  }
}

StaffManagementAccess _accessFromState(int storeId, StoreAccessState state) {
  return StaffManagementAccess(
    storeId: storeId,
    canViewStaff: state.can(AppPermissionCodes.staffView),
    canInviteStaff: state.can(AppPermissionCodes.staffInvite),
    canUpdateStaff: state.can(AppPermissionCodes.staffUpdate),
    canRemoveStaff: state.can(AppPermissionCodes.staffRemove),
    canManageRoles: state.can(AppPermissionCodes.roleManage),
  );
}

String _initials(String name) {
  final parts = name
      .trim()
      .split(RegExp(r'\s+'))
      .where((part) => part.isNotEmpty)
      .toList();
  if (parts.isEmpty) {
    return '?';
  }

  if (parts.length == 1) {
    return parts.first.characters.first.toUpperCase();
  }

  return '${parts.first.characters.first}${parts.last.characters.first}'
      .toUpperCase();
}

Future<Object?> _openStaffDetail(
  BuildContext context,
  StaffManagementAccess access,
  StaffMember member,
) {
  final storeId = access.storeId.toString();
  final storeUserId = member.storeUserId;
  if (storeUserId != null) {
    return context.pushNamed(
      RouteNames.storeStaffUserDetail,
      pathParameters: {
        'storeId': storeId,
        'storeUserId': storeUserId.toString(),
      },
    );
  }

  final invitationId = member.invitationId;
  if (invitationId != null) {
    return context.pushNamed(
      RouteNames.storeStaffInvitationDetail,
      pathParameters: {
        'storeId': storeId,
        'invitationId': invitationId.toString(),
      },
    );
  }

  return Future<Object?>.value();
}

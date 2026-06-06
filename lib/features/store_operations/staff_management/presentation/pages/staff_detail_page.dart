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
import '../../domain/entities/staff_status.dart';
import '../controllers/staff_detail_notifier.dart';
import '../controllers/staff_detail_state.dart';
import '../controllers/staff_management_access.dart';
import '../providers/staff_management_providers.dart';
import '../widgets/permission_group_list.dart';
import '../widgets/staff_role_selector_bottom_sheet.dart';

class StaffDetailPage extends ConsumerStatefulWidget {
  final int storeId;
  final int? storeUserId;
  final int? invitationId;

  const StaffDetailPage({
    super.key,
    required this.storeId,
    this.storeUserId,
    this.invitationId,
  });

  @override
  ConsumerState<StaffDetailPage> createState() => _StaffDetailPageState();
}

class _StaffDetailPageState extends ConsumerState<StaffDetailPage> {
  final _displayNameController = TextEditingController();
  int? _loadedMemberKey;
  bool _didMutate = false;

  @override
  void dispose() {
    _displayNameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final accessState = ref.watch(storeAccessNotifierProvider(widget.storeId));

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          tooltip: 'Quay lại',
          onPressed: () => _closeDetail(_didMutate),
          icon: const Icon(Icons.arrow_back_rounded),
        ),
        title: Text(
          widget.invitationId == null
              ? 'Chi tiết nhân viên'
              : 'Chi tiết lời mời',
        ),
      ),
      body: switch (accessState.status) {
        StoreAccessStatus.initial || StoreAccessStatus.loading => const Center(
          child: CircularProgressIndicator(),
        ),
        StoreAccessStatus.forbidden || StoreAccessStatus.error => _MessageView(
          message:
              accessState.errorMessage ??
              'Không thể tải quyền cửa hàng để xem nhân viên.',
        ),
        StoreAccessStatus.ready => _buildReady(
          context,
          _accessFromState(widget.storeId, accessState),
        ),
      },
    );
  }

  Widget _buildReady(BuildContext context, StaffManagementAccess access) {
    final args = StaffDetailArgs(
      access: access,
      storeUserId: widget.storeUserId,
      invitationId: widget.invitationId,
    );
    final state = ref.watch(staffDetailNotifierProvider(args));
    final notifier = ref.read(staffDetailNotifierProvider(args).notifier);

    return switch (state.status) {
      StaffDetailStatus.initial || StaffDetailStatus.loading => const Center(
        child: CircularProgressIndicator(),
      ),
      StaffDetailStatus.forbidden => _MessageView(
        message: state.errorMessage ?? 'Bạn chưa có quyền quản lý nhân viên.',
      ),
      StaffDetailStatus.error => _ErrorView(
        message: state.errorMessage ?? 'Không thể tải chi tiết nhân viên',
        onRetry: notifier.load,
      ),
      StaffDetailStatus.ready => _StaffDetailContent(
        access: access,
        state: state,
        notifier: notifier,
        displayNameController: _displayNameController,
        onLoadedMember: _syncDisplayName,
        onMutated: () => _didMutate = true,
        onDone: () => _closeDetail(true),
      ),
    };
  }

  void _syncDisplayName(StaffMember member) {
    final memberKey = member.storeUserId ?? -(member.invitationId ?? 0);
    if (_loadedMemberKey == memberKey) {
      return;
    }

    _loadedMemberKey = memberKey;
    _displayNameController.text = member.displayName.trim().isEmpty
        ? member.primaryName
        : member.displayName;
  }

  void _closeDetail(bool didMutate) {
    final navigator = Navigator.of(context);
    if (navigator.canPop()) {
      navigator.pop(didMutate);
      return;
    }

    context.goNamed(
      RouteNames.storeStaffManagement,
      pathParameters: {'storeId': widget.storeId.toString()},
    );
  }
}

class _StaffDetailContent extends StatelessWidget {
  final StaffManagementAccess access;
  final StaffDetailState state;
  final StaffDetailNotifier notifier;
  final TextEditingController displayNameController;
  final void Function(StaffMember member) onLoadedMember;
  final VoidCallback onMutated;
  final VoidCallback onDone;

  const _StaffDetailContent({
    required this.access,
    required this.state,
    required this.notifier,
    required this.displayNameController,
    required this.onLoadedMember,
    required this.onMutated,
    required this.onDone,
  });

  @override
  Widget build(BuildContext context) {
    final member = state.member;
    if (member == null) {
      return const _MessageView(message: 'Nhân viên không tồn tại.');
    }

    onLoadedMember(member);

    final isPending = member.status.isPending;
    final canEditActive =
        member.status.isActive && !member.isOwner && access.canUpdateStaff;
    final canRemove =
        member.status.isActive && !member.isOwner && access.canRemoveStaff;
    final canCancel = isPending && access.canInviteStaff;

    return Column(
      children: [
        Expanded(
          child: ListView(
            padding: const EdgeInsets.all(AppConstants.spacingMd),
            children: [
              _ProfileCard(member: member),
              const SizedBox(height: AppConstants.spacingMd),
              _InfoSection(member: member),
              const SizedBox(height: AppConstants.spacingMd),
              if (isPending)
                _PendingSection(member: member)
              else
                _ActiveEditSection(
                  state: state,
                  notifier: notifier,
                  displayNameController: displayNameController,
                  canEdit: canEditActive,
                  onMutated: onMutated,
                ),
            ],
          ),
        ),
        if (canRemove || canCancel)
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.all(AppConstants.spacingMd),
              child: SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: state.isMutating
                      ? null
                      : () async {
                          final confirmed = await _confirm(
                            context,
                            canCancel
                                ? 'Hủy lời mời nhân viên này?'
                                : 'Xóa nhân viên khỏi cửa hàng?',
                          );
                          if (!confirmed) {
                            return;
                          }

                          try {
                            if (canCancel) {
                              await notifier.cancelInvitation();
                            } else {
                              await notifier.removeStaff();
                            }
                            if (!context.mounted) return;
                            WidgetsBinding.instance.addPostFrameCallback((_) {
                              if (context.mounted) {
                                onDone();
                              }
                            });
                          } catch (error) {
                            if (context.mounted) {
                              _showError(context, error);
                            }
                          }
                        },
                  icon: const Icon(Icons.delete_outline_rounded),
                  label: Text(canCancel ? 'Hủy lời mời' : 'Xóa nhân viên'),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _ProfileCard extends StatelessWidget {
  final StaffMember member;

  const _ProfileCard({required this.member});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppConstants.spacingMd),
        child: Row(
          children: [
            CircleAvatar(
              radius: 28,
              backgroundColor: AppColors.primaryLight,
              foregroundColor: AppColors.primary,
              child: Text(_initials(member.primaryName)),
            ),
            const SizedBox(width: AppConstants.spacingMd),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    member.primaryName,
                    style: AppTextStyles.h4.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: AppConstants.spacingXs),
                  Wrap(
                    spacing: AppConstants.spacingXs,
                    runSpacing: AppConstants.spacingXs,
                    children: [
                      _ChipLabel(text: _statusLabel(member)),
                      if (member.isOwner) const _ChipLabel(text: 'Chủ sở hữu'),
                      _ChipLabel(text: member.role?.name ?? 'Chưa có vai trò'),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoSection extends StatelessWidget {
  final StaffMember member;

  const _InfoSection({required this.member});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppConstants.spacingMd),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Thông tin',
              style: AppTextStyles.label.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: AppConstants.spacingMd),
            _InfoRow(label: 'Email', value: member.email),
            _InfoRow(label: 'Số điện thoại', value: member.phone),
            _InfoRow(label: 'Tên tài khoản', value: member.accountFullName),
            _InfoRow(label: 'Ngày tham gia', value: _dateText(member.joinedAt)),
            _InfoRow(
              label: 'Ngày tạo lời mời',
              value: _dateText(member.createdAt),
            ),
            _InfoRow(
              label: 'Hết hạn lời mời',
              value: _dateText(member.expiresAt),
            ),
          ],
        ),
      ),
    );
  }
}

class _PendingSection extends StatelessWidget {
  final StaffMember member;

  const _PendingSection({required this.member});

  @override
  Widget build(BuildContext context) {
    return Card(
      color: AppColors.primaryLight,
      child: Padding(
        padding: const EdgeInsets.all(AppConstants.spacingMd),
        child: Text(
          'Lời mời đang chờ phản hồi. Thông tin vai trò và quyền hạn chỉ có thể xem tại đây.',
          style: AppTextStyles.bodySm,
        ),
      ),
    );
  }
}

class _ActiveEditSection extends StatelessWidget {
  final StaffDetailState state;
  final StaffDetailNotifier notifier;
  final TextEditingController displayNameController;
  final bool canEdit;
  final VoidCallback onMutated;

  const _ActiveEditSection({
    required this.state,
    required this.notifier,
    required this.displayNameController,
    required this.canEdit,
    required this.onMutated,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(AppConstants.spacingMd),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Tên hiển thị',
                  style: AppTextStyles.label.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: AppConstants.spacingMd),
                TextField(
                  controller: displayNameController,
                  readOnly: !canEdit,
                  decoration: const InputDecoration(labelText: 'Tên nhân viên'),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: AppConstants.spacingMd),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(AppConstants.spacingMd),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Vai trò và quyền hạn',
                  style: AppTextStyles.label.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: AppConstants.spacingSm),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Vai trò'),
                  subtitle: Text(
                    state.selectedRole?.name ?? 'Chọn vai trò cho nhân viên',
                  ),
                  trailing: canEdit
                      ? const Icon(Icons.expand_more_rounded)
                      : null,
                  onTap: canEdit
                      ? () async {
                          final result =
                              await showModalBottomSheet<
                                StaffRoleSelectorResult
                              >(
                                context: context,
                                isScrollControlled: true,
                                useSafeArea: true,
                                backgroundColor: Colors.transparent,
                                builder: (context) => FractionallySizedBox(
                                  heightFactor: 0.78,
                                  child: StaffRoleSelectorBottomSheet(
                                    roles: state.roles,
                                    selectedRoleId: state.selectedRoleId,
                                    canManageRoles: false,
                                  ),
                                ),
                              );
                          final roleId = result?.roleId;
                          if (roleId != null) {
                            notifier.selectRole(roleId);
                          }
                        }
                      : null,
                ),
                const SizedBox(height: AppConstants.spacingMd),
                PermissionGroupList(
                  groups: state.permissionGroups,
                  selectedPermissionIds: state.selectedPermissionIds,
                  isReadOnly: !canEdit,
                  onTogglePermission: notifier.togglePermission,
                  onSetGroupPermissions: notifier.setGroupPermissions,
                ),
              ],
            ),
          ),
        ),
        if (canEdit) ...[
          const SizedBox(height: AppConstants.spacingMd),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: state.isMutating
                  ? null
                  : () async {
                      try {
                        await notifier.updateStaff(displayNameController.text);
                        onMutated();
                        if (context.mounted) {
                          _showSuccess(context, 'Đã cập nhật nhân viên');
                        }
                      } catch (error) {
                        if (context.mounted) {
                          _showError(context, error);
                        }
                      }
                    },
              child: const Text('Cập nhật nhân viên'),
            ),
          ),
        ],
      ],
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;

  const _InfoRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final cleanValue = value.trim();
    if (cleanValue.isEmpty || cleanValue == '-') {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: AppConstants.spacingSm),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(label, style: AppTextStyles.caption),
          ),
          Expanded(child: Text(cleanValue, style: AppTextStyles.bodySm)),
        ],
      ),
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

class _MessageView extends StatelessWidget {
  final String message;

  const _MessageView({required this.message});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppConstants.spacingLg),
        child: Text(
          message,
          style: AppTextStyles.bodySm,
          textAlign: TextAlign.center,
        ),
      ),
    );
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

Future<bool> _confirm(BuildContext context, String message) async {
  final result = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('Xác nhận'),
      content: Text(message),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: const Text('Hủy'),
        ),
        ElevatedButton(
          onPressed: () => Navigator.of(context).pop(true),
          child: const Text('Đồng ý'),
        ),
      ],
    ),
  );
  return result ?? false;
}

void _showSuccess(BuildContext context, String message) {
  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
}

void _showError(BuildContext context, Object error) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text(error.toString().replaceFirst('Exception: ', ''))),
  );
}

String _statusLabel(StaffMember member) {
  if (member.status.isActive) {
    return 'Đang hoạt động';
  }

  if (member.status.isPending) {
    return 'Đang chờ';
  }

  return 'Khác';
}

String _dateText(DateTime? value) {
  if (value == null) {
    return '';
  }

  return value.toLocal().toString().split('.').first;
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

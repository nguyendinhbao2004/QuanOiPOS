import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../core/constants/app_constants.dart';
import '../../../../../core/constants/app_permission_codes.dart';
import '../../../../../core/theme/index.dart';
import '../../../../workspace_context/presentation/controllers/store_access_state.dart';
import '../../../../workspace_context/presentation/providers/workspace_context_providers.dart';
import '../controllers/staff_management_access.dart';
import '../controllers/staff_role_form_notifier.dart';
import '../controllers/staff_role_form_state.dart';
import '../providers/staff_management_providers.dart';
import '../widgets/permission_group_list.dart';

class StaffRoleFormPage extends ConsumerStatefulWidget {
  final int storeId;
  final int? roleId;

  const StaffRoleFormPage({super.key, required this.storeId, this.roleId});

  @override
  ConsumerState<StaffRoleFormPage> createState() => _StaffRoleFormPageState();
}

class _StaffRoleFormPageState extends ConsumerState<StaffRoleFormPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  int? _loadedRoleId;

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final accessState = ref.watch(storeAccessNotifierProvider(widget.storeId));

    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.roleId == null ? 'Thêm vai trò' : 'Chi tiết vai trò',
        ),
      ),
      body: switch (accessState.status) {
        StoreAccessStatus.initial || StoreAccessStatus.loading => const Center(
          child: CircularProgressIndicator(),
        ),
        StoreAccessStatus.forbidden || StoreAccessStatus.error => _MessageView(
          message:
              accessState.errorMessage ??
              'Không thể tải quyền cửa hàng để quản lý vai trò.',
        ),
        StoreAccessStatus.ready => _buildReady(
          context,
          _accessFromState(widget.storeId, accessState),
        ),
      },
    );
  }

  Widget _buildReady(BuildContext context, StaffManagementAccess access) {
    if (!access.canManageRoles) {
      return const _MessageView(message: 'Bạn chưa có quyền quản lý vai trò.');
    }

    final args = StaffRoleFormArgs(access: access, roleId: widget.roleId);
    final state = ref.watch(staffRoleFormNotifierProvider(args));
    final notifier = ref.read(staffRoleFormNotifierProvider(args).notifier);

    if (state.status == StaffRoleFormStatus.loading ||
        state.status == StaffRoleFormStatus.initial) {
      return const Center(child: CircularProgressIndicator());
    }

    if (state.status == StaffRoleFormStatus.error &&
        state.permissionGroups.isEmpty) {
      return _MessageView(
        message: state.errorMessage ?? 'Không thể tải thông tin vai trò',
      );
    }

    final role = state.role;
    if (_loadedRoleId != role?.id) {
      _loadedRoleId = role?.id;
      _nameController.text = role?.name ?? '';
    }

    final isReadOnly = state.isSystemRole;
    final isSaving =
        state.status == StaffRoleFormStatus.saving ||
        state.status == StaffRoleFormStatus.deleting;

    return Form(
      key: _formKey,
      child: Column(
        children: [
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(AppConstants.spacingMd),
              children: [
                if (isReadOnly)
                  Card(
                    color: AppColors.primaryLight,
                    child: Padding(
                      padding: const EdgeInsets.all(AppConstants.spacingMd),
                      child: Text(
                        'Vai trò hệ thống chỉ dùng để chọn, không thể sửa hoặc xóa.',
                        style: AppTextStyles.bodySm,
                      ),
                    ),
                  ),
                TextFormField(
                  controller: _nameController,
                  readOnly: isReadOnly,
                  decoration: const InputDecoration(
                    labelText: 'Tên vai trò',
                    hintText: 'Ví dụ: Thu ngân',
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Vui lòng nhập tên vai trò';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: AppConstants.spacingLg),
                Text(
                  'Quyền',
                  style: AppTextStyles.h4.copyWith(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: AppConstants.spacingMd),
                PermissionGroupList(
                  groups: state.permissionGroups,
                  selectedPermissionIds: state.selectedPermissionIds,
                  isReadOnly: isReadOnly,
                  onTogglePermission: notifier.togglePermission,
                  onSetGroupPermissions: notifier.setGroupPermissions,
                ),
              ],
            ),
          ),
          if (!isReadOnly)
            SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.all(AppConstants.spacingMd),
                child: Row(
                  children: [
                    if (role != null)
                      Expanded(
                        child: OutlinedButton(
                          onPressed: isSaving
                              ? null
                              : () => _deleteRole(context, notifier),
                          child: const Text('Xóa'),
                        ),
                      ),
                    if (role != null)
                      const SizedBox(width: AppConstants.spacingMd),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: isSaving
                            ? null
                            : () => _saveRole(context, notifier),
                        child: isSaving
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : Text(role == null ? 'Tạo vai trò' : 'Cập nhật'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Future<void> _saveRole(
    BuildContext context,
    StaffRoleFormNotifier notifier,
  ) async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    try {
      await notifier.save(_nameController.text);
      if (!context.mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Đã lưu vai trò')));
      Navigator.of(context).pop(true);
    } catch (error) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(_cleanError(error))));
      }
    }
  }

  Future<void> _deleteRole(
    BuildContext context,
    StaffRoleFormNotifier notifier,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Xóa vai trò'),
        content: const Text('Bạn muốn xóa vai trò này?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Xóa'),
          ),
        ],
      ),
    );

    if (confirmed != true) {
      return;
    }

    try {
      await notifier.deleteRole();
      if (!context.mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Đã xóa vai trò')));
      Navigator.of(context).pop(true);
    } catch (error) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(_cleanError(error))));
      }
    }
  }

  String _cleanError(Object error) {
    return error.toString().replaceFirst('Exception: ', '');
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

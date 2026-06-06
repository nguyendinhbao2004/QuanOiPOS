import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../../config/router_config.dart';
import '../../../../../core/constants/app_constants.dart';
import '../../../../../core/constants/app_permission_codes.dart';
import '../../../../../core/theme/index.dart';
import '../../../../workspace_context/presentation/controllers/store_access_state.dart';
import '../../../../workspace_context/presentation/providers/workspace_context_providers.dart';
import '../controllers/staff_invite_state.dart';
import '../controllers/staff_management_access.dart';
import '../providers/staff_management_providers.dart';
import '../widgets/staff_role_selector_bottom_sheet.dart';

class InviteStaffPage extends ConsumerStatefulWidget {
  final int storeId;

  const InviteStaffPage({super.key, required this.storeId});

  @override
  ConsumerState<InviteStaffPage> createState() => _InviteStaffPageState();
}

class _InviteStaffPageState extends ConsumerState<InviteStaffPage> {
  final _formKey = GlobalKey<FormState>();
  final _displayNameController = TextEditingController();
  final _emailController = TextEditingController();

  @override
  void dispose() {
    _displayNameController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final accessState = ref.watch(storeAccessNotifierProvider(widget.storeId));

    return Scaffold(
      appBar: AppBar(title: const Text('Thêm nhân viên')),
      body: switch (accessState.status) {
        StoreAccessStatus.initial || StoreAccessStatus.loading => const Center(
          child: CircularProgressIndicator(),
        ),
        StoreAccessStatus.forbidden || StoreAccessStatus.error => _MessageView(
          message:
              accessState.errorMessage ??
              'Không thể tải quyền cửa hàng để mời nhân viên.',
        ),
        StoreAccessStatus.ready => _buildReady(
          context,
          _accessFromState(widget.storeId, accessState),
        ),
      },
    );
  }

  Widget _buildReady(BuildContext context, StaffManagementAccess access) {
    final state = ref.watch(staffInviteNotifierProvider(access));
    final notifier = ref.read(staffInviteNotifierProvider(access).notifier);
    final isSubmitting = state.status == StaffInviteStatus.submitting;

    if (!access.canInviteStaff) {
      return const _MessageView(message: 'Bạn chưa có quyền mời nhân viên.');
    }

    if (state.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (state.status == StaffInviteStatus.error && state.roles.isEmpty) {
      return _MessageView(
        message: state.errorMessage ?? 'Không thể tải dữ liệu mời nhân viên',
      );
    }

    return Form(
      key: _formKey,
      child: Column(
        children: [
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(AppConstants.spacingMd),
              children: [
                TextFormField(
                  controller: _displayNameController,
                  textInputAction: TextInputAction.next,
                  decoration: const InputDecoration(
                    labelText: 'Tên nhân viên',
                    hintText: 'Ví dụ: Nguyễn Văn A',
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Vui lòng nhập tên nhân viên';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: AppConstants.spacingMd),
                TextFormField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  textInputAction: TextInputAction.done,
                  decoration: const InputDecoration(
                    labelText: 'Email',
                    hintText: 'staff@example.com',
                  ),
                  validator: (value) {
                    final email = value?.trim() ?? '';
                    if (email.isEmpty) {
                      return 'Vui lòng nhập email';
                    }
                    if (!email.contains('@')) {
                      return 'Email không hợp lệ';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: AppConstants.spacingMd),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Vai trò'),
                  subtitle: Text(
                    state.selectedRole?.name ?? 'Chọn 1 vai trò cho nhân viên',
                  ),
                  trailing: const Icon(Icons.expand_more_rounded),
                  onTap: () async {
                    final result =
                        await showModalBottomSheet<StaffRoleSelectorResult>(
                          context: context,
                          isScrollControlled: true,
                          useSafeArea: true,
                          backgroundColor: Colors.transparent,
                          builder: (context) => FractionallySizedBox(
                            heightFactor: 0.78,
                            child: StaffRoleSelectorBottomSheet(
                              roles: state.roles,
                              selectedRoleId: state.selectedRole?.id,
                              canManageRoles: access.canManageRoles,
                            ),
                          ),
                        );
                    if (result == null) {
                      return;
                    }

                    if (result.shouldCreateRole) {
                      if (!context.mounted) {
                        return;
                      }

                      final created = await context.pushNamed(
                        RouteNames.storeStaffRoleCreate,
                        pathParameters: {'storeId': access.storeId.toString()},
                      );
                      if (created == true && context.mounted) {
                        await notifier.load();
                      }
                      return;
                    }

                    final roleId = result.roleId;
                    if (roleId != null) {
                      notifier.selectRole(roleId);
                    }
                  },
                ),
              ],
            ),
          ),
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.all(AppConstants.spacingMd),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: isSubmitting ? null : () => _submit(access),
                  child: isSubmitting
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Tạo và gửi lời mời'),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _submit(StaffManagementAccess access) async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    try {
      await ref
          .read(staffInviteNotifierProvider(access).notifier)
          .submit(
            displayName: _displayNameController.text.trim(),
            invitedEmail: _emailController.text.trim(),
          );

      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Đã gửi lời mời nhân viên')));
      Navigator.of(context).pop(true);
    } catch (error) {
      if (mounted) {
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

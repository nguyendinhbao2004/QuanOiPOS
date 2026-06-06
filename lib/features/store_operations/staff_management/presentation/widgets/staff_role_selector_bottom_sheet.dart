import 'package:flutter/material.dart';

import '../../../../../core/constants/app_constants.dart';
import '../../../presentation/widgets/store_bottom_sheet_panel.dart';
import '../../domain/entities/staff_role.dart';

class StaffRoleSelectorResult {
  final int? roleId;
  final bool shouldCreateRole;

  const StaffRoleSelectorResult._({
    required this.roleId,
    required this.shouldCreateRole,
  });

  const StaffRoleSelectorResult.select(int roleId)
    : this._(roleId: roleId, shouldCreateRole: false);

  const StaffRoleSelectorResult.createRole()
    : this._(roleId: null, shouldCreateRole: true);
}

class StaffRoleSelectorBottomSheet extends StatelessWidget {
  final List<StaffRole> roles;
  final int? selectedRoleId;
  final bool canManageRoles;

  const StaffRoleSelectorBottomSheet({
    super.key,
    required this.roles,
    required this.selectedRoleId,
    required this.canManageRoles,
  });

  @override
  Widget build(BuildContext context) {
    return StoreBottomSheetPanel(
      title: 'Chọn vai trò',
      child: Column(
        children: [
          Expanded(
            child: roles.isEmpty
                ? const Center(child: Text('Chưa có vai trò để chọn'))
                : ListView.separated(
                    padding: const EdgeInsets.only(
                      bottom: AppConstants.spacingLg,
                    ),
                    itemBuilder: (context, index) {
                      final role = roles[index];
                      final isSelected = role.id == selectedRoleId;
                      return ListTile(
                        onTap: () => Navigator.of(
                          context,
                        ).pop(StaffRoleSelectorResult.select(role.id)),
                        title: Text(role.name),
                        subtitle: role.permissions.isEmpty
                            ? null
                            : Text('${role.permissions.length} quyền'),
                        trailing: isSelected
                            ? const Icon(Icons.check_circle_rounded)
                            : const Icon(Icons.circle_outlined),
                      );
                    },
                    separatorBuilder: (context, index) =>
                        const Divider(height: 1),
                    itemCount: roles.length,
                  ),
          ),
          if (canManageRoles)
            Padding(
              padding: const EdgeInsets.all(AppConstants.spacingMd),
              child: SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () {
                    Navigator.of(
                      context,
                    ).pop(const StaffRoleSelectorResult.createRole());
                  },
                  icon: const Icon(Icons.add_rounded),
                  label: const Text('Thêm vai trò'),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

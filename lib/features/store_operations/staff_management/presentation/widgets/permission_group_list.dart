import 'package:flutter/material.dart';

import '../../../../../core/constants/app_constants.dart';
import '../../../../../core/theme/index.dart';
import '../../domain/entities/permission_group.dart';

class PermissionGroupList extends StatelessWidget {
  final List<PermissionGroup> groups;
  final Set<int> selectedPermissionIds;
  final bool isReadOnly;
  final void Function(int permissionId) onTogglePermission;
  final void Function(List<int> permissionIds, bool isSelected)
  onSetGroupPermissions;

  const PermissionGroupList({
    super.key,
    required this.groups,
    required this.selectedPermissionIds,
    required this.isReadOnly,
    required this.onTogglePermission,
    required this.onSetGroupPermissions,
  });

  @override
  Widget build(BuildContext context) {
    if (groups.isEmpty) {
      return const Center(child: Text('Chưa có dữ liệu quyền'));
    }

    return Column(
      children: groups.map((group) {
        final permissionIds = group.permissions
            .map((permission) => permission.id)
            .toList();
        final selectedCount = permissionIds
            .where(selectedPermissionIds.contains)
            .length;
        final isAllSelected =
            permissionIds.isNotEmpty && selectedCount == permissionIds.length;
        final isPartiallySelected =
            selectedCount > 0 && selectedCount < permissionIds.length;

        return Card(
          margin: const EdgeInsets.only(bottom: AppConstants.spacingMd),
          child: ExpansionTile(
            initiallyExpanded: selectedCount > 0,
            leading: Checkbox(
              value: isPartiallySelected ? null : isAllSelected,
              tristate: true,
              onChanged: isReadOnly
                  ? null
                  : (value) =>
                        onSetGroupPermissions(permissionIds, value ?? false),
            ),
            title: Text(
              group.groupName,
              style: AppTextStyles.label.copyWith(fontWeight: FontWeight.w700),
            ),
            subtitle: group.description.isEmpty
                ? Text('$selectedCount/${permissionIds.length} quyền')
                : Text(group.description),
            children: group.permissions.map((permission) {
              return CheckboxListTile(
                value: selectedPermissionIds.contains(permission.id),
                onChanged: isReadOnly
                    ? null
                    : (_) => onTogglePermission(permission.id),
                title: Text(permission.name),
              );
            }).toList(),
          ),
        );
      }).toList(),
    );
  }
}

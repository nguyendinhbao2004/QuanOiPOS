import '../../domain/entities/permission_group.dart';
import '../../domain/entities/staff_role.dart';

enum StaffRoleFormStatus { initial, loading, ready, saving, deleting, error }

class StaffRoleFormState {
  final StaffRoleFormStatus status;
  final StaffRole? role;
  final List<PermissionGroup> permissionGroups;
  final Set<int> selectedPermissionIds;
  final String? errorMessage;

  const StaffRoleFormState({
    required this.status,
    required this.role,
    required this.permissionGroups,
    required this.selectedPermissionIds,
    required this.errorMessage,
  });

  const StaffRoleFormState.initial()
    : status = StaffRoleFormStatus.initial,
      role = null,
      permissionGroups = const [],
      selectedPermissionIds = const {},
      errorMessage = null;

  bool get isSystemRole => role?.isSystemRole ?? false;

  StaffRoleFormState copyWith({
    StaffRoleFormStatus? status,
    StaffRole? role,
    List<PermissionGroup>? permissionGroups,
    Set<int>? selectedPermissionIds,
    String? errorMessage,
    bool clearRole = false,
    bool clearError = false,
  }) {
    return StaffRoleFormState(
      status: status ?? this.status,
      role: clearRole ? null : (role ?? this.role),
      permissionGroups: permissionGroups ?? this.permissionGroups,
      selectedPermissionIds:
          selectedPermissionIds ?? this.selectedPermissionIds,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }
}

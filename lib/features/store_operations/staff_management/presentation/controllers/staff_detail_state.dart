import '../../domain/entities/permission_group.dart';
import '../../domain/entities/staff_member.dart';
import '../../domain/entities/staff_role.dart';

enum StaffDetailStatus { initial, loading, ready, forbidden, error }

class StaffDetailState {
  final StaffDetailStatus status;
  final StaffMember? member;
  final List<StaffRole> roles;
  final List<PermissionGroup> permissionGroups;
  final int? selectedRoleId;
  final Set<int> selectedPermissionIds;
  final String? errorMessage;
  final bool isMutating;

  const StaffDetailState({
    required this.status,
    required this.member,
    required this.roles,
    required this.permissionGroups,
    required this.selectedRoleId,
    required this.selectedPermissionIds,
    required this.errorMessage,
    required this.isMutating,
  });

  const StaffDetailState.initial()
    : status = StaffDetailStatus.initial,
      member = null,
      roles = const [],
      permissionGroups = const [],
      selectedRoleId = null,
      selectedPermissionIds = const {},
      errorMessage = null,
      isMutating = false;

  StaffRole? get selectedRole {
    final roleId = selectedRoleId;
    if (roleId == null) {
      return null;
    }

    final matchingRoles = roles.where((role) => role.id == roleId);
    return matchingRoles.isEmpty ? null : matchingRoles.first;
  }

  StaffDetailState copyWith({
    StaffDetailStatus? status,
    StaffMember? member,
    List<StaffRole>? roles,
    List<PermissionGroup>? permissionGroups,
    int? selectedRoleId,
    Set<int>? selectedPermissionIds,
    String? errorMessage,
    bool? isMutating,
    bool clearMember = false,
    bool clearSelectedRole = false,
    bool clearError = false,
  }) {
    return StaffDetailState(
      status: status ?? this.status,
      member: clearMember ? null : (member ?? this.member),
      roles: roles ?? this.roles,
      permissionGroups: permissionGroups ?? this.permissionGroups,
      selectedRoleId: clearSelectedRole
          ? null
          : (selectedRoleId ?? this.selectedRoleId),
      selectedPermissionIds:
          selectedPermissionIds ?? this.selectedPermissionIds,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      isMutating: isMutating ?? this.isMutating,
    );
  }
}

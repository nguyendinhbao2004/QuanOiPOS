import '../../domain/entities/permission_group.dart';
import '../../domain/entities/staff_role.dart';

enum StaffInviteStatus { initial, loading, ready, submitting, success, error }

class StaffInviteState {
  final StaffInviteStatus status;
  final List<StaffRole> roles;
  final List<PermissionGroup> permissionGroups;
  final StaffRole? selectedRole;
  final String? errorMessage;

  const StaffInviteState({
    required this.status,
    required this.roles,
    required this.permissionGroups,
    required this.selectedRole,
    required this.errorMessage,
  });

  const StaffInviteState.initial()
    : status = StaffInviteStatus.initial,
      roles = const [],
      permissionGroups = const [],
      selectedRole = null,
      errorMessage = null;

  bool get isLoading =>
      status == StaffInviteStatus.initial ||
      status == StaffInviteStatus.loading;

  StaffInviteState copyWith({
    StaffInviteStatus? status,
    List<StaffRole>? roles,
    List<PermissionGroup>? permissionGroups,
    StaffRole? selectedRole,
    String? errorMessage,
    bool clearSelectedRole = false,
    bool clearError = false,
  }) {
    return StaffInviteState(
      status: status ?? this.status,
      roles: roles ?? this.roles,
      permissionGroups: permissionGroups ?? this.permissionGroups,
      selectedRole: clearSelectedRole
          ? null
          : (selectedRole ?? this.selectedRole),
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }
}

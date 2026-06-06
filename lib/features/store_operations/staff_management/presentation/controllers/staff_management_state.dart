import '../../domain/entities/staff_member.dart';
import '../../domain/entities/staff_role.dart';

enum StaffManagementStatus { initial, loading, ready, forbidden, error }

class StaffManagementState {
  final StaffManagementStatus status;
  final List<StaffMember> staff;
  final List<StaffRole> roles;
  final String? errorMessage;
  final bool isMutating;

  const StaffManagementState({
    required this.status,
    required this.staff,
    required this.roles,
    required this.errorMessage,
    required this.isMutating,
  });

  const StaffManagementState.initial()
    : status = StaffManagementStatus.initial,
      staff = const [],
      roles = const [],
      errorMessage = null,
      isMutating = false;

  StaffManagementState copyWith({
    StaffManagementStatus? status,
    List<StaffMember>? staff,
    List<StaffRole>? roles,
    String? errorMessage,
    bool? isMutating,
    bool clearError = false,
  }) {
    return StaffManagementState(
      status: status ?? this.status,
      staff: staff ?? this.staff,
      roles: roles ?? this.roles,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      isMutating: isMutating ?? this.isMutating,
    );
  }
}

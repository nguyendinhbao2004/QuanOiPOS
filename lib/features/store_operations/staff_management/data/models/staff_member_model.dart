import '../../domain/entities/staff_member.dart';
import '../../domain/entities/staff_status.dart';
import 'staff_model_helpers.dart';
import 'staff_permission_model.dart';
import 'staff_role_model.dart';

class StaffMemberModel {
  final StaffStatus status;
  final int? storeUserId;
  final int? invitationId;
  final int? accountId;
  final int? invitedAccountId;
  final String displayName;
  final String accountFullName;
  final String email;
  final String phone;
  final StaffRoleModel? role;
  final List<StaffPermissionModel> permissions;
  final DateTime? joinedAt;
  final DateTime? createdAt;
  final DateTime? expiresAt;
  final bool isOwner;

  const StaffMemberModel({
    required this.status,
    required this.storeUserId,
    required this.invitationId,
    required this.accountId,
    required this.invitedAccountId,
    required this.displayName,
    required this.accountFullName,
    required this.email,
    required this.phone,
    required this.role,
    required this.permissions,
    required this.joinedAt,
    required this.createdAt,
    required this.expiresAt,
    required this.isOwner,
  });

  factory StaffMemberModel.fromJson(Object? json) {
    if (json is! Map<String, dynamic>) {
      throw const FormatException('Invalid staff member data');
    }

    final roleJson = readJson(json, 'role', 'Role');

    return StaffMemberModel(
      status: _statusFromJson(readJson(json, 'status', 'Status')),
      storeUserId: nullableIntValue(
        readJson(json, 'storeUserId', 'StoreUserId'),
      ),
      invitationId: nullableIntValue(
        readJson(json, 'invitationId', 'InvitationId'),
      ),
      accountId: nullableIntValue(readJson(json, 'accountId', 'AccountId')),
      invitedAccountId: nullableIntValue(
        readJson(json, 'invitedAccountId', 'InvitedAccountId'),
      ),
      displayName: stringValue(readJson(json, 'displayName', 'DisplayName')),
      accountFullName: stringValue(
        readJson(json, 'accountFullName', 'AccountFullName'),
      ),
      email: stringValue(readJson(json, 'email', 'Email')),
      phone: stringValue(readJson(json, 'phone', 'Phone')),
      role: roleJson == null ? null : StaffRoleModel.fromJson(roleJson),
      permissions: StaffPermissionModel.listFromJson(
        readJson(json, 'permissions', 'Permissions'),
      ),
      joinedAt: nullableDateTimeValue(readJson(json, 'joinedAt', 'JoinedAt')),
      createdAt: nullableDateTimeValue(
        readJson(json, 'createdAt', 'CreatedAt'),
      ),
      expiresAt: nullableDateTimeValue(
        readJson(json, 'expiresAt', 'ExpiresAt'),
      ),
      isOwner: boolValue(readJson(json, 'isOwner', 'IsOwner')),
    );
  }

  static List<StaffMemberModel> listFromJson(Object? json) {
    if (json == null) {
      return const [];
    }

    if (json is List) {
      return json.map(StaffMemberModel.fromJson).toList();
    }

    throw const FormatException('Invalid staff member list data');
  }

  StaffMember toEntity() {
    return StaffMember(
      status: status,
      storeUserId: storeUserId,
      invitationId: invitationId,
      accountId: accountId,
      invitedAccountId: invitedAccountId,
      displayName: displayName,
      accountFullName: accountFullName,
      email: email,
      phone: phone,
      role: role?.toEntity(),
      permissions: permissions
          .map((permission) => permission.toEntity())
          .toList(),
      joinedAt: joinedAt,
      createdAt: createdAt,
      expiresAt: expiresAt,
      isOwner: isOwner,
    );
  }

  static StaffStatus _statusFromJson(Object? value) {
    final status = stringValue(value).toLowerCase();
    if (status == 'active') {
      return StaffStatus.active;
    }

    if (status == 'pending') {
      return StaffStatus.pending;
    }

    return StaffStatus.other;
  }
}

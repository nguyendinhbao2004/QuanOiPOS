import '../../domain/entities/staff_invitation.dart';
import 'staff_model_helpers.dart';

class StaffInvitationModel {
  final int invitationId;
  final int storeId;
  final String invitedEmail;
  final String displayName;
  final int? invitedAccountId;
  final int roleId;
  final int invitedByAccountId;
  final int status;
  final DateTime? createdAt;
  final DateTime? expiresAt;
  final DateTime? respondedAt;
  final List<int> permissionIds;
  final int? notificationId;

  const StaffInvitationModel({
    required this.invitationId,
    required this.storeId,
    required this.invitedEmail,
    required this.displayName,
    required this.invitedAccountId,
    required this.roleId,
    required this.invitedByAccountId,
    required this.status,
    required this.createdAt,
    required this.expiresAt,
    required this.respondedAt,
    required this.permissionIds,
    required this.notificationId,
  });

  factory StaffInvitationModel.fromJson(Object? json) {
    if (json is! Map<String, dynamic>) {
      throw const FormatException('Invalid staff invitation data');
    }

    return StaffInvitationModel(
      invitationId: intValue(readJson(json, 'invitationId', 'InvitationId')),
      storeId: intValue(readJson(json, 'storeId', 'StoreId')),
      invitedEmail: stringValue(readJson(json, 'invitedEmail', 'InvitedEmail')),
      displayName: stringValue(readJson(json, 'displayName', 'DisplayName')),
      invitedAccountId: nullableIntValue(
        readJson(json, 'invitedAccountId', 'InvitedAccountId'),
      ),
      roleId: intValue(readJson(json, 'roleId', 'RoleId')),
      invitedByAccountId: intValue(
        readJson(json, 'invitedByAccountId', 'InvitedByAccountId'),
      ),
      status: intValue(readJson(json, 'status', 'Status')),
      createdAt: nullableDateTimeValue(
        readJson(json, 'createdAt', 'CreatedAt'),
      ),
      expiresAt: nullableDateTimeValue(
        readJson(json, 'expiresAt', 'ExpiresAt'),
      ),
      respondedAt: nullableDateTimeValue(
        readJson(json, 'respondedAt', 'RespondedAt'),
      ),
      permissionIds: intListValue(
        readJson(json, 'permissionIds', 'PermissionIds'),
      ),
      notificationId: nullableIntValue(
        readJson(json, 'notificationId', 'NotificationId'),
      ),
    );
  }

  StaffInvitation toEntity() {
    return StaffInvitation(
      invitationId: invitationId,
      storeId: storeId,
      invitedEmail: invitedEmail,
      displayName: displayName,
      invitedAccountId: invitedAccountId,
      roleId: roleId,
      invitedByAccountId: invitedByAccountId,
      status: status,
      createdAt: createdAt,
      expiresAt: expiresAt,
      respondedAt: respondedAt,
      permissionIds: permissionIds,
      notificationId: notificationId,
    );
  }
}

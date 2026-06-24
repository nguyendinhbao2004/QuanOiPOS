import '../../domain/entities/received_store_invitation.dart';

class ReceivedStoreInvitationModel {
  final int invitationId;
  final int storeId;
  final String storeName;
  final String invitedEmail;
  final String displayName;
  final int? invitedAccountId;
  final int roleId;
  final String roleName;
  final int invitedByAccountId;
  final String invitedByFullName;
  final String invitedByEmail;
  final int status;
  final DateTime? createdAt;
  final DateTime? expiresAt;
  final DateTime? respondedAt;
  final List<int> permissionIds;

  const ReceivedStoreInvitationModel({
    required this.invitationId,
    required this.storeId,
    required this.storeName,
    required this.invitedEmail,
    required this.displayName,
    required this.invitedAccountId,
    required this.roleId,
    required this.roleName,
    required this.invitedByAccountId,
    required this.invitedByFullName,
    required this.invitedByEmail,
    required this.status,
    required this.createdAt,
    required this.expiresAt,
    required this.respondedAt,
    required this.permissionIds,
  });

  factory ReceivedStoreInvitationModel.fromJson(Object? json) {
    if (json is! Map<String, dynamic>) {
      throw const FormatException('Invalid received store invitation data');
    }

    return ReceivedStoreInvitationModel(
      invitationId: _intValue(json['invitationId'] ?? json['InvitationId']),
      storeId: _intValue(json['storeId'] ?? json['StoreId']),
      storeName: _stringValue(json['storeName'] ?? json['StoreName']),
      invitedEmail: _stringValue(json['invitedEmail'] ?? json['InvitedEmail']),
      displayName: _stringValue(json['displayName'] ?? json['DisplayName']),
      invitedAccountId: _nullableIntValue(
        json['invitedAccountId'] ?? json['InvitedAccountId'],
      ),
      roleId: _intValue(json['roleId'] ?? json['RoleId']),
      roleName: _stringValue(json['roleName'] ?? json['RoleName']),
      invitedByAccountId: _intValue(
        json['invitedByAccountId'] ?? json['InvitedByAccountId'],
      ),
      invitedByFullName: _stringValue(
        json['invitedByFullName'] ?? json['InvitedByFullName'],
      ),
      invitedByEmail: _stringValue(
        json['invitedByEmail'] ?? json['InvitedByEmail'],
      ),
      status: _intValue(json['status'] ?? json['Status']),
      createdAt: _nullableDateTimeValue(json['createdAt'] ?? json['CreatedAt']),
      expiresAt: _nullableDateTimeValue(json['expiresAt'] ?? json['ExpiresAt']),
      respondedAt: _nullableDateTimeValue(
        json['respondedAt'] ?? json['RespondedAt'],
      ),
      permissionIds: _intListValue(
        json['permissionIds'] ?? json['PermissionIds'],
      ),
    );
  }

  static List<ReceivedStoreInvitationModel> listFromJson(Object? json) {
    if (json is! List) {
      return const [];
    }

    return json.map(ReceivedStoreInvitationModel.fromJson).toList();
  }

  ReceivedStoreInvitation toEntity() {
    return ReceivedStoreInvitation(
      invitationId: invitationId,
      storeId: storeId,
      storeName: storeName,
      invitedEmail: invitedEmail,
      displayName: displayName,
      invitedAccountId: invitedAccountId,
      roleId: roleId,
      roleName: roleName,
      invitedByAccountId: invitedByAccountId,
      invitedByFullName: invitedByFullName,
      invitedByEmail: invitedByEmail,
      status: status,
      createdAt: createdAt,
      expiresAt: expiresAt,
      respondedAt: respondedAt,
      permissionIds: permissionIds,
    );
  }

  static int _intValue(Object? value) {
    if (value is int) {
      return value;
    }

    return int.tryParse(value?.toString() ?? '') ?? 0;
  }

  static int? _nullableIntValue(Object? value) {
    if (value == null) {
      return null;
    }

    if (value is int) {
      return value;
    }

    return int.tryParse(value.toString());
  }

  static String _stringValue(Object? value, {String fallback = ''}) {
    if (value == null) {
      return fallback;
    }

    final text = value.toString().trim();
    return text.isEmpty ? fallback : text;
  }

  static DateTime? _nullableDateTimeValue(Object? value) {
    if (value == null) {
      return null;
    }

    return DateTime.tryParse(value.toString());
  }

  static List<int> _intListValue(Object? value) {
    if (value is! List) {
      return const [];
    }

    return value
        .map((item) => _nullableIntValue(item))
        .whereType<int>()
        .toList();
  }
}

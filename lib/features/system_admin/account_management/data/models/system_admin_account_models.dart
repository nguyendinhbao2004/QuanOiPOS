import '../../domain/entities/system_admin_account.dart';

class SystemAdminAccountSummaryModel {
  final SystemAdminAccountSummary value;
  const SystemAdminAccountSummaryModel(this.value);
  factory SystemAdminAccountSummaryModel.fromJson(Object? json) {
    final m = _map(json);
    return SystemAdminAccountSummaryModel(
      SystemAdminAccountSummary(
        totalAccounts: _int(m['totalAccounts']),
        systemAdminAccounts: _int(m['systemAdminAccounts']),
        storeUserAccounts: _int(m['storeUserAccounts']),
        activeAccounts: _int(m['activeAccounts']),
        suspendedAccounts: _int(m['suspendedAccounts']),
        pendingRegistrationCount: _int(m['pendingRegistrationCount']),
      ),
    );
  }
}

class SystemAdminAccountModel {
  final SystemAdminAccount value;
  const SystemAdminAccountModel(this.value);
  factory SystemAdminAccountModel.fromJson(Object? json) {
    final m = _map(json);
    return SystemAdminAccountModel(
      SystemAdminAccount(
        id: _int(m['id']),
        fullName: _string(m['fullName']),
        email: _string(m['email']),
        phone: _string(m['phone']),
        accountType: _type(m['accountType']),
        status: _status(m['status']),
        createdAt:
            _date(m['createdAt']) ??
            DateTime.fromMillisecondsSinceEpoch(0, isUtc: true),
        lastLogin: _date(m['lastLogin']),
      ),
    );
  }
}

class SystemAdminAccountDetailModel {
  final SystemAdminAccountDetail value;
  const SystemAdminAccountDetailModel(this.value);
  factory SystemAdminAccountDetailModel.fromJson(Object? json) {
    final m = _map(json);
    final memberships = m['storeMemberships'] is List
        ? (m['storeMemberships'] as List).map((item) {
            final x = _map(item);
            return SystemAdminAccountMembership(
              storeId: _int(x['storeId']),
              storeName: _string(x['storeName']),
              storeStatus: _string(x['storeStatus']),
              address: _string(x['address']),
              phone: _string(x['phone']),
              isOwner: x['isOwner'] == true,
              isActive: x['isActive'] == true,
              roleId: _nullableInt(x['roleId']),
              roleName: _nullableString(x['roleName']),
              joinedAt: _date(x['joinedAt']),
            );
          }).toList()
        : const <SystemAdminAccountMembership>[];
    return SystemAdminAccountDetailModel(
      SystemAdminAccountDetail(
        id: _int(m['id']),
        fullName: _string(m['fullName']),
        email: _string(m['email']),
        phone: _string(m['phone']),
        accountType: _type(m['accountType']),
        status: _status(m['status']),
        createdAt:
            _date(m['createdAt']) ??
            DateTime.fromMillisecondsSinceEpoch(0, isUtc: true),
        lastLogin: _date(m['lastLogin']),
        updatedAt: _date(m['updatedAt']),
        storeMemberships: memberships,
      ),
    );
  }
}

class PendingRegistrationModel {
  final PendingRegistration value;
  const PendingRegistrationModel(this.value);
  factory PendingRegistrationModel.fromJson(Object? json) {
    final m = _map(json);
    return PendingRegistrationModel(
      PendingRegistration(
        email: _string(m['email']),
        fullName: _string(m['fullName']),
        createdAt:
            _date(m['createdAt']) ??
            DateTime.fromMillisecondsSinceEpoch(0, isUtc: true),
        expiresAt:
            _date(m['expiresAt']) ??
            DateTime.fromMillisecondsSinceEpoch(0, isUtc: true),
        attemptCount: _int(m['attemptCount']),
        maxAttempts: _int(m['maxAttempts']),
      ),
    );
  }
}

class SystemAdminPageModel<T> {
  final SystemAdminPage<T> value;
  const SystemAdminPageModel(this.value);
  factory SystemAdminPageModel.fromJson(
    Object? json,
    T Function(Object?) item,
  ) {
    final m = _map(json);
    final p = _map(m['pagination']);
    final raw = m['items'];
    return SystemAdminPageModel(
      SystemAdminPage(
        items: raw is List ? raw.map(item).toList() : const [],
        pageIndex: _int(p['pageIndex'], fallback: 1),
        pageSize: _int(p['pageSize'], fallback: 20),
        totalItems: _int(p['totalItems']),
        totalPages: _int(p['totalPages'], fallback: 1),
      ),
    );
  }
}

Map<String, dynamic> _map(Object? value) =>
    value is Map<String, dynamic> ? value : <String, dynamic>{};
int _int(Object? v, {int fallback = 0}) =>
    v is num ? v.toInt() : int.tryParse(v?.toString() ?? '') ?? fallback;
int? _nullableInt(Object? v) => v == null ? null : _int(v);
String _string(Object? v) => v?.toString() ?? '';
String? _nullableString(Object? v) => v?.toString();
DateTime? _date(Object? v) => v is String ? DateTime.tryParse(v) : null;
SystemAdminAccountType _type(Object? v) =>
    switch (v?.toString().toLowerCase()) {
      'systemadmin' => SystemAdminAccountType.systemAdmin,
      'storeuser' => SystemAdminAccountType.storeUser,
      _ => SystemAdminAccountType.all,
    };
SystemAdminAccountStatus _status(Object? v) =>
    switch (v?.toString().toLowerCase()) {
      'active' => SystemAdminAccountStatus.active,
      'inactive' => SystemAdminAccountStatus.inactive,
      'suspended' => SystemAdminAccountStatus.suspended,
      _ => SystemAdminAccountStatus.all,
    };

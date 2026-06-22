enum SystemAdminAccountType { all, systemAdmin, storeUser }

enum SystemAdminAccountStatus { all, active, inactive, suspended }

enum SystemAdminAccountSort {
  id,
  fullName,
  email,
  createdAt,
  lastLogin,
  accountType,
  status,
}

enum SystemAdminSortDirection { asc, desc }

enum SystemAdminAccountView { accounts, pendingRegistrations }

class SystemAdminAccountSummary {
  final int totalAccounts,
      systemAdminAccounts,
      storeUserAccounts,
      activeAccounts,
      suspendedAccounts,
      pendingRegistrationCount;
  const SystemAdminAccountSummary({
    required this.totalAccounts,
    required this.systemAdminAccounts,
    required this.storeUserAccounts,
    required this.activeAccounts,
    required this.suspendedAccounts,
    required this.pendingRegistrationCount,
  });
}

class SystemAdminAccountQuery {
  final String keyword;
  final SystemAdminAccountType accountType;
  final SystemAdminAccountStatus status;
  final DateTime? createdFrom, createdTo, lastLoginFrom, lastLoginTo;
  final SystemAdminAccountSort sort;
  final SystemAdminSortDirection direction;
  const SystemAdminAccountQuery({
    this.keyword = '',
    this.accountType = SystemAdminAccountType.all,
    this.status = SystemAdminAccountStatus.all,
    this.createdFrom,
    this.createdTo,
    this.lastLoginFrom,
    this.lastLoginTo,
    this.sort = SystemAdminAccountSort.createdAt,
    this.direction = SystemAdminSortDirection.desc,
  });
  SystemAdminAccountQuery copyWith({
    String? keyword,
    SystemAdminAccountType? accountType,
    SystemAdminAccountStatus? status,
    DateTime? createdFrom,
    DateTime? createdTo,
    DateTime? lastLoginFrom,
    DateTime? lastLoginTo,
    SystemAdminAccountSort? sort,
    SystemAdminSortDirection? direction,
    bool clearCreatedDates = false,
    bool clearLastLoginDates = false,
  }) => SystemAdminAccountQuery(
    keyword: keyword ?? this.keyword,
    accountType: accountType ?? this.accountType,
    status: status ?? this.status,
    createdFrom: clearCreatedDates ? null : createdFrom ?? this.createdFrom,
    createdTo: clearCreatedDates ? null : createdTo ?? this.createdTo,
    lastLoginFrom: clearLastLoginDates
        ? null
        : lastLoginFrom ?? this.lastLoginFrom,
    lastLoginTo: clearLastLoginDates ? null : lastLoginTo ?? this.lastLoginTo,
    sort: sort ?? this.sort,
    direction: direction ?? this.direction,
  );
}

class SystemAdminAccount {
  final int id;
  final String fullName, email, phone;
  final SystemAdminAccountType accountType;
  final SystemAdminAccountStatus status;
  final DateTime createdAt;
  final DateTime? lastLogin;
  const SystemAdminAccount({
    required this.id,
    required this.fullName,
    required this.email,
    required this.phone,
    required this.accountType,
    required this.status,
    required this.createdAt,
    required this.lastLogin,
  });
}

class SystemAdminAccountMembership {
  final int storeId;
  final String storeName, storeStatus, address, phone;
  final bool isOwner, isActive;
  final int? roleId;
  final String? roleName;
  final DateTime? joinedAt;
  const SystemAdminAccountMembership({
    required this.storeId,
    required this.storeName,
    required this.storeStatus,
    required this.address,
    required this.phone,
    required this.isOwner,
    required this.isActive,
    this.roleId,
    this.roleName,
    this.joinedAt,
  });
}

class SystemAdminAccountDetail extends SystemAdminAccount {
  final DateTime? updatedAt;
  final List<SystemAdminAccountMembership> storeMemberships;
  const SystemAdminAccountDetail({
    required super.id,
    required super.fullName,
    required super.email,
    required super.phone,
    required super.accountType,
    required super.status,
    required super.createdAt,
    required super.lastLogin,
    required this.updatedAt,
    required this.storeMemberships,
  });
}

class PendingRegistration {
  final String email, fullName;
  final DateTime createdAt, expiresAt;
  final int attemptCount, maxAttempts;
  const PendingRegistration({
    required this.email,
    required this.fullName,
    required this.createdAt,
    required this.expiresAt,
    required this.attemptCount,
    required this.maxAttempts,
  });
}

class SystemAdminPage<T> {
  final List<T> items;
  final int pageIndex, pageSize, totalItems, totalPages;
  const SystemAdminPage({
    required this.items,
    required this.pageIndex,
    required this.pageSize,
    required this.totalItems,
    required this.totalPages,
  });
}

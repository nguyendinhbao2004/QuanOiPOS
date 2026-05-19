enum AccountType {
  superAdmin,
  storeUser,
}

extension AccountTypeX on AccountType {
  static AccountType fromApiValue(String raw) {
    switch (raw.trim().toLowerCase()) {
      case 'superadmin':
        return AccountType.superAdmin;
      case 'storeuser':
        return AccountType.storeUser;
      default:
        return AccountType.storeUser;
    }
  }
}

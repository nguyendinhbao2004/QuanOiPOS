enum AccountType { systemAdmin, storeUser }

extension AccountTypeX on AccountType {
  static AccountType fromApiValue(String raw) {
    switch (raw.trim().toLowerCase()) {
      case 'systemadmin':
        return AccountType.systemAdmin;
      case 'storeuser':
        return AccountType.storeUser;
      default:
        return AccountType.storeUser;
    }
  }
}

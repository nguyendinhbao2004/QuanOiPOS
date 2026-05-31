import 'account_type.dart';

class CurrentUserProfile {
  final int accountId;
  final String email;
  final String fullName;
  final String phone;
  final AccountType accountType;
  final String status;
  final DateTime? lastLogin;

  const CurrentUserProfile({
    required this.accountId,
    required this.email,
    required this.fullName,
    required this.phone,
    required this.accountType,
    required this.status,
    this.lastLogin,
  });
}

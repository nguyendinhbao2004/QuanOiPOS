import 'account_type.dart';

class LoginResult {
  final int accountId;
  final String email;
  final String fullName;
  final String phone;
  final AccountType accountType;
  final String accessToken;
  final String refreshToken;

  const LoginResult({
    required this.accountId,
    required this.email,
    required this.fullName,
    required this.phone,
    required this.accountType,
    required this.accessToken,
    required this.refreshToken,
  });
}

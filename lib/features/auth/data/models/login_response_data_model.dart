import '../../domain/entities/account_type.dart';
import '../../domain/entities/login_result.dart';

class LoginResponseDataModel {
  final int accountId;
  final String email;
  final String fullName;
  final String phone;
  final AccountType accountType;
  final String accessToken;
  final String refreshToken;

  const LoginResponseDataModel({
    required this.accountId,
    required this.email,
    required this.fullName,
    required this.phone,
    required this.accountType,
    required this.accessToken,
    required this.refreshToken,
  });

  factory LoginResponseDataModel.fromJson(Object? rawJson) {
    if (rawJson is! Map<String, dynamic>) {
      throw Exception('Invalid login response data');
    }

    return LoginResponseDataModel(
      accountId: rawJson['accountId'] as int? ?? 0,
      email: rawJson['email'] as String? ?? '',
      fullName: rawJson['fullName'] as String? ?? '',
      phone: rawJson['phone'] as String? ?? '',
      accountType: AccountTypeX.fromApiValue(rawJson['accountType'] as String? ?? ''),
      accessToken: rawJson['accessToken'] as String? ?? '',
      refreshToken: rawJson['refreshToken'] as String? ?? '',
    );
  }

  LoginResult toEntity() {
    return LoginResult(
      accountId: accountId,
      email: email,
      fullName: fullName,
      phone: phone,
      accountType: accountType,
      accessToken: accessToken,
      refreshToken: refreshToken,
    );
  }
}

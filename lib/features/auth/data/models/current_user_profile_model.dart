import '../../domain/entities/account_type.dart';
import '../../domain/entities/current_user_profile.dart';

class CurrentUserProfileModel {
  final int accountId;
  final String email;
  final String fullName;
  final String phone;
  final AccountType accountType;
  final String status;
  final DateTime? lastLogin;

  const CurrentUserProfileModel({
    required this.accountId,
    required this.email,
    required this.fullName,
    required this.phone,
    required this.accountType,
    required this.status,
    this.lastLogin,
  });

  factory CurrentUserProfileModel.fromJson(Object? rawJson) {
    if (rawJson is! Map<String, dynamic>) {
      throw Exception('Invalid profile response data');
    }

    return CurrentUserProfileModel(
      accountId: rawJson['id'] as int? ?? rawJson['accountId'] as int? ?? 0,
      email: rawJson['email'] as String? ?? '',
      fullName: rawJson['fullName'] as String? ?? '',
      phone: rawJson['phone'] as String? ?? '',
      accountType: AccountTypeX.fromApiValue(
        rawJson['accountType'] as String? ?? '',
      ),
      status: rawJson['status'] as String? ?? '',
      lastLogin: _dateTimeValue(rawJson['lastLogin']),
    );
  }

  CurrentUserProfile toEntity() {
    return CurrentUserProfile(
      accountId: accountId,
      email: email,
      fullName: fullName,
      phone: phone,
      accountType: accountType,
      status: status,
      lastLogin: lastLogin,
    );
  }

  static DateTime? _dateTimeValue(Object? value) {
    if (value is DateTime) {
      return value;
    }

    if (value is String && value.trim().isNotEmpty) {
      return DateTime.tryParse(value);
    }

    return null;
  }
}

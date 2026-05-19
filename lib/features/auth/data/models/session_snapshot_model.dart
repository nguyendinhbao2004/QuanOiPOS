import '../../domain/entities/account_type.dart';

class SessionSnapshot {
  final int accountId;
  final String email;
  final String fullName;
  final AccountType accountType;

  const SessionSnapshot({
    required this.accountId,
    required this.email,
    required this.fullName,
    required this.accountType,
  });

  Map<String, dynamic> toJson() {
    return {
      'accountId': accountId,
      'email': email,
      'fullName': fullName,
      'accountType': accountType.name,
    };
  }

  factory SessionSnapshot.fromJson(Map<String, dynamic> json) {
    return SessionSnapshot(
      accountId: json['accountId'] as int? ?? 0,
      email: json['email'] as String? ?? '',
      fullName: json['fullName'] as String? ?? '',
      accountType: AccountTypeX.fromApiValue(json['accountType'] as String? ?? ''),
    );
  }
}

import '../../domain/entities/account_type.dart';

enum AuthStatus {
  bootstrapping,
  unauthenticated,
  authenticating,
  authenticated,
  failure,
}

class AuthState {
  final AuthStatus status;
  final int? accountId;
  final AccountType? accountType;
  final String? errorMessage;
  final String? fullName;
  final String? email;
  final String? phone;
  final bool sessionRestored;

  const AuthState({
    required this.status,
    this.accountId,
    this.accountType,
    this.errorMessage,
    this.fullName,
    this.email,
    this.phone,
    this.sessionRestored = false,
  });

  const AuthState.bootstrapping()
    : status = AuthStatus.bootstrapping,
      accountId = null,
      accountType = null,
      errorMessage = null,
      fullName = null,
      email = null,
      phone = null,
      sessionRestored = false;

  const AuthState.unauthenticated()
    : status = AuthStatus.unauthenticated,
      accountId = null,
      accountType = null,
      errorMessage = null,
      fullName = null,
      email = null,
      phone = null,
      sessionRestored = false;

  bool get isLoading =>
      status == AuthStatus.authenticating || status == AuthStatus.bootstrapping;

  bool get isAuthenticated => status == AuthStatus.authenticated;

  bool get isBootstrapping => status == AuthStatus.bootstrapping;

  AuthState copyWith({
    AuthStatus? status,
    int? accountId,
    AccountType? accountType,
    String? errorMessage,
    String? fullName,
    String? email,
    String? phone,
    bool? sessionRestored,
    bool clearError = false,
  }) {
    return AuthState(
      status: status ?? this.status,
      accountId: accountId ?? this.accountId,
      accountType: accountType ?? this.accountType,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      fullName: fullName ?? this.fullName,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      sessionRestored: sessionRestored ?? this.sessionRestored,
    );
  }
}

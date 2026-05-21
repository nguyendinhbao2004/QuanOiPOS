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
  final AccountType? accountType;
  final String? errorMessage;
  final String? fullName;
  final String? email;
  final bool sessionRestored;

  const AuthState({
    required this.status,
    this.accountType,
    this.errorMessage,
    this.fullName,
    this.email,
    this.sessionRestored = false,
  });

  const AuthState.bootstrapping()
    : status = AuthStatus.bootstrapping,
      accountType = null,
      errorMessage = null,
      fullName = null,
      email = null,
      sessionRestored = false;

  const AuthState.unauthenticated()
    : status = AuthStatus.unauthenticated,
      accountType = null,
      errorMessage = null,
      fullName = null,
      email = null,
      sessionRestored = false;

  bool get isLoading =>
      status == AuthStatus.authenticating || status == AuthStatus.bootstrapping;

  bool get isAuthenticated => status == AuthStatus.authenticated;

  bool get isBootstrapping => status == AuthStatus.bootstrapping;

  AuthState copyWith({
    AuthStatus? status,
    AccountType? accountType,
    String? errorMessage,
    String? fullName,
    String? email,
    bool? sessionRestored,
    bool clearError = false,
  }) {
    return AuthState(
      status: status ?? this.status,
      accountType: accountType ?? this.accountType,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      fullName: fullName ?? this.fullName,
      email: email ?? this.email,
      sessionRestored: sessionRestored ?? this.sessionRestored,
    );
  }
}

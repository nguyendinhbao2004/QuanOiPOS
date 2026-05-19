import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/account_type.dart';
import '../providers/auth_providers.dart';
import 'auth_state.dart';

class AuthNotifier extends Notifier<AuthState> {
  static const _sessionRestoreTimeout = Duration(seconds: 8);

  bool _bootstrapStarted = false;

  @override
  AuthState build() {
    Future.microtask(initializeSession);
    return const AuthState.bootstrapping();
  }

  Future<void> initializeSession() async {
    if (_bootstrapStarted || state.status != AuthStatus.bootstrapping) {
      return;
    }

    _bootstrapStarted = true;

    try {
      final restoreUseCase = ref.read(restoreSessionUseCaseProvider);
      final result = await restoreUseCase().timeout(_sessionRestoreTimeout);

      if (result != null) {
        state = AuthState(
          status: AuthStatus.authenticated,
          accountType: result.accountType,
          fullName: result.fullName,
          email: result.email,
          sessionRestored: true,
        );
      } else {
        state = const AuthState.unauthenticated();
      }
    } on TimeoutException {
      state = const AuthState.unauthenticated();
    } catch (error) {
      state = const AuthState.unauthenticated();
    }
  }

  Future<void> login({required String email, required String password}) async {
    state = state.copyWith(status: AuthStatus.authenticating, clearError: true);

    try {
      final loginUseCase = ref.read(loginUseCaseProvider);
      final result = await loginUseCase(email: email, password: password);

      state = AuthState(
        status: AuthStatus.authenticated,
        accountType: result.accountType,
        fullName: result.fullName,
        email: result.email,
        sessionRestored: false,
      );
    } catch (error) {
      state = state.copyWith(
        status: AuthStatus.failure,
        accountType: null,
        errorMessage: error.toString().replaceFirst('Exception: ', ''),
      );
    }
  }

  Future<void> logout() async {
    final logoutUseCase = ref.read(logoutUseCaseProvider);
    await logoutUseCase();
    state = const AuthState.unauthenticated();
  }

  void clearError() {
    if (state.errorMessage != null) {
      state = state.copyWith(clearError: true);
      if (state.status == AuthStatus.failure) {
        state = state.copyWith(status: AuthStatus.unauthenticated);
      }
    }
  }

  bool get isSuperAdmin => state.accountType == AccountType.superAdmin;
}

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/auth_providers.dart';
import 'register_state.dart';

class RegisterNotifier extends Notifier<RegisterState> {
  @override
  RegisterState build() {
    return const RegisterState.initial();
  }

  Future<void> submitDetails({
    required String email,
    required String password,
    required String fullName,
  }) async {
    final normalizedEmail = email.trim();
    state = RegisterState(
      step: RegisterStep.details,
      status: RegisterStatus.submitting,
      email: normalizedEmail,
    );

    try {
      final registerUseCase = ref.read(registerUseCaseProvider);
      await registerUseCase(
        email: normalizedEmail,
        password: password,
        fullName: fullName.trim(),
      );

      state = RegisterState(
        step: RegisterStep.otp,
        status: RegisterStatus.awaitingOtp,
        email: normalizedEmail,
      );
    } catch (error) {
      state = RegisterState(
        step: RegisterStep.details,
        status: RegisterStatus.failure,
        email: normalizedEmail,
        errorMessage: _cleanError(error),
      );
    }
  }

  Future<void> confirmOtp(String otpCode) async {
    final email = state.email;
    if (email == null || email.isEmpty) {
      state = state.copyWith(
        step: RegisterStep.details,
        status: RegisterStatus.failure,
        errorMessage: 'Email đăng ký không hợp lệ',
      );
      return;
    }

    state = state.copyWith(
      step: RegisterStep.otp,
      status: RegisterStatus.confirming,
      clearError: true,
    );

    try {
      final confirmUseCase = ref.read(confirmRegistrationUseCaseProvider);
      await confirmUseCase(email: email, otpCode: otpCode.trim());

      state = state.copyWith(
        step: RegisterStep.otp,
        status: RegisterStatus.success,
        clearError: true,
      );
    } catch (error) {
      state = state.copyWith(
        step: RegisterStep.otp,
        status: RegisterStatus.failure,
        errorMessage: _cleanError(error),
      );
    }
  }

  void backToDetails() {
    state = state.copyWith(
      step: RegisterStep.details,
      status: RegisterStatus.idle,
      clearError: true,
    );
  }

  void reset() {
    state = const RegisterState.initial();
  }

  String _cleanError(Object error) {
    return error.toString().replaceFirst('Exception: ', '');
  }
}

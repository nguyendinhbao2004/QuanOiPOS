enum RegisterStep { details, otp }

enum RegisterStatus {
  idle,
  submitting,
  awaitingOtp,
  confirming,
  success,
  failure,
}

class RegisterState {
  final RegisterStep step;
  final RegisterStatus status;
  final String? email;
  final String? errorMessage;

  const RegisterState({
    required this.step,
    required this.status,
    this.email,
    this.errorMessage,
  });

  const RegisterState.initial()
    : step = RegisterStep.details,
      status = RegisterStatus.idle,
      email = null,
      errorMessage = null;

  bool get isLoading {
    return status == RegisterStatus.submitting ||
        status == RegisterStatus.confirming;
  }

  bool get isAwaitingOtp => step == RegisterStep.otp;

  RegisterState copyWith({
    RegisterStep? step,
    RegisterStatus? status,
    String? email,
    String? errorMessage,
    bool clearError = false,
  }) {
    return RegisterState(
      step: step ?? this.step,
      status: status ?? this.status,
      email: email ?? this.email,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }
}

enum ChangePasswordStatus { idle, submitting, success, failure }

class ChangePasswordState {
  final ChangePasswordStatus status;
  final String? errorMessage;

  const ChangePasswordState({required this.status, this.errorMessage});

  const ChangePasswordState.initial()
    : status = ChangePasswordStatus.idle,
      errorMessage = null;

  bool get isSubmitting => status == ChangePasswordStatus.submitting;

  ChangePasswordState copyWith({
    ChangePasswordStatus? status,
    String? errorMessage,
    bool clearError = false,
  }) {
    return ChangePasswordState(
      status: status ?? this.status,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }
}

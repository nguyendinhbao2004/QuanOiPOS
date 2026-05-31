import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/auth_providers.dart';
import 'change_password_state.dart';

class ChangePasswordNotifier extends Notifier<ChangePasswordState> {
  @override
  ChangePasswordState build() {
    return const ChangePasswordState.initial();
  }

  Future<void> submit({
    required String currentPassword,
    required String newPassword,
  }) async {
    state = const ChangePasswordState(status: ChangePasswordStatus.submitting);

    try {
      final useCase = ref.read(changePasswordUseCaseProvider);
      await useCase(currentPassword: currentPassword, newPassword: newPassword);

      state = const ChangePasswordState(status: ChangePasswordStatus.success);
    } catch (error) {
      state = ChangePasswordState(
        status: ChangePasswordStatus.failure,
        errorMessage: _cleanError(error),
      );
    }
  }

  void reset() {
    state = const ChangePasswordState.initial();
  }

  String _cleanError(Object error) {
    return error.toString().replaceFirst('Exception: ', '');
  }
}

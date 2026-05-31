import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/auth_providers.dart';
import 'profile_state.dart';

class ProfileNotifier extends Notifier<ProfileState> {
  @override
  ProfileState build() {
    return const ProfileState.initial();
  }

  Future<void> load() async {
    state = state.copyWith(status: ProfileStatus.loading, clearError: true);

    try {
      final useCase = ref.read(loadCurrentUserProfileUseCaseProvider);
      final profile = await useCase();
      ref.read(authNotifierProvider.notifier).syncCurrentUserProfile(profile);
      state = ProfileState(status: ProfileStatus.ready, profile: profile);
    } catch (error) {
      state = ProfileState(
        status: ProfileStatus.failure,
        profile: state.profile,
        errorMessage: _cleanError(error),
      );
    }
  }

  Future<void> submit({required String fullName, required String phone}) async {
    state = state.copyWith(status: ProfileStatus.submitting, clearError: true);

    try {
      final useCase = ref.read(updateCurrentUserProfileUseCaseProvider);
      final profile = await useCase(
        fullName: fullName.trim(),
        phone: phone.trim(),
      );
      ref.read(authNotifierProvider.notifier).syncCurrentUserProfile(profile);
      state = ProfileState(status: ProfileStatus.success, profile: profile);
    } catch (error) {
      state = ProfileState(
        status: ProfileStatus.failure,
        profile: state.profile,
        errorMessage: _cleanError(error),
      );
    }
  }

  void reset() {
    state = const ProfileState.initial();
  }

  String _cleanError(Object error) {
    return error.toString().replaceFirst('Exception: ', '');
  }
}

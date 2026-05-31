import '../../domain/entities/current_user_profile.dart';

enum ProfileStatus { initial, loading, ready, submitting, success, failure }

class ProfileState {
  final ProfileStatus status;
  final CurrentUserProfile? profile;
  final String? errorMessage;

  const ProfileState({required this.status, this.profile, this.errorMessage});

  const ProfileState.initial()
    : status = ProfileStatus.initial,
      profile = null,
      errorMessage = null;

  bool get isLoading => status == ProfileStatus.loading;

  bool get isSubmitting => status == ProfileStatus.submitting;

  bool get hasProfile => profile != null;

  ProfileState copyWith({
    ProfileStatus? status,
    CurrentUserProfile? profile,
    String? errorMessage,
    bool clearError = false,
  }) {
    return ProfileState(
      status: status ?? this.status,
      profile: profile ?? this.profile,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }
}

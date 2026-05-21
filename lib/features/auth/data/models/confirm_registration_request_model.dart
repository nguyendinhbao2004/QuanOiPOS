class ConfirmRegistrationRequestModel {
  final String email;
  final String otpCode;

  const ConfirmRegistrationRequestModel({
    required this.email,
    required this.otpCode,
  });

  Map<String, dynamic> toJson() {
    return {'email': email, 'otpCode': otpCode};
  }
}

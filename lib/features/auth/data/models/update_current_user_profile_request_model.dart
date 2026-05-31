class UpdateCurrentUserProfileRequestModel {
  final String fullName;
  final String phone;

  const UpdateCurrentUserProfileRequestModel({
    required this.fullName,
    required this.phone,
  });

  Map<String, dynamic> toJson() {
    return {'fullName': fullName, 'phone': phone};
  }
}

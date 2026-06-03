class CreateStoreRequestModel {
  final String storeName;
  final String phone;
  final String address;

  const CreateStoreRequestModel({
    required this.storeName,
    required this.phone,
    required this.address,
  });

  Map<String, dynamic> toJson() {
    return {'storeName': storeName, 'phone': phone, 'address': address};
  }
}

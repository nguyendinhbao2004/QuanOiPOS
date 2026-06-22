class ProductImageUploadUrlModel {
  final String imageUrl;
  final String uploadUrl;

  const ProductImageUploadUrlModel({
    required this.imageUrl,
    required this.uploadUrl,
  });

  factory ProductImageUploadUrlModel.fromJson(Object? json) {
    if (json is! Map<String, dynamic>) {
      throw const FormatException('Phản hồi URL tải ảnh không hợp lệ');
    }

    final imageUrl = json['imageUrl']?.toString() ?? '';
    final uploadUrl = json['uploadUrl']?.toString() ?? '';
    if (imageUrl.isEmpty || uploadUrl.isEmpty) {
      throw const FormatException('Phản hồi URL tải ảnh không hợp lệ');
    }

    return ProductImageUploadUrlModel(imageUrl: imageUrl, uploadUrl: uploadUrl);
  }
}

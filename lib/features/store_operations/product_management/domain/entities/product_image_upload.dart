import 'dart:typed_data';

class ProductImageUpload {
  static const supportedContentTypes = <String>{
    'image/jpeg',
    'image/png',
    'image/webp',
  };

  final Uint8List bytes;
  final String contentType;

  const ProductImageUpload({required this.bytes, required this.contentType});

  bool get isSupported => supportedContentTypes.contains(contentType);
}

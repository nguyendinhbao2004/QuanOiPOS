import '../../domain/entities/product.dart';
import '../../domain/entities/product_type.dart';

class ProductModel {
  final int id;
  final int storeId;
  final int categoryId;
  final String categoryName;
  final String name;
  final String imageUrl;
  final String description;
  final int preparationTime;
  final int price;
  final ProductType type;
  final bool isSell;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final bool isDeleted;

  const ProductModel({
    required this.id,
    required this.storeId,
    required this.categoryId,
    required this.categoryName,
    required this.name,
    required this.imageUrl,
    required this.description,
    required this.preparationTime,
    required this.price,
    required this.type,
    required this.isSell,
    this.createdAt,
    this.updatedAt,
    required this.isDeleted,
  });

  factory ProductModel.fromJson(Object? json) {
    if (json is! Map<String, dynamic>) {
      throw const FormatException('Invalid product data');
    }

    final category = json['category'];

    return ProductModel(
      id: _intValue(json['id'] ?? json['productId']),
      storeId: _intValue(json['storeId']),
      categoryId: _intValue(
        json['categoryId'] ??
            (category is Map<String, dynamic> ? category['id'] : null),
      ),
      categoryName: _stringValue(
        json['categoryName'] ??
            (category is Map<String, dynamic> ? category['name'] : null),
      ),
      name: _stringValue(json['name'], fallback: 'Sản phẩm'),
      imageUrl: _stringValue(json['imageUrl']),
      description: _stringValue(json['description']),
      preparationTime: _intValue(json['preparationTime']),
      price: _intValue(json['price']),
      type: ProductType.fromValue(json['type']),
      isSell: _boolValue(json['isSell'], fallback: true),
      createdAt: _dateValue(json['createdAt']),
      updatedAt: _dateValue(json['updatedAt']),
      isDeleted: _boolValue(json['isDeleted']),
    );
  }

  static List<ProductModel> listFromJson(Object? json) {
    if (json == null) {
      return const [];
    }

    if (json is List) {
      return json.map(ProductModel.fromJson).toList();
    }

    if (json is Map<String, dynamic>) {
      final items = json['items'] ?? json['products'] ?? json['data'];
      if (items is List) {
        return items.map(ProductModel.fromJson).toList();
      }
    }

    throw const FormatException('Invalid product list data');
  }

  Product toEntity() {
    return Product(
      id: id,
      storeId: storeId,
      categoryId: categoryId,
      categoryName: categoryName,
      name: name,
      imageUrl: imageUrl,
      description: description,
      preparationTime: preparationTime,
      price: price,
      type: type,
      isSell: isSell,
      createdAt: createdAt,
      updatedAt: updatedAt,
      isDeleted: isDeleted,
    );
  }

  static int _intValue(Object? value) {
    if (value is num) {
      return value.toInt();
    }

    if (value is String) {
      return int.tryParse(value) ?? 0;
    }

    return 0;
  }

  static String _stringValue(Object? value, {String fallback = ''}) {
    if (value == null) {
      return fallback;
    }

    final text = value.toString().trim();
    return text.isEmpty ? fallback : text;
  }

  static bool _boolValue(Object? value, {bool fallback = false}) {
    if (value is bool) {
      return value;
    }

    if (value is String) {
      final text = value.toLowerCase();
      if (text == 'true') {
        return true;
      }

      if (text == 'false') {
        return false;
      }
    }

    if (value is num) {
      return value != 0;
    }

    return fallback;
  }

  static DateTime? _dateValue(Object? value) {
    if (value is DateTime) {
      return value;
    }

    if (value is String && value.trim().isNotEmpty) {
      return DateTime.tryParse(value);
    }

    return null;
  }
}

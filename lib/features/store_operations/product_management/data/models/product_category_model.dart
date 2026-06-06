import '../../domain/entities/product_category.dart';

class ProductCategoryModel {
  final int id;
  final int storeId;
  final String name;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final bool isDeleted;

  const ProductCategoryModel({
    required this.id,
    required this.storeId,
    required this.name,
    this.createdAt,
    this.updatedAt,
    required this.isDeleted,
  });

  factory ProductCategoryModel.fromJson(Object? json) {
    if (json is! Map<String, dynamic>) {
      throw const FormatException('Invalid category data');
    }

    return ProductCategoryModel(
      id: _intValue(json['id'] ?? json['categoryId']),
      storeId: _intValue(json['storeId']),
      name: _stringValue(json['name'], fallback: 'Danh mục'),
      createdAt: _dateValue(json['createdAt']),
      updatedAt: _dateValue(json['updatedAt']),
      isDeleted: _boolValue(json['isDeleted']),
    );
  }

  static List<ProductCategoryModel> listFromJson(Object? json) {
    if (json == null) {
      return const [];
    }

    if (json is List) {
      return json.map(ProductCategoryModel.fromJson).toList();
    }

    if (json is Map<String, dynamic>) {
      final items = json['items'] ?? json['categories'] ?? json['data'];
      if (items is List) {
        return items.map(ProductCategoryModel.fromJson).toList();
      }
    }

    throw const FormatException('Invalid category list data');
  }

  ProductCategory toEntity() {
    return ProductCategory(
      id: id,
      storeId: storeId,
      name: name,
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

  static bool _boolValue(Object? value) {
    if (value is bool) {
      return value;
    }

    if (value is String) {
      return value.toLowerCase() == 'true';
    }

    if (value is num) {
      return value != 0;
    }

    return false;
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

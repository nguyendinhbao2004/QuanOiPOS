import '../../domain/entities/product_topping.dart';

class ProductToppingModel {
  final int id;
  final int storeId;
  final String name;
  final int price;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final bool isDeleted;

  const ProductToppingModel({
    required this.id,
    required this.storeId,
    required this.name,
    required this.price,
    this.createdAt,
    this.updatedAt,
    required this.isDeleted,
  });

  factory ProductToppingModel.fromJson(Object? json) {
    if (json is! Map<String, dynamic>) {
      throw const FormatException('Invalid topping data');
    }

    return ProductToppingModel(
      id: _intValue(json['id'] ?? json['toppingId']),
      storeId: _intValue(json['storeId']),
      name: _stringValue(json['name'], fallback: 'Topping'),
      price: _intValue(json['price']),
      createdAt: _dateValue(json['createdAt']),
      updatedAt: _dateValue(json['updatedAt']),
      isDeleted: _boolValue(json['isDeleted']),
    );
  }

  static List<ProductToppingModel> listFromJson(Object? json) {
    if (json == null) {
      return const [];
    }

    if (json is List) {
      return json.map(ProductToppingModel.fromJson).toList();
    }

    if (json is Map<String, dynamic>) {
      final items = json['items'] ?? json['toppings'] ?? json['data'];
      if (items is List) {
        return items.map(ProductToppingModel.fromJson).toList();
      }
    }

    throw const FormatException('Invalid topping list data');
  }

  ProductTopping toEntity() {
    return ProductTopping(
      id: id,
      storeId: storeId,
      name: name,
      price: price,
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

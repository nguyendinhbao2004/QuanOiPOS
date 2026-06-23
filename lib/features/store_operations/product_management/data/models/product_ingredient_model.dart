import '../../domain/entities/product_ingredient.dart';

class ProductIngredientModel {
  final int id;
  final int storeId;
  final String name;
  final int itemType;
  final String unit;
  final double quantity;
  final double minimumStock;
  final double averageUnitCost;
  final double lastImportUnitCost;
  final bool isTrackInventory;
  final bool isLowStock;
  final bool isOutOfStock;
  final int capacity;
  final int currentCapacity;
  final bool isActive;
  final bool isDeleted;

  const ProductIngredientModel({
    required this.id,
    required this.storeId,
    required this.name,
    required this.itemType,
    required this.unit,
    required this.quantity,
    required this.minimumStock,
    required this.averageUnitCost,
    required this.lastImportUnitCost,
    required this.isTrackInventory,
    required this.isLowStock,
    required this.isOutOfStock,
    required this.capacity,
    required this.currentCapacity,
    required this.isActive,
    required this.isDeleted,
  });

  factory ProductIngredientModel.fromJson(Object? json) {
    if (json is! Map<String, dynamic>) {
      throw const FormatException('Invalid ingredient data');
    }

    return ProductIngredientModel(
      id: _intValue(json['id'] ?? json['ingredientId']),
      storeId: _intValue(json['storeId']),
      name: _stringValue(json['name'], fallback: 'Nguyên liệu'),
      itemType: _intValue(json['itemType']),
      unit: _stringValue(json['unit']),
      quantity: _doubleValue(json['quantity']),
      minimumStock: _doubleValue(json['minimumStock']),
      averageUnitCost: _doubleValue(json['averageUnitCost']),
      lastImportUnitCost: _doubleValue(json['lastImportUnitCost']),
      isTrackInventory: _boolValue(json['isTrackInventory']),
      isLowStock: _boolValue(json['isLowStock']),
      isOutOfStock: _boolValue(json['isOutOfStock']),
      capacity: _intValue(json['capacity']),
      currentCapacity: _intValue(json['currentCapacity']),
      isActive: _boolValue(json['isActive'], fallback: true),
      isDeleted: _boolValue(json['isDeleted']),
    );
  }

  static List<ProductIngredientModel> listFromJson(Object? json) {
    if (json == null) {
      return const [];
    }

    if (json is List) {
      return json.map(ProductIngredientModel.fromJson).toList();
    }

    if (json is Map<String, dynamic>) {
      final items = json['items'] ?? json['ingredients'] ?? json['data'];
      if (items is List) {
        return items.map(ProductIngredientModel.fromJson).toList();
      }
    }

    throw const FormatException('Invalid ingredient list data');
  }

  ProductIngredient toEntity() {
    return ProductIngredient(
      id: id,
      storeId: storeId,
      name: name,
      itemType: itemType,
      unit: unit,
      quantity: quantity,
      minimumStock: minimumStock,
      averageUnitCost: averageUnitCost,
      lastImportUnitCost: lastImportUnitCost,
      isTrackInventory: isTrackInventory,
      isLowStock: isLowStock,
      isOutOfStock: isOutOfStock,
      capacity: capacity,
      currentCapacity: currentCapacity,
      isActive: isActive,
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

  static double _doubleValue(Object? value) {
    if (value is num) {
      return value.toDouble();
    }

    if (value is String) {
      return double.tryParse(value) ?? 0;
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
}

import '../../domain/entities/inventory_deduction_mode.dart';
import '../../domain/entities/inventory_item_settings.dart';

class IngredientInventorySettingsModel {
  final int id;
  final double minimumStock;
  final bool isTrackInventory;

  const IngredientInventorySettingsModel({
    required this.id,
    required this.minimumStock,
    required this.isTrackInventory,
  });

  factory IngredientInventorySettingsModel.fromJson(Object? json) {
    final map = _map(json);
    return IngredientInventorySettingsModel(
      id: _int(map['id'] ?? map['ingredientId']),
      minimumStock: _double(map['minimumStock']),
      isTrackInventory: _bool(map['isTrackInventory']),
    );
  }

  static List<IngredientInventorySettingsModel> listFromJson(Object? json) {
    if (json is! List) {
      return const [];
    }

    return json.map(IngredientInventorySettingsModel.fromJson).toList();
  }

  IngredientInventorySettings toEntity() => IngredientInventorySettings(
    ingredientId: id,
    minimumStock: minimumStock,
    isTrackInventory: isTrackInventory,
  );
}

class ProductInventorySettingsModel {
  final int id;
  final double minimumStock;
  final bool isTrackInventory;
  final InventoryDeductionMode inventoryDeductionMode;

  const ProductInventorySettingsModel({
    required this.id,
    required this.minimumStock,
    required this.isTrackInventory,
    required this.inventoryDeductionMode,
  });

  factory ProductInventorySettingsModel.fromJson(Object? json) {
    final map = _map(json);
    return ProductInventorySettingsModel(
      id: _int(map['id'] ?? map['productId']),
      minimumStock: _double(map['minimumStock']),
      isTrackInventory: _bool(map['isTrackInventory']),
      inventoryDeductionMode: InventoryDeductionMode.fromApi(
        map['inventoryDeductionMode'],
      ),
    );
  }

  static List<ProductInventorySettingsModel> listFromJson(Object? json) {
    if (json is! List) {
      return const [];
    }

    return json.map(ProductInventorySettingsModel.fromJson).toList();
  }

  ProductInventorySettings toEntity() => ProductInventorySettings(
    productId: id,
    minimumStock: minimumStock,
    isTrackInventory: isTrackInventory,
    inventoryDeductionMode: inventoryDeductionMode,
  );
}

Map<String, dynamic> _map(Object? value) => value is Map<String, dynamic>
    ? value
    : value is Map
    ? value.map((key, value) => MapEntry(key.toString(), value))
    : <String, dynamic>{};

int _int(Object? value) =>
    value is num ? value.toInt() : int.tryParse(value?.toString() ?? '') ?? 0;

double _double(Object? value) => value is num
    ? value.toDouble()
    : double.tryParse(value?.toString() ?? '') ?? 0;

bool _bool(Object? value) {
  if (value is bool) {
    return value;
  }

  if (value is num) {
    return value != 0;
  }

  return value?.toString().toLowerCase() == 'true';
}

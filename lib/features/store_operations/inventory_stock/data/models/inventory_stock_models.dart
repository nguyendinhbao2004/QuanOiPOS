import '../../domain/entities/inventory_stock.dart';

class InventoryStockItemModel {
  final Map<String, dynamic> map;
  final InventoryStockItemType type;

  const InventoryStockItemModel._(this.map, this.type);

  factory InventoryStockItemModel.fromJson(
    Object? json,
    InventoryStockItemType type,
  ) => InventoryStockItemModel._(_map(json), type);

  static List<InventoryStockItemModel> listFromJson(
    Object? json,
    InventoryStockItemType type,
  ) => json is List
      ? json
            .map((value) => InventoryStockItemModel.fromJson(value, type))
            .toList()
      : const [];

  InventoryStockItem toEntity() => InventoryStockItem(
    type: type,
    id: _int(map['id']),
    storeId: _int(map['storeId']),
    name: _string(map['name']),
    unit: type == InventoryStockItemType.product ? 'sp' : _string(map['unit']),
    quantity: _double(map['quantity']),
    minimumStock: _double(map['minimumStock']),
    averageUnitCost: _double(map['averageUnitCost']),
    lastImportUnitCost: _double(map['lastImportUnitCost']),
    isTrackInventory: _bool(map['isTrackInventory']),
    inventoryDeductionMode: type == InventoryStockItemType.product
        ? _nullableString(map['inventoryDeductionMode'])
        : null,
    isLowStock: _bool(map['isLowStock']),
    isOutOfStock: _bool(map['isOutOfStock']),
  );
}

class InventoryMovementModel {
  final Map<String, dynamic> map;

  const InventoryMovementModel._(this.map);

  factory InventoryMovementModel.fromJson(Object? json) =>
      InventoryMovementModel._(_map(json));

  static List<InventoryMovementModel> listFromJson(Object? json) => json is List
      ? json.map(InventoryMovementModel.fromJson).toList()
      : const [];

  InventoryMovement toEntity() => InventoryMovement(
    id: _int(map['id']),
    ingredientId: _nullableInt(map['ingredientId']),
    productId: _nullableInt(map['productId']),
    type: _string(map['type']),
    reason: _string(map['reason']),
    quantity: _double(map['quantity']),
    requestedQuantity: _double(map['requestedQuantity']),
    shortageQuantity: _double(map['shortageQuantity']),
    unitCost: _double(map['unitCost']),
    totalCost: _double(map['totalCost']),
    orderId: _nullableInt(map['orderId']),
    orderItemId: _nullableInt(map['orderItemId']),
    note: _nullableString(map['note']),
    destinationName: _nullableString(map['destinationName']),
    occurredAt: _date(map['occurredAt']),
  );
}

Map<String, dynamic> _map(Object? value) => value is Map<String, dynamic>
    ? value
    : value is Map
    ? value.map((key, value) => MapEntry(key.toString(), value))
    : <String, dynamic>{};

int _int(Object? value, [int fallback = 0]) => value is num
    ? value.toInt()
    : int.tryParse(value?.toString() ?? '') ?? fallback;

int? _nullableInt(Object? value) {
  if (value == null) return null;
  if (value is num) return value.toInt();
  return int.tryParse(value.toString());
}

double _double(Object? value, [double fallback = 0]) => value is num
    ? value.toDouble()
    : double.tryParse(value?.toString() ?? '') ?? fallback;

bool _bool(Object? value) => value is bool
    ? value
    : value is num
    ? value != 0
    : value?.toString().toLowerCase() == 'true';

String _string(Object? value, [String fallback = '']) {
  final text = value?.toString().trim();
  return text == null || text.isEmpty ? fallback : text;
}

String? _nullableString(Object? value) {
  final text = value?.toString().trim();
  return text == null || text.isEmpty ? null : text;
}

DateTime? _date(Object? value) =>
    value == null ? null : DateTime.tryParse(value.toString());

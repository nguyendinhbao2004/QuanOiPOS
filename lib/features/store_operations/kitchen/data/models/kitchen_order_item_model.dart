import '../../domain/entities/kitchen_order_item.dart';

class KitchenOrderItemModel {
  final int orderItemId;
  final int orderId;
  final int storeId;
  final int? tableSessionId;
  final int? tableId;
  final String tableName;
  final int productId;
  final String productName;
  final int? variantId;
  final String? variantName;
  final String? note;
  final int status;
  final DateTime? orderedAt;
  final DateTime? updatedAt;
  final List<KitchenOrderItemToppingModel> toppings;

  const KitchenOrderItemModel({
    required this.orderItemId,
    required this.orderId,
    required this.storeId,
    required this.tableSessionId,
    required this.tableId,
    required this.tableName,
    required this.productId,
    required this.productName,
    required this.variantId,
    required this.variantName,
    required this.note,
    required this.status,
    required this.orderedAt,
    required this.updatedAt,
    required this.toppings,
  });

  factory KitchenOrderItemModel.fromJson(Object? json) {
    final map = json as Map<String, dynamic>? ?? const <String, dynamic>{};
    return KitchenOrderItemModel(
      orderItemId: _readInt(map, 'orderItemId') ?? 0,
      orderId: _readInt(map, 'orderId') ?? 0,
      storeId: _readInt(map, 'storeId') ?? 0,
      tableSessionId: _readInt(map, 'tableSessionId'),
      tableId: _readInt(map, 'tableId'),
      tableName: _readString(map, 'tableName') ?? '',
      productId: _readInt(map, 'productId') ?? 0,
      productName: _readString(map, 'productName') ?? '',
      variantId: _readInt(map, 'variantId'),
      variantName: _readString(map, 'variantName'),
      note: _readString(map, 'note'),
      status: _readInt(map, 'status') ?? 1,
      orderedAt: _readDateTime(map, 'orderedAt'),
      updatedAt: _readDateTime(map, 'updatedAt'),
      toppings: KitchenOrderItemToppingModel.listFromJson(map['toppings']),
    );
  }

  static List<KitchenOrderItemModel> listFromJson(Object? json) {
    if (json is! List) return const [];
    return json.map(KitchenOrderItemModel.fromJson).toList();
  }

  KitchenOrderItem toEntity() {
    return KitchenOrderItem(
      orderItemId: orderItemId,
      orderId: orderId,
      storeId: storeId,
      tableSessionId: tableSessionId,
      tableId: tableId,
      tableName: tableName,
      productId: productId,
      productName: productName,
      variantId: variantId,
      variantName: variantName,
      note: note,
      status: KitchenOrderItemStatus.fromValue(status),
      orderedAt: orderedAt,
      updatedAt: updatedAt,
      toppings: toppings.map((topping) => topping.toEntity()).toList(),
    );
  }
}

class KitchenOrderItemToppingModel {
  final int id;
  final int orderItemId;
  final int toppingId;
  final String toppingName;
  final int quantity;
  final num unitPrice;
  final num totalPrice;

  const KitchenOrderItemToppingModel({
    required this.id,
    required this.orderItemId,
    required this.toppingId,
    required this.toppingName,
    required this.quantity,
    required this.unitPrice,
    required this.totalPrice,
  });

  factory KitchenOrderItemToppingModel.fromJson(Object? json) {
    final map = json as Map<String, dynamic>? ?? const <String, dynamic>{};
    return KitchenOrderItemToppingModel(
      id: _readInt(map, 'id') ?? 0,
      orderItemId: _readInt(map, 'orderItemId') ?? 0,
      toppingId: _readInt(map, 'toppingId') ?? 0,
      toppingName: _readString(map, 'toppingName') ?? '',
      quantity: _readInt(map, 'quantity') ?? 0,
      unitPrice: _readNum(map, 'unitPrice') ?? 0,
      totalPrice: _readNum(map, 'totalPrice') ?? 0,
    );
  }

  static List<KitchenOrderItemToppingModel> listFromJson(Object? json) {
    if (json is! List) return const [];
    return json.map(KitchenOrderItemToppingModel.fromJson).toList();
  }

  KitchenOrderItemTopping toEntity() {
    return KitchenOrderItemTopping(
      id: id,
      orderItemId: orderItemId,
      toppingId: toppingId,
      toppingName: toppingName,
      quantity: quantity,
      unitPrice: unitPrice,
      totalPrice: totalPrice,
    );
  }
}

class KitchenItemFailedUpdateModel {
  final int orderItemId;
  final String message;

  const KitchenItemFailedUpdateModel({
    required this.orderItemId,
    required this.message,
  });

  factory KitchenItemFailedUpdateModel.fromJson(Object? json) {
    final map = json as Map<String, dynamic>? ?? const <String, dynamic>{};
    return KitchenItemFailedUpdateModel(
      orderItemId: _readInt(map, 'orderItemId') ?? 0,
      message: _readString(map, 'message') ?? 'Không thể cập nhật món',
    );
  }

  static List<KitchenItemFailedUpdateModel> listFromJson(Object? json) {
    if (json is! List) return const [];
    return json.map(KitchenItemFailedUpdateModel.fromJson).toList();
  }

  KitchenItemFailedUpdate toEntity() {
    return KitchenItemFailedUpdate(
      orderItemId: orderItemId,
      message: message,
    );
  }
}

class KitchenBulkUpdateResultModel {
  final List<KitchenOrderItemModel> updatedItems;
  final List<KitchenItemFailedUpdateModel> failedItems;

  const KitchenBulkUpdateResultModel({
    required this.updatedItems,
    required this.failedItems,
  });

  factory KitchenBulkUpdateResultModel.fromJson(Object? json) {
    final map = json as Map<String, dynamic>? ?? const <String, dynamic>{};
    return KitchenBulkUpdateResultModel(
      updatedItems: KitchenOrderItemModel.listFromJson(
        map['updatedItems'] ?? map['UpdatedItems'],
      ),
      failedItems: KitchenItemFailedUpdateModel.listFromJson(
        map['failedItems'] ?? map['FailedItems'],
      ),
    );
  }

  KitchenBulkUpdateResult toEntity() {
    return KitchenBulkUpdateResult(
      updatedItems: updatedItems.map((item) => item.toEntity()).toList(),
      failedItems: failedItems.map((item) => item.toEntity()).toList(),
    );
  }
}

int? _readInt(Map<String, dynamic> json, String key) {
  final value = json[key] ?? json[_upperFirst(key)];
  if (value is int) return value;
  if (value is num) return value.toInt();
  return int.tryParse(value?.toString() ?? '');
}

num? _readNum(Map<String, dynamic> json, String key) {
  final value = json[key] ?? json[_upperFirst(key)];
  if (value is num) return value;
  return num.tryParse(value?.toString() ?? '');
}

String? _readString(Map<String, dynamic> json, String key) {
  final value = json[key] ?? json[_upperFirst(key)];
  final text = value?.toString().trim();
  return text == null || text.isEmpty ? null : text;
}

DateTime? _readDateTime(Map<String, dynamic> json, String key) {
  final value = _readString(json, key);
  return value == null ? null : DateTime.tryParse(value);
}

String _upperFirst(String value) {
  if (value.isEmpty) return value;
  return value[0].toUpperCase() + value.substring(1);
}

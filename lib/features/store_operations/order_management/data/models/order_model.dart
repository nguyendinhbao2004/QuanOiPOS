import '../../domain/entities/order.dart';

class OrderModel {
  final Order entity;

  const OrderModel(this.entity);

  factory OrderModel.fromJson(Object? json) {
    if (json is! Map<String, dynamic>) {
      throw const FormatException('Invalid order data');
    }

    final orderId = _intValue(json['id'] ?? json['orderId']);
    return OrderModel(
      Order(
        id: orderId,
        storeId: _intValue(json['storeId']),
        tableSessionId: _intValue(json['tableSessionId']),
        shiftSessionId: _nullableInt(json['shiftSessionId']),
        type: _orderType(json['orderType']),
        status: _orderStatus(json['status']),
        customerId: _nullableInt(json['customerId']),
        totalAmount: _intValue(json['totalAmount']),
        finalAmount: _nullableInt(json['finalAmount']),
        discountAmount: _nullableInt(json['discountAmount']),
        paidAmount: _nullableInt(json['paidAmount']),
        createdByAccountId: _nullableInt(json['createdByAccountId']),
        createdAt: _dateValue(json['createdAt']),
        items: _items(json['items'], orderId),
      ),
    );
  }

  static List<OrderModel> listFromJson(Object? json) {
    if (json == null) return const [];
    if (json is List) return json.map(OrderModel.fromJson).toList();
    if (json is Map<String, dynamic>) {
      final items = json['items'] ?? json['orders'] ?? json['data'];
      if (items is List) return items.map(OrderModel.fromJson).toList();
    }
    throw const FormatException('Invalid order list data');
  }

  Order toEntity() => entity;

  static List<OrderItem> _items(Object? value, int orderId) {
    if (value is! List) return const [];
    return value.whereType<Map<String, dynamic>>().map((json) {
      final itemId = _intValue(json['id'] ?? json['orderItemId']);
      return OrderItem(
        id: itemId,
        orderId: _intValue(json['orderId']) == 0
            ? orderId
            : _intValue(json['orderId']),
        productId: _intValue(json['productId']),
        variantId: _nullableInt(json['variantId']),
        productName: _stringValue(
          json['productNameSnapshot'] ?? json['productName'],
          fallback: 'Sản phẩm',
        ),
        variantName: _stringValue(
          json['variantNameSnapshot'] ?? json['variantName'],
        ),
        note: _stringValue(json['note']),
        status: _itemStatus(json['status']),
        unitPrice: _intValue(json['unitPrice']),
        finalPrice: _nullableInt(json['finalPrice']),
        toppings: _toppings(json['toppings'], itemId),
      );
    }).toList();
  }

  static List<OrderItemTopping> _toppings(Object? value, int itemId) {
    if (value is! List) return const [];
    return value.whereType<Map<String, dynamic>>().map((json) {
      final quantity = _intValue(json['quantity']);
      final unitPrice = _intValue(json['unitPrice']);
      final totalPrice = _intValue(json['totalPrice']);
      return OrderItemTopping(
        id: _intValue(json['id']),
        orderItemId: _intValue(json['orderItemId']) == 0
            ? itemId
            : _intValue(json['orderItemId']),
        toppingId: _intValue(json['toppingId']),
        name: _stringValue(
          json['toppingNameSnapshot'] ?? json['name'],
          fallback: 'Topping',
        ),
        quantity: quantity,
        unitPrice: unitPrice,
        totalPrice: totalPrice == 0 ? quantity * unitPrice : totalPrice,
      );
    }).toList();
  }

  static OrderType _orderType(Object? value) {
    final text = value?.toString().toLowerCase();
    return switch (text) {
      '1' || 'dinein' || 'dine_in' => OrderType.dineIn,
      '2' || 'qr' => OrderType.qr,
      '3' || 'takeaway' || 'take_away' => OrderType.takeAway,
      _ => OrderType.unknown,
    };
  }

  static OrderStatus _orderStatus(Object? value) => switch (_intValue(value)) {
    1 => OrderStatus.pending,
    2 => OrderStatus.completed,
    3 => OrderStatus.cancelled,
    _ => OrderStatus.unknown,
  };

  static OrderItemStatus _itemStatus(Object? value) =>
      switch (_intValue(value)) {
        1 => OrderItemStatus.pending,
        2 => OrderItemStatus.preparing,
        3 => OrderItemStatus.ready,
        4 => OrderItemStatus.cancelled,
        _ => OrderItemStatus.unknown,
      };

  static int _intValue(Object? value) {
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }

  static int? _nullableInt(Object? value) {
    if (value == null) return null;
    return _intValue(value);
  }

  static String _stringValue(Object? value, {String fallback = ''}) {
    final text = value?.toString().trim() ?? '';
    return text.isEmpty ? fallback : text;
  }

  static DateTime? _dateValue(Object? value) {
    if (value is DateTime) return value;
    return value is String ? DateTime.tryParse(value) : null;
  }
}

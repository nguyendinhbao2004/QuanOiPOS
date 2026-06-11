enum OrderType { dineIn, qr, takeAway, unknown }

enum OrderStatus { pending, completed, cancelled, unknown }

enum OrderItemStatus { pending, preparing, ready, cancelled, unknown }

extension OrderStatusX on OrderStatus {
  String get label => switch (this) {
    OrderStatus.pending => 'Đang xử lý',
    OrderStatus.completed => 'Hoàn thành',
    OrderStatus.cancelled => 'Đã hủy',
    OrderStatus.unknown => 'Không rõ',
  };
}

extension OrderItemStatusX on OrderItemStatus {
  String get label => switch (this) {
    OrderItemStatus.pending => 'Chờ chế biến',
    OrderItemStatus.preparing => 'Đang chế biến',
    OrderItemStatus.ready => 'Sẵn sàng',
    OrderItemStatus.cancelled => 'Đã hủy',
    OrderItemStatus.unknown => 'Không rõ',
  };
}

class OrderItemTopping {
  final int id;
  final int orderItemId;
  final int toppingId;
  final String name;
  final int quantity;
  final int unitPrice;
  final int totalPrice;

  const OrderItemTopping({
    required this.id,
    required this.orderItemId,
    required this.toppingId,
    required this.name,
    required this.quantity,
    required this.unitPrice,
    required this.totalPrice,
  });
}

class OrderItem {
  final int id;
  final int orderId;
  final int productId;
  final int? variantId;
  final String productName;
  final String variantName;
  final String note;
  final OrderItemStatus status;
  final int unitPrice;
  final int? finalPrice;
  final List<OrderItemTopping> toppings;

  const OrderItem({
    required this.id,
    required this.orderId,
    required this.productId,
    this.variantId,
    required this.productName,
    required this.variantName,
    required this.note,
    required this.status,
    required this.unitPrice,
    this.finalPrice,
    this.toppings = const [],
  });

  int get displayPrice =>
      (finalPrice ?? unitPrice) +
      toppings.fold(0, (sum, topping) => sum + topping.totalPrice);
}

class Order {
  final int id;
  final int storeId;
  final int tableSessionId;
  final int? shiftSessionId;
  final OrderType type;
  final OrderStatus status;
  final int? customerId;
  final int totalAmount;
  final int? finalAmount;
  final int? discountAmount;
  final int? paidAmount;
  final int? createdByAccountId;
  final DateTime? createdAt;
  final List<OrderItem> items;

  const Order({
    required this.id,
    required this.storeId,
    required this.tableSessionId,
    this.shiftSessionId,
    required this.type,
    required this.status,
    this.customerId,
    required this.totalAmount,
    this.finalAmount,
    this.discountAmount,
    this.paidAmount,
    this.createdByAccountId,
    this.createdAt,
    this.items = const [],
  });

  int get payableAmount => finalAmount ?? totalAmount;

  bool get isFullyPaid => (paidAmount ?? 0) >= payableAmount;

  bool get canPay => status != OrderStatus.cancelled && !isFullyPaid;
}

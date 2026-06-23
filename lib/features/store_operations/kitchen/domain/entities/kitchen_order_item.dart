enum KitchenOrderItemStatus {
  pending(1),
  preparing(2),
  ready(3),
  cancelled(4);

  final int value;

  const KitchenOrderItemStatus(this.value);

  static KitchenOrderItemStatus fromValue(int value) {
    return KitchenOrderItemStatus.values.firstWhere(
      (status) => status.value == value,
      orElse: () => KitchenOrderItemStatus.pending,
    );
  }
}

class KitchenOrderItem {
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
  final KitchenOrderItemStatus status;
  final DateTime? orderedAt;
  final DateTime? updatedAt;
  final List<KitchenOrderItemTopping> toppings;

  const KitchenOrderItem({
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

  String get displayName {
    final variant = variantName?.trim();
    if (variant == null || variant.isEmpty) return productName;
    return '$productName - $variant';
  }
}

class KitchenOrderItemTopping {
  final int id;
  final int orderItemId;
  final int toppingId;
  final String toppingName;
  final int quantity;
  final num unitPrice;
  final num totalPrice;

  const KitchenOrderItemTopping({
    required this.id,
    required this.orderItemId,
    required this.toppingId,
    required this.toppingName,
    required this.quantity,
    required this.unitPrice,
    required this.totalPrice,
  });
}

class KitchenItemFailedUpdate {
  final int orderItemId;
  final String message;

  const KitchenItemFailedUpdate({
    required this.orderItemId,
    required this.message,
  });
}

class KitchenBulkUpdateResult {
  final List<KitchenOrderItem> updatedItems;
  final List<KitchenItemFailedUpdate> failedItems;

  const KitchenBulkUpdateResult({
    required this.updatedItems,
    required this.failedItems,
  });
}

class KitchenItemFilter {
  final int? productId;
  final int? tableId;
  final int? tableSessionId;
  final KitchenOrderItemStatus? status;
  final DateTime? orderedFrom;
  final DateTime? orderedTo;

  const KitchenItemFilter({
    this.productId,
    this.tableId,
    this.tableSessionId,
    this.status,
    this.orderedFrom,
    this.orderedTo,
  });

  KitchenItemFilter copyWith({
    int? productId,
    int? tableId,
    int? tableSessionId,
    KitchenOrderItemStatus? status,
    DateTime? orderedFrom,
    DateTime? orderedTo,
    bool clearProduct = false,
    bool clearTable = false,
    bool clearTableSession = false,
    bool clearStatus = false,
    bool clearOrderedFrom = false,
    bool clearOrderedTo = false,
  }) {
    return KitchenItemFilter(
      productId: clearProduct ? null : (productId ?? this.productId),
      tableId: clearTable ? null : (tableId ?? this.tableId),
      tableSessionId: clearTableSession
          ? null
          : (tableSessionId ?? this.tableSessionId),
      status: clearStatus ? null : (status ?? this.status),
      orderedFrom: clearOrderedFrom ? null : (orderedFrom ?? this.orderedFrom),
      orderedTo: clearOrderedTo ? null : (orderedTo ?? this.orderedTo),
    );
  }
}

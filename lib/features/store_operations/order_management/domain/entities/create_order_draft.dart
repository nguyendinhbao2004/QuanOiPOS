class CreateOrderToppingDraft {
  final int toppingId;
  final int quantity;

  const CreateOrderToppingDraft({
    required this.toppingId,
    required this.quantity,
  });
}

class CreateOrderItemDraft {
  final int productId;
  final int? variantId;
  final String? note;
  final List<CreateOrderToppingDraft> toppings;

  const CreateOrderItemDraft({
    required this.productId,
    this.variantId,
    this.note,
    this.toppings = const [],
  });
}

class CreateOrderDraft {
  final int storeId;
  final int tableSessionId;
  final List<CreateOrderItemDraft> items;

  const CreateOrderDraft({
    required this.storeId,
    required this.tableSessionId,
    required this.items,
  });
}

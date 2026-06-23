import '../../../product_management/domain/entities/product.dart';
import '../../../product_management/domain/entities/product_category.dart';
import '../../../product_management/domain/entities/product_topping.dart';
import '../../../product_management/domain/entities/product_variant_draft.dart';
import '../../domain/entities/order.dart';
import '../../domain/entities/session_invoice.dart';

enum OrderLoadStatus { initial, loading, ready, forbidden, error }

class OrderSessionAccess {
  final int storeId;
  final int tableSessionId;
  final bool isSessionOpen;
  final bool canViewOrder;
  final bool canCreateOrder;
  final bool canCloseSession;

  const OrderSessionAccess({
    required this.storeId,
    required this.tableSessionId,
    required this.isSessionOpen,
    required this.canViewOrder,
    required this.canCreateOrder,
    this.canCloseSession = false,
  });

  @override
  bool operator ==(Object other) =>
      other is OrderSessionAccess &&
      storeId == other.storeId &&
      tableSessionId == other.tableSessionId &&
      isSessionOpen == other.isSessionOpen &&
      canViewOrder == other.canViewOrder &&
      canCreateOrder == other.canCreateOrder &&
      canCloseSession == other.canCloseSession;

  @override
  int get hashCode => Object.hash(
    storeId,
    tableSessionId,
    isSessionOpen,
    canViewOrder,
    canCreateOrder,
    canCloseSession,
  );
}

enum SessionCheckoutStatus {
  idle,
  creatingInvoice,
  confirmingPayment,
  awaitingQrPayment,
  closingSession,
  completed,
  error,
}

class SessionCheckoutState {
  final SessionCheckoutStatus status;
  final SessionInvoice? invoice;
  final bool paymentConfirmed;
  final String? errorMessage;

  const SessionCheckoutState({
    required this.status,
    this.invoice,
    this.paymentConfirmed = false,
    this.errorMessage,
  });

  const SessionCheckoutState.idle() : this(status: SessionCheckoutStatus.idle);

  bool get isProcessing =>
      status == SessionCheckoutStatus.creatingInvoice ||
      status == SessionCheckoutStatus.confirmingPayment ||
      status == SessionCheckoutStatus.closingSession;

  SessionCheckoutState copyWith({
    SessionCheckoutStatus? status,
    SessionInvoice? invoice,
    bool? paymentConfirmed,
    String? errorMessage,
    bool clearError = false,
  }) {
    return SessionCheckoutState(
      status: status ?? this.status,
      invoice: invoice ?? this.invoice,
      paymentConfirmed: paymentConfirmed ?? this.paymentConfirmed,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }
}

class OrderListState {
  final OrderLoadStatus status;
  final List<Order> orders;
  final String? errorMessage;

  const OrderListState({
    required this.status,
    this.orders = const [],
    this.errorMessage,
  });

  const OrderListState.initial() : this(status: OrderLoadStatus.initial);

  OrderListState copyWith({
    OrderLoadStatus? status,
    List<Order>? orders,
    String? errorMessage,
    bool clearError = false,
  }) {
    return OrderListState(
      status: status ?? this.status,
      orders: orders ?? this.orders,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }
}

class OrderDetailAccess {
  final int orderId;
  final bool canViewOrder;

  const OrderDetailAccess({required this.orderId, required this.canViewOrder});

  @override
  bool operator ==(Object other) =>
      other is OrderDetailAccess &&
      orderId == other.orderId &&
      canViewOrder == other.canViewOrder;

  @override
  int get hashCode => Object.hash(orderId, canViewOrder);
}

enum OrderPaymentStatus {
  idle,
  creatingInvoice,
  confirmingPayment,
  awaitingQrPayment,
  completed,
  error,
}

class OrderPaymentState {
  final OrderPaymentStatus status;
  final SessionInvoice? invoice;
  final String? errorMessage;

  const OrderPaymentState({
    required this.status,
    this.invoice,
    this.errorMessage,
  });

  const OrderPaymentState.idle() : this(status: OrderPaymentStatus.idle);

  bool get isProcessing =>
      status == OrderPaymentStatus.creatingInvoice ||
      status == OrderPaymentStatus.confirmingPayment;

  OrderPaymentState copyWith({
    OrderPaymentStatus? status,
    SessionInvoice? invoice,
    String? errorMessage,
    bool clearError = false,
  }) {
    return OrderPaymentState(
      status: status ?? this.status,
      invoice: invoice ?? this.invoice,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }
}

class OrderDetailState {
  final OrderLoadStatus status;
  final Order? order;
  final String? errorMessage;

  const OrderDetailState({required this.status, this.order, this.errorMessage});

  const OrderDetailState.initial() : this(status: OrderLoadStatus.initial);

  OrderDetailState copyWith({
    OrderLoadStatus? status,
    Order? order,
    String? errorMessage,
    bool clearError = false,
  }) {
    return OrderDetailState(
      status: status ?? this.status,
      order: order ?? this.order,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }
}

class OrderCartTopping {
  final ProductTopping topping;
  final int quantity;

  const OrderCartTopping({required this.topping, required this.quantity});

  OrderCartTopping copyWith({int? quantity}) {
    return OrderCartTopping(
      topping: topping,
      quantity: quantity ?? this.quantity,
    );
  }
}

class OrderCartItem {
  final String key;
  final Product product;
  final ProductVariantDraft? variant;
  final List<OrderCartTopping> toppings;
  final String note;
  final int quantity;

  const OrderCartItem({
    required this.key,
    required this.product,
    this.variant,
    this.toppings = const [],
    this.note = '',
    this.quantity = 1,
  });

  int get unitPrice =>
      (variant?.price ?? product.price) +
      toppings.fold(
        0,
        (sum, selected) => sum + selected.topping.price * selected.quantity,
      );

  int get totalPrice => unitPrice * quantity;

  OrderCartItem copyWith({
    ProductVariantDraft? variant,
    bool clearVariant = false,
    List<OrderCartTopping>? toppings,
    String? note,
    int? quantity,
  }) {
    return OrderCartItem(
      key: key,
      product: product,
      variant: clearVariant ? null : (variant ?? this.variant),
      toppings: toppings ?? this.toppings,
      note: note ?? this.note,
      quantity: quantity ?? this.quantity,
    );
  }
}

class OrderCreateState {
  final OrderLoadStatus status;
  final List<Product> products;
  final List<ProductCategory> categories;
  final List<OrderCartItem> cart;
  final int? selectedCategoryId;
  final String query;
  final bool isSubmitting;
  final String? errorMessage;

  const OrderCreateState({
    required this.status,
    this.products = const [],
    this.categories = const [],
    this.cart = const [],
    this.selectedCategoryId,
    this.query = '',
    this.isSubmitting = false,
    this.errorMessage,
  });

  const OrderCreateState.initial() : this(status: OrderLoadStatus.initial);

  List<Product> get visibleProducts {
    final normalized = query.trim().toLowerCase();
    return products.where((product) {
      return product.isActive &&
          !product.isDeleted &&
          (selectedCategoryId == null ||
              product.categoryId == selectedCategoryId) &&
          (normalized.isEmpty ||
              product.name.toLowerCase().contains(normalized) ||
              product.categoryName.toLowerCase().contains(normalized));
    }).toList();
  }

  int get cartQuantity =>
      cart.fold(0, (sum, cartItem) => sum + cartItem.quantity);

  int get cartTotal =>
      cart.fold(0, (sum, cartItem) => sum + cartItem.totalPrice);

  OrderCreateState copyWith({
    OrderLoadStatus? status,
    List<Product>? products,
    List<ProductCategory>? categories,
    List<OrderCartItem>? cart,
    int? selectedCategoryId,
    bool clearSelectedCategory = false,
    String? query,
    bool? isSubmitting,
    String? errorMessage,
    bool clearError = false,
  }) {
    return OrderCreateState(
      status: status ?? this.status,
      products: products ?? this.products,
      categories: categories ?? this.categories,
      cart: cart ?? this.cart,
      selectedCategoryId: clearSelectedCategory
          ? null
          : (selectedCategoryId ?? this.selectedCategoryId),
      query: query ?? this.query,
      isSubmitting: isSubmitting ?? this.isSubmitting,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }
}

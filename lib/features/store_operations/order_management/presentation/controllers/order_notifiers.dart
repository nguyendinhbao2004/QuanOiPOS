import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../product_management/presentation/providers/product_management_providers.dart';
import '../../domain/entities/create_order_draft.dart';
import '../../domain/entities/order.dart';
import '../providers/order_management_providers.dart';
import 'order_states.dart';

class OrderListNotifier
    extends AutoDisposeFamilyNotifier<OrderListState, OrderSessionAccess> {
  late OrderSessionAccess _access;
  bool _loading = false;

  @override
  OrderListState build(OrderSessionAccess arg) {
    _access = arg;
    Future.microtask(load);
    return const OrderListState.initial();
  }

  Future<void> load() async {
    if (_loading) return;
    if (!_access.canViewOrder) {
      state = state.copyWith(
        status: OrderLoadStatus.forbidden,
        errorMessage: 'Bạn chưa có quyền xem đơn hàng',
      );
      return;
    }

    _loading = true;
    state = state.copyWith(status: OrderLoadStatus.loading, clearError: true);
    try {
      final orders = await ref.read(loadOrdersByTableSessionUseCaseProvider)(
        _access.tableSessionId,
      );
      orders.sort((a, b) {
        final left = a.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
        final right = b.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
        return right.compareTo(left);
      });
      state = state.copyWith(
        status: OrderLoadStatus.ready,
        orders: orders,
        clearError: true,
      );
    } catch (error) {
      state = state.copyWith(
        status: OrderLoadStatus.error,
        errorMessage: _cleanError(error),
      );
    } finally {
      _loading = false;
    }
  }
}

class OrderDetailNotifier
    extends AutoDisposeFamilyNotifier<OrderDetailState, OrderDetailAccess> {
  late OrderDetailAccess _access;

  @override
  OrderDetailState build(OrderDetailAccess arg) {
    _access = arg;
    Future.microtask(load);
    return const OrderDetailState.initial();
  }

  Future<void> load() async {
    if (!_access.canViewOrder) {
      state = state.copyWith(
        status: OrderLoadStatus.forbidden,
        errorMessage: 'Bạn chưa có quyền xem đơn hàng',
      );
      return;
    }
    state = state.copyWith(status: OrderLoadStatus.loading, clearError: true);
    try {
      final order = await ref.read(loadOrderDetailUseCaseProvider)(
        _access.orderId,
      );
      state = state.copyWith(
        status: OrderLoadStatus.ready,
        order: order,
        clearError: true,
      );
    } catch (error) {
      state = state.copyWith(
        status: OrderLoadStatus.error,
        errorMessage: _cleanError(error),
      );
    }
  }
}

class OrderCreateNotifier
    extends AutoDisposeFamilyNotifier<OrderCreateState, OrderSessionAccess> {
  late OrderSessionAccess _access;
  int _nextKey = 0;

  @override
  OrderCreateState build(OrderSessionAccess arg) {
    _access = arg;
    Future.microtask(load);
    return const OrderCreateState.initial();
  }

  Future<void> load() async {
    if (!_access.canCreateOrder || !_access.isSessionOpen) {
      state = state.copyWith(
        status: OrderLoadStatus.forbidden,
        errorMessage: !_access.isSessionOpen
            ? 'Chỉ có thể tạo đơn cho phiên đang mở'
            : 'Bạn chưa có quyền tạo đơn hàng',
      );
      return;
    }

    state = state.copyWith(status: OrderLoadStatus.loading, clearError: true);
    try {
      final productsFuture = ref.read(loadProductsUseCaseProvider)(
        _access.storeId,
      );
      final categoriesFuture = ref.read(loadProductCategoriesUseCaseProvider)(
        _access.storeId,
      );
      state = state.copyWith(
        status: OrderLoadStatus.ready,
        products: await productsFuture,
        categories: await categoriesFuture,
        clearError: true,
      );
    } catch (error) {
      state = state.copyWith(
        status: OrderLoadStatus.error,
        errorMessage: _cleanError(error),
      );
    }
  }

  void setQuery(String value) => state = state.copyWith(query: value);

  void selectCategory(int? categoryId) {
    state = state.copyWith(
      selectedCategoryId: categoryId,
      clearSelectedCategory: categoryId == null,
    );
  }

  void addConfiguredItem(OrderCartItem item) {
    final keyedItem = OrderCartItem(
      key: 'cart-${_nextKey++}',
      product: item.product,
      variant: item.variant,
      toppings: item.toppings,
      note: item.note,
      quantity: item.quantity,
    );
    state = state.copyWith(cart: [...state.cart, keyedItem]);
  }

  void updateItem(OrderCartItem item) {
    state = state.copyWith(
      cart: [
        for (final current in state.cart)
          if (current.key == item.key) item else current,
      ],
    );
  }

  void changeQuantity(String key, int delta) {
    final updated = <OrderCartItem>[];
    for (final item in state.cart) {
      if (item.key != key) {
        updated.add(item);
        continue;
      }
      final quantity = item.quantity + delta;
      if (quantity > 0) updated.add(item.copyWith(quantity: quantity));
    }
    state = state.copyWith(cart: updated);
  }

  void removeItem(String key) {
    state = state.copyWith(
      cart: state.cart.where((item) => item.key != key).toList(),
    );
  }

  Future<Order> submit() async {
    if (!_access.canCreateOrder || !_access.isSessionOpen) {
      throw Exception('Không thể tạo đơn cho phiên này');
    }
    if (state.cart.isEmpty) {
      throw Exception('Vui lòng chọn ít nhất một món');
    }

    state = state.copyWith(isSubmitting: true, clearError: true);
    try {
      final items = <CreateOrderItemDraft>[];
      for (final cartItem in state.cart) {
        for (var index = 0; index < cartItem.quantity; index++) {
          items.add(
            CreateOrderItemDraft(
              productId: cartItem.product.id,
              variantId: cartItem.variant?.id,
              note: cartItem.note.trim().isEmpty ? null : cartItem.note.trim(),
              toppings: cartItem.toppings
                  .map(
                    (selected) => CreateOrderToppingDraft(
                      toppingId: selected.topping.id,
                      quantity: selected.quantity,
                    ),
                  )
                  .toList(),
            ),
          );
        }
      }
      return await ref.read(createOrderUseCaseProvider)(
        CreateOrderDraft(
          storeId: _access.storeId,
          tableSessionId: _access.tableSessionId,
          items: items,
        ),
      );
    } catch (error) {
      state = state.copyWith(errorMessage: _cleanError(error));
      rethrow;
    } finally {
      state = state.copyWith(isSubmitting: false);
    }
  }
}

String _cleanError(Object error) {
  return error.toString().replaceFirst('Exception: ', '');
}

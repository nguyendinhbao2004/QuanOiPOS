import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quan_oi/features/store_operations/order_management/domain/entities/create_order_draft.dart';
import 'package:quan_oi/features/store_operations/order_management/domain/entities/order.dart';
import 'package:quan_oi/features/store_operations/order_management/domain/repositories/order_management_repository.dart';
import 'package:quan_oi/features/store_operations/order_management/domain/usecases/create_order_use_case.dart';
import 'package:quan_oi/features/store_operations/order_management/domain/usecases/load_orders_by_table_session_use_case.dart';
import 'package:quan_oi/features/store_operations/order_management/presentation/controllers/order_states.dart';
import 'package:quan_oi/features/store_operations/order_management/presentation/providers/order_management_providers.dart';
import 'package:quan_oi/features/store_operations/product_management/domain/entities/product.dart';
import 'package:quan_oi/features/store_operations/product_management/domain/entities/product_category.dart';
import 'package:quan_oi/features/store_operations/product_management/domain/entities/product_type.dart';
import 'package:quan_oi/features/store_operations/product_management/domain/entities/product_variant_draft.dart';
import 'package:quan_oi/features/store_operations/product_management/domain/repositories/product_management_repository.dart';
import 'package:quan_oi/features/store_operations/product_management/domain/usecases/load_product_categories_use_case.dart';
import 'package:quan_oi/features/store_operations/product_management/domain/usecases/load_products_use_case.dart';
import 'package:quan_oi/features/store_operations/product_management/presentation/providers/product_management_providers.dart';

void main() {
  test('order list blocks loading without ORDER.VIEW', () async {
    final orderRepository = _FakeOrderRepository();
    final container = ProviderContainer(
      overrides: [
        loadOrdersByTableSessionUseCaseProvider.overrideWithValue(
          LoadOrdersByTableSessionUseCase(orderRepository),
        ),
      ],
    );
    addTearDown(container.dispose);
    const access = OrderSessionAccess(
      storeId: 5,
      tableSessionId: 501,
      isSessionOpen: true,
      canViewOrder: false,
      canCreateOrder: false,
    );

    await container.read(orderListNotifierProvider(access).notifier).load();

    expect(
      container.read(orderListNotifierProvider(access)).status,
      OrderLoadStatus.forbidden,
    );
    expect(orderRepository.loadCallCount, 0);
  });

  test('create notifier expands cart quantity into API items', () async {
    final orderRepository = _FakeOrderRepository();
    final productRepository = _FakeProductRepository();
    final container = ProviderContainer(
      overrides: [
        loadProductsUseCaseProvider.overrideWithValue(
          LoadProductsUseCase(productRepository),
        ),
        loadProductCategoriesUseCaseProvider.overrideWithValue(
          LoadProductCategoriesUseCase(productRepository),
        ),
        createOrderUseCaseProvider.overrideWithValue(
          CreateOrderUseCase(orderRepository),
        ),
      ],
    );
    addTearDown(container.dispose);
    const access = OrderSessionAccess(
      storeId: 5,
      tableSessionId: 501,
      isSessionOpen: true,
      canViewOrder: true,
      canCreateOrder: true,
    );
    final notifier = container.read(
      orderCreateNotifierProvider(access).notifier,
    );
    await notifier.load();
    notifier.addConfiguredItem(
      OrderCartItem(
        key: '',
        product: productRepository.product,
        variant: productRepository.product.variants.single,
        note: 'Ít đá',
        quantity: 2,
      ),
    );

    await notifier.submit();

    expect(orderRepository.createdDraft?.items.length, 2);
    expect(orderRepository.createdDraft?.items.first.variantId, 201);
    expect(orderRepository.createdDraft?.items.first.note, 'Ít đá');
  });

  test('create notifier rejects empty cart', () async {
    final orderRepository = _FakeOrderRepository();
    final productRepository = _FakeProductRepository();
    final container = ProviderContainer(
      overrides: [
        loadProductsUseCaseProvider.overrideWithValue(
          LoadProductsUseCase(productRepository),
        ),
        loadProductCategoriesUseCaseProvider.overrideWithValue(
          LoadProductCategoriesUseCase(productRepository),
        ),
        createOrderUseCaseProvider.overrideWithValue(
          CreateOrderUseCase(orderRepository),
        ),
      ],
    );
    addTearDown(container.dispose);
    const access = OrderSessionAccess(
      storeId: 5,
      tableSessionId: 501,
      isSessionOpen: true,
      canViewOrder: true,
      canCreateOrder: true,
    );
    final notifier = container.read(
      orderCreateNotifierProvider(access).notifier,
    );
    await notifier.load();

    await expectLater(notifier.submit(), throwsA(isA<Exception>()));
    expect(orderRepository.createdDraft, isNull);
  });
}

class _FakeOrderRepository implements OrderManagementRepository {
  int loadCallCount = 0;
  CreateOrderDraft? createdDraft;

  @override
  Future<List<Order>> loadOrdersByTableSession(int tableSessionId) async {
    loadCallCount += 1;
    return const [];
  }

  @override
  Future<Order> createOrder(CreateOrderDraft draft) async {
    createdDraft = draft;
    return Order(
      id: 7001,
      storeId: draft.storeId,
      tableSessionId: draft.tableSessionId,
      type: OrderType.dineIn,
      status: OrderStatus.pending,
      totalAmount: 60000,
    );
  }

  @override
  Future<Order> loadOrderDetail(int orderId) async =>
      throw UnimplementedError();
}

class _FakeProductRepository implements ProductManagementRepository {
  final Product product = const Product(
    id: 101,
    storeId: 5,
    categoryId: 12,
    categoryName: 'Đồ uống',
    name: 'Trà sữa',
    imageUrl: '',
    description: '',
    preparationTime: 5,
    price: 30000,
    type: ProductType.drink,
    variants: [
      ProductVariantDraft(
        id: 201,
        name: 'Size L',
        price: 35000,
        isDefault: true,
      ),
    ],
    isSell: true,
    isDeleted: false,
  );

  @override
  Future<List<Product>> loadProducts(int storeId) async => [product];

  @override
  Future<List<ProductCategory>> loadCategories(int storeId) async => const [
    ProductCategory(id: 12, storeId: 5, name: 'Đồ uống', isDeleted: false),
  ];

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

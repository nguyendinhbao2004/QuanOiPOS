import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quan_oi/features/store_operations/order_management/domain/entities/create_order_draft.dart';
import 'package:quan_oi/features/store_operations/order_management/domain/entities/order.dart';
import 'package:quan_oi/features/store_operations/order_management/domain/entities/session_invoice.dart';
import 'package:quan_oi/features/store_operations/order_management/domain/repositories/order_management_repository.dart';
import 'package:quan_oi/features/store_operations/order_management/domain/usecases/create_order_use_case.dart';
import 'package:quan_oi/features/store_operations/order_management/domain/usecases/create_order_invoice_use_case.dart';
import 'package:quan_oi/features/store_operations/order_management/domain/usecases/create_session_invoice_use_case.dart';
import 'package:quan_oi/features/store_operations/order_management/domain/usecases/confirm_payment_use_case.dart';
import 'package:quan_oi/features/store_operations/order_management/domain/usecases/load_orders_by_table_session_use_case.dart';
import 'package:quan_oi/features/store_operations/order_management/presentation/controllers/order_states.dart';
import 'package:quan_oi/features/store_operations/order_management/presentation/providers/order_management_providers.dart';
import 'package:quan_oi/features/store_operations/product_management/domain/entities/inventory_deduction_mode.dart';
import 'package:quan_oi/features/store_operations/product_management/domain/entities/product.dart';
import 'package:quan_oi/features/store_operations/product_management/domain/entities/product_category.dart';
import 'package:quan_oi/features/store_operations/product_management/domain/entities/product_type.dart';
import 'package:quan_oi/features/store_operations/product_management/domain/entities/product_variant_draft.dart';
import 'package:quan_oi/features/store_operations/product_management/domain/repositories/product_management_repository.dart';
import 'package:quan_oi/features/store_operations/product_management/domain/usecases/load_product_categories_use_case.dart';
import 'package:quan_oi/features/store_operations/product_management/domain/usecases/load_products_use_case.dart';
import 'package:quan_oi/features/store_operations/product_management/presentation/providers/product_management_providers.dart';
import 'package:quan_oi/features/store_operations/table_management/domain/repositories/table_management_repository.dart';
import 'package:quan_oi/features/store_operations/table_management/domain/usecases/close_table_session_use_case.dart';
import 'package:quan_oi/features/store_operations/table_management/presentation/providers/table_management_providers.dart';

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

  test(
    'create notifier sends null variant for ProductOnly without selection',
    () async {
      final orderRepository = _FakeOrderRepository();
      final productRepository = _FakeProductRepository(
        product: _product.copyWith(
          inventoryDeductionMode: InventoryDeductionMode.productOnly,
        ),
      );
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
        OrderCartItem(key: '', product: productRepository.product),
      );

      await notifier.submit();

      expect(orderRepository.createdDraft?.items.single.variantId, isNull);
    },
  );

  test('create notifier rejects VariantOnly item without variant', () async {
    final orderRepository = _FakeOrderRepository();
    final productRepository = _FakeProductRepository(
      product: _product.copyWith(
        inventoryDeductionMode: InventoryDeductionMode.variantOnly,
      ),
    );
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
      OrderCartItem(key: '', product: productRepository.product),
    );

    await expectLater(notifier.submit(), throwsA(isA<Exception>()));
    expect(orderRepository.createdDraft, isNull);
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

  test(
    'checkout creates invoice, confirms payment, then closes session',
    () async {
      final orderRepository = _FakeOrderRepository();
      final tableRepository = _CheckoutTableRepository();
      final container = ProviderContainer(
        overrides: [
          createSessionInvoiceUseCaseProvider.overrideWithValue(
            CreateSessionInvoiceUseCase(orderRepository),
          ),
          confirmPaymentUseCaseProvider.overrideWithValue(
            ConfirmPaymentUseCase(orderRepository),
          ),
          closeTableSessionUseCaseProvider.overrideWithValue(
            CloseTableSessionUseCase(tableRepository),
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
        canCloseSession: true,
      );

      await container
          .read(sessionCheckoutNotifierProvider(access).notifier)
          .checkout(PaymentMethod.cash);

      final state = container.read(sessionCheckoutNotifierProvider(access));
      expect(state.status, SessionCheckoutStatus.completed);
      expect(orderRepository.invoiceCallCount, 1);
      expect(orderRepository.confirmedPaymentIds, [1101]);
      expect(tableRepository.closedSessionIds, [501]);
    },
  );

  test(
    'qr checkout creates invoice without confirming or closing session',
    () async {
      final orderRepository = _FakeOrderRepository();
      final tableRepository = _CheckoutTableRepository();
      final container = ProviderContainer(
        overrides: [
          createSessionInvoiceUseCaseProvider.overrideWithValue(
            CreateSessionInvoiceUseCase(orderRepository),
          ),
          confirmPaymentUseCaseProvider.overrideWithValue(
            ConfirmPaymentUseCase(orderRepository),
          ),
          closeTableSessionUseCaseProvider.overrideWithValue(
            CloseTableSessionUseCase(tableRepository),
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
        canCloseSession: true,
      );

      await container
          .read(sessionCheckoutNotifierProvider(access).notifier)
          .checkout(PaymentMethod.qr);

      final state = container.read(sessionCheckoutNotifierProvider(access));
      expect(state.status, SessionCheckoutStatus.awaitingQrPayment);
      expect(state.invoice?.payOsData?.accountNumber, 'CAS0932958302');
      expect(orderRepository.invoiceCallCount, 1);
      expect(orderRepository.confirmedPaymentIds, isEmpty);
      expect(tableRepository.closedSessionIds, isEmpty);
    },
  );

  test('checkout retries only close after payment was confirmed', () async {
    final orderRepository = _FakeOrderRepository();
    final tableRepository = _CheckoutTableRepository(failFirstClose: true);
    final container = ProviderContainer(
      overrides: [
        createSessionInvoiceUseCaseProvider.overrideWithValue(
          CreateSessionInvoiceUseCase(orderRepository),
        ),
        confirmPaymentUseCaseProvider.overrideWithValue(
          ConfirmPaymentUseCase(orderRepository),
        ),
        closeTableSessionUseCaseProvider.overrideWithValue(
          CloseTableSessionUseCase(tableRepository),
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
      canCloseSession: true,
    );
    final notifier = container.read(
      sessionCheckoutNotifierProvider(access).notifier,
    );

    await expectLater(
      notifier.checkout(PaymentMethod.cash),
      throwsA(isA<Exception>()),
    );
    expect(
      container.read(sessionCheckoutNotifierProvider(access)).paymentConfirmed,
      isTrue,
    );

    await notifier.retryCloseSession();

    expect(orderRepository.invoiceCallCount, 1);
    expect(orderRepository.confirmedPaymentIds, [1101]);
    expect(tableRepository.closeCallCount, 2);
    expect(
      container.read(sessionCheckoutNotifierProvider(access)).status,
      SessionCheckoutStatus.completed,
    );
  });

  test(
    'order payment creates invoice and confirms without closing session',
    () async {
      final orderRepository = _FakeOrderRepository();
      final container = ProviderContainer(
        overrides: [
          createOrderInvoiceUseCaseProvider.overrideWithValue(
            CreateOrderInvoiceUseCase(orderRepository),
          ),
          confirmPaymentUseCaseProvider.overrideWithValue(
            ConfirmPaymentUseCase(orderRepository),
          ),
        ],
      );
      addTearDown(container.dispose);
      const access = OrderDetailAccess(orderId: 7001, canViewOrder: true);

      await container
          .read(orderPaymentNotifierProvider(access).notifier)
          .pay(PaymentMethod.card);

      expect(orderRepository.orderInvoiceIds, [7001]);
      expect(orderRepository.confirmedPaymentIds, [1101]);
      expect(
        container.read(orderPaymentNotifierProvider(access)).status,
        OrderPaymentStatus.completed,
      );
    },
  );

  test('qr order payment creates invoice without confirming payment', () async {
    final orderRepository = _FakeOrderRepository();
    final container = ProviderContainer(
      overrides: [
        createOrderInvoiceUseCaseProvider.overrideWithValue(
          CreateOrderInvoiceUseCase(orderRepository),
        ),
        confirmPaymentUseCaseProvider.overrideWithValue(
          ConfirmPaymentUseCase(orderRepository),
        ),
      ],
    );
    addTearDown(container.dispose);
    const access = OrderDetailAccess(orderId: 7001, canViewOrder: true);

    await container
        .read(orderPaymentNotifierProvider(access).notifier)
        .pay(PaymentMethod.qr);

    final state = container.read(orderPaymentNotifierProvider(access));
    expect(orderRepository.orderInvoiceIds, [7001]);
    expect(orderRepository.confirmedPaymentIds, isEmpty);
    expect(state.status, OrderPaymentStatus.awaitingQrPayment);
    expect(state.invoice?.payOsData?.description, 'CSY4HNUEJC7 PAY 28');
  });

  test('order payment retry reuses invoice after confirm failure', () async {
    final orderRepository = _FakeOrderRepository(failFirstConfirm: true);
    final container = ProviderContainer(
      overrides: [
        createOrderInvoiceUseCaseProvider.overrideWithValue(
          CreateOrderInvoiceUseCase(orderRepository),
        ),
        confirmPaymentUseCaseProvider.overrideWithValue(
          ConfirmPaymentUseCase(orderRepository),
        ),
      ],
    );
    addTearDown(container.dispose);
    const access = OrderDetailAccess(orderId: 7001, canViewOrder: true);
    final notifier = container.read(
      orderPaymentNotifierProvider(access).notifier,
    );

    await expectLater(
      notifier.pay(PaymentMethod.card),
      throwsA(isA<Exception>()),
    );
    await notifier.pay(PaymentMethod.card);

    expect(orderRepository.orderInvoiceIds, [7001]);
    expect(orderRepository.confirmCallCount, 2);
    expect(
      container.read(orderPaymentNotifierProvider(access)).status,
      OrderPaymentStatus.completed,
    );
  });
}

class _FakeOrderRepository implements OrderManagementRepository {
  final bool failFirstConfirm;
  int loadCallCount = 0;
  int invoiceCallCount = 0;
  int confirmCallCount = 0;
  CreateOrderDraft? createdDraft;
  final List<int> confirmedPaymentIds = [];
  final List<int> orderInvoiceIds = [];

  _FakeOrderRepository({this.failFirstConfirm = false});

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

  @override
  Future<SessionInvoice> createSessionInvoice({
    required int tableSessionId,
    required PaymentMethod method,
  }) async {
    invoiceCallCount += 1;
    return _invoice(method, 'INV-TS-501');
  }

  SessionInvoice _invoice(PaymentMethod method, String invoiceCode) {
    return SessionInvoice(
      invoiceId: 1001,
      paymentId: 1101,
      paymentMethod: method,
      invoiceCode: invoiceCode,
      finalAmount: 60000,
      payOsData: method == PaymentMethod.qr
          ? const PayOsPaymentData(
              bin: '970448',
              accountNumber: 'CAS0932958302',
              accountName: 'Nguyen Dinh Bao',
              amount: 10000,
              description: 'CSY4HNUEJC7 PAY 28',
              orderCode: 281782007998,
              currency: 'VND',
              paymentLinkId: 'af81765f288b4d758a14e260c6e8112b',
              status: 'PENDING',
              checkoutUrl:
                  'https://pay.payos.vn/web/af81765f288b4d758a14e260c6e8112b',
              qrCode: '000201010212',
            )
          : null,
    );
  }

  @override
  Future<void> confirmPayment(int paymentId) async {
    confirmCallCount += 1;
    if (failFirstConfirm && confirmCallCount == 1) {
      throw Exception('Không thể xác nhận thanh toán');
    }
    confirmedPaymentIds.add(paymentId);
  }

  @override
  Future<SessionInvoice> createOrderInvoice({
    required int orderId,
    required PaymentMethod method,
  }) async {
    orderInvoiceIds.add(orderId);
    return _invoice(method, 'INV-ORDER-7001');
  }

  @override
  Future<List<VietQrBank>> loadVietQrBanks() async => const [];
}

class _CheckoutTableRepository implements TableManagementRepository {
  final bool failFirstClose;
  int closeCallCount = 0;
  final List<int> closedSessionIds = [];

  _CheckoutTableRepository({this.failFirstClose = false});

  @override
  Future<void> closeTableSession(int tableSessionId) async {
    closeCallCount += 1;
    if (failFirstClose && closeCallCount == 1) {
      throw Exception('Không thể đóng phiên bàn');
    }
    closedSessionIds.add(tableSessionId);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

const _product = Product(
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
    ProductVariantDraft(id: 201, name: 'Size L', price: 35000, isDefault: true),
  ],
  isSell: true,
  isDeleted: false,
);

class _FakeProductRepository implements ProductManagementRepository {
  final Product product;

  _FakeProductRepository({this.product = _product});

  @override
  Future<List<Product>> loadProducts(int storeId) async => [product];

  @override
  Future<List<ProductCategory>> loadCategories(int storeId) async => const [
    ProductCategory(id: 12, storeId: 5, name: 'Đồ uống', isDeleted: false),
  ];

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

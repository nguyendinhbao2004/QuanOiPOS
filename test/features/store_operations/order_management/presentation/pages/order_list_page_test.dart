import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:quan_oi/core/constants/app_permission_codes.dart';
import 'package:quan_oi/core/theme/app_theme.dart';
import 'package:quan_oi/features/store_operations/order_management/domain/entities/create_order_draft.dart';
import 'package:quan_oi/features/store_operations/order_management/domain/entities/order.dart';
import 'package:quan_oi/features/store_operations/order_management/domain/entities/session_invoice.dart';
import 'package:quan_oi/features/store_operations/order_management/domain/repositories/order_management_repository.dart';
import 'package:quan_oi/features/store_operations/order_management/domain/usecases/load_orders_by_table_session_use_case.dart';
import 'package:quan_oi/features/store_operations/order_management/presentation/pages/order_list_page.dart';
import 'package:quan_oi/features/store_operations/order_management/presentation/providers/order_management_providers.dart';
import 'package:quan_oi/features/store_operations/order_management/presentation/widgets/qr_payment_dialog.dart';
import 'package:quan_oi/features/workspace_context/domain/entities/store.dart';
import 'package:quan_oi/features/workspace_context/domain/entities/store_access_context.dart';
import 'package:quan_oi/features/workspace_context/domain/entities/store_permission.dart';
import 'package:quan_oi/features/workspace_context/domain/repositories/workspace_repository.dart';
import 'package:quan_oi/features/workspace_context/domain/usecases/load_store_access_context_use_case.dart';
import 'package:quan_oi/features/workspace_context/presentation/providers/workspace_context_providers.dart';

void main() {
  testWidgets('shows FAB for open session with ORDER.CREATE', (tester) async {
    await _pumpPage(tester, isSessionOpen: true);

    expect(find.byKey(const Key('add_order_button')), findsOneWidget);
    expect(find.byKey(const Key('checkout_session_button')), findsOneWidget);
    expect(find.text('Đơn #7001'), findsOneWidget);
  });

  testWidgets('hides FAB for closed session and opens order detail', (
    tester,
  ) async {
    await _pumpPage(tester, isSessionOpen: false);

    expect(find.byKey(const Key('add_order_button')), findsNothing);
    expect(find.byKey(const Key('checkout_session_button')), findsNothing);
    await tester.tap(find.byKey(const Key('order_card_7001')));
    await tester.pumpAndSettle();
    expect(find.text('Chi tiết 7001'), findsOneWidget);
  });
  testWidgets('qr payment dialog shows PayOS and mapped bank info', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          vietQrBanksProvider.overrideWith(
            (_) async => const [
              VietQrBank(
                bin: '970448',
                code: 'OCB',
                name: 'Orient Commercial Joint Stock Bank',
                shortName: 'OCB',
                logo: 'https://api.vietqr.io/img/OCB.png',
              ),
            ],
          ),
        ],
        child: MaterialApp(
          theme: AppTheme.light,
          home: const Scaffold(body: QrPaymentDialog(invoice: _qrInvoice)),
        ),
      ),
    );
    await tester.pump();

    expect(find.text('OCB'), findsOneWidget);
    expect(find.text('CAS0932958302'), findsOneWidget);
    expect(find.text('Nguyen Dinh Bao'), findsOneWidget);
    expect(find.text('CSY4HNUEJC7 PAY 28'), findsOneWidget);
    expect(find.textContaining('10.000'), findsOneWidget);
    expect(find.text('PENDING'), findsNothing);
    expect(find.text('Trạng thái'), findsNothing);
  });
}

const _qrInvoice = SessionInvoice(
  invoiceId: 28,
  paymentId: 28,
  paymentMethod: PaymentMethod.qr,
  invoiceCode: 'INV-ORD-60-20260621021316718',
  finalAmount: 10000,
  payOsData: PayOsPaymentData(
    bin: '970448',
    accountNumber: 'CAS0932958302',
    accountName: 'Nguyen Dinh Bao',
    amount: 10000,
    description: 'CSY4HNUEJC7 PAY 28',
    orderCode: 281782007998,
    currency: 'VND',
    paymentLinkId: 'af81765f288b4d758a14e260c6e8112b',
    status: 'PENDING',
    checkoutUrl: 'https://pay.payos.vn/web/af81765f288b4d758a14e260c6e8112b',
    qrCode: '000201010212',
  ),
);

Future<void> _pumpPage(
  WidgetTester tester, {
  required bool isSessionOpen,
}) async {
  final router = GoRouter(
    initialLocation: '/orders',
    routes: [
      GoRoute(
        path: '/orders',
        builder: (_, _) => OrderListPage(
          storeId: 5,
          tableSessionId: 501,
          isSessionOpen: isSessionOpen,
        ),
      ),
      GoRoute(
        path: '/stores/:storeId/table-sessions/:tableSessionId/orders/new',
        name: 'store-order-create',
        builder: (_, _) => const Scaffold(body: Text('Tạo đơn')),
      ),
      GoRoute(
        path: '/stores/:storeId/table-sessions/:tableSessionId/orders/:orderId',
        name: 'store-order-detail',
        builder: (_, state) =>
            Scaffold(body: Text('Chi tiết ${state.pathParameters['orderId']}')),
      ),
    ],
  );
  final workspaceRepository = _FakeWorkspaceRepository();
  final orderRepository = _FakeOrderRepository();

  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        loadStoreAccessContextUseCaseProvider.overrideWithValue(
          LoadStoreAccessContextUseCase(workspaceRepository),
        ),
        loadOrdersByTableSessionUseCaseProvider.overrideWithValue(
          LoadOrdersByTableSessionUseCase(orderRepository),
        ),
      ],
      child: MaterialApp.router(theme: AppTheme.light, routerConfig: router),
    ),
  );
  await tester.pumpAndSettle();
}

class _FakeOrderRepository implements OrderManagementRepository {
  @override
  Future<List<Order>> loadOrdersByTableSession(int tableSessionId) async => [
    Order(
      id: 7001,
      storeId: 5,
      tableSessionId: tableSessionId,
      type: OrderType.dineIn,
      status: OrderStatus.pending,
      totalAmount: 35000,
      createdAt: DateTime(2026, 6, 10, 10),
    ),
  ];

  @override
  Future<Order> createOrder(CreateOrderDraft draft) =>
      throw UnimplementedError();

  @override
  Future<Order> loadOrderDetail(int orderId) => throw UnimplementedError();

  @override
  Future<SessionInvoice> createSessionInvoice({
    required int tableSessionId,
    required PaymentMethod method,
  }) async {
    throw UnimplementedError();
  }

  @override
  Future<void> confirmPayment(int paymentId) async {
    throw UnimplementedError();
  }

  @override
  Future<SessionInvoice> createOrderInvoice({
    required int orderId,
    required PaymentMethod method,
  }) async {
    throw UnimplementedError();
  }

  @override
  Future<List<VietQrBank>> loadVietQrBanks() async => const [];
}

class _FakeWorkspaceRepository implements WorkspaceRepository {
  static const store = Store(
    id: 5,
    ownerAccountId: 1,
    storeName: 'Quán Ơi',
    phone: '',
    address: '',
    status: StoreStatus.active,
    isDeleted: false,
  );

  @override
  Future<StoreAccessContext> loadStoreAccessContext(int storeId) async {
    return const StoreAccessContext(
      store: store,
      permissions: [
        StorePermission(permissionId: 27, code: AppPermissionCodes.orderView),
        StorePermission(permissionId: 28, code: AppPermissionCodes.orderCreate),
        StorePermission(
          permissionId: 13,
          code: AppPermissionCodes.tableCloseSession,
        ),
      ],
    );
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

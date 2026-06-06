import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:quan_oi/config/router_config.dart';
import 'package:quan_oi/core/constants/app_permission_codes.dart';
import 'package:quan_oi/core/theme/index.dart';
import 'package:quan_oi/features/store_operations/product_management/domain/entities/product.dart';
import 'package:quan_oi/features/store_operations/product_management/domain/entities/product_category.dart';
import 'package:quan_oi/features/store_operations/product_management/domain/entities/product_topping.dart';
import 'package:quan_oi/features/store_operations/product_management/domain/entities/product_type.dart';
import 'package:quan_oi/features/store_operations/product_management/domain/entities/product_variant_draft.dart';
import 'package:quan_oi/features/store_operations/product_management/domain/repositories/product_management_repository.dart';
import 'package:quan_oi/features/store_operations/product_management/domain/usecases/create_product_category_use_case.dart';
import 'package:quan_oi/features/store_operations/product_management/domain/usecases/create_product_use_case.dart';
import 'package:quan_oi/features/store_operations/product_management/domain/usecases/delete_product_category_use_case.dart';
import 'package:quan_oi/features/store_operations/product_management/domain/usecases/delete_product_use_case.dart';
import 'package:quan_oi/features/store_operations/product_management/domain/usecases/load_product_categories_use_case.dart';
import 'package:quan_oi/features/store_operations/product_management/domain/usecases/load_product_toppings_use_case.dart';
import 'package:quan_oi/features/store_operations/product_management/domain/usecases/load_products_use_case.dart';
import 'package:quan_oi/features/store_operations/product_management/domain/usecases/update_product_category_use_case.dart';
import 'package:quan_oi/features/store_operations/product_management/domain/usecases/update_product_sell_status_use_case.dart';
import 'package:quan_oi/features/store_operations/product_management/presentation/pages/product_create_page.dart';
import 'package:quan_oi/features/store_operations/product_management/presentation/pages/product_management_page.dart';
import 'package:quan_oi/features/store_operations/product_management/presentation/providers/product_management_providers.dart';
import 'package:quan_oi/features/workspace_context/domain/entities/store.dart';
import 'package:quan_oi/features/workspace_context/domain/entities/store_access_context.dart';
import 'package:quan_oi/features/workspace_context/domain/entities/store_permission.dart';
import 'package:quan_oi/features/workspace_context/domain/repositories/workspace_repository.dart';
import 'package:quan_oi/features/workspace_context/domain/usecases/load_store_access_context_use_case.dart';
import 'package:quan_oi/features/workspace_context/presentation/providers/workspace_context_providers.dart';

void main() {
  testWidgets(
    'shows forbidden state and skips product load without view permission',
    (tester) async {
      final productRepository = _FakeProductManagementRepository();

      await _pumpPage(
        tester,
        permissions: const [],
        productRepository: productRepository,
      );
      await tester.pumpAndSettle();

      expect(
        find.text('Bạn chưa có quyền xem quản lý sản phẩm'),
        findsOneWidget,
      );
      expect(productRepository.loadCategoriesCallCount, 0);
      expect(productRepository.loadProductsCallCount, 0);
    },
  );

  testWidgets('renders product tab with category chips and products', (
    tester,
  ) async {
    await _pumpPage(
      tester,
      permissions: const [
        StorePermission(permissionId: 1, code: AppPermissionCodes.productView),
      ],
      productRepository: _FakeProductManagementRepository(),
    );
    await tester.pumpAndSettle();

    expect(find.text('Sản phẩm'), findsWidgets);
    expect(find.text('Tất cả'), findsOneWidget);
    expect(find.text('Đồ uống'), findsWidgets);
    expect(find.text('Trà sữa trân châu'), findsOneWidget);
    expect(find.text('25.000 đ'), findsOneWidget);
    expect(find.byKey(const Key('product_actions_1')), findsNothing);
  });

  testWidgets('category icon opens management sheet from product tab', (
    tester,
  ) async {
    await _pumpPage(
      tester,
      permissions: const [
        StorePermission(permissionId: 1, code: AppPermissionCodes.productView),
        StorePermission(
          permissionId: 2,
          code: AppPermissionCodes.productCreate,
        ),
        StorePermission(
          permissionId: 3,
          code: AppPermissionCodes.productUpdate,
        ),
        StorePermission(
          permissionId: 4,
          code: AppPermissionCodes.productDelete,
        ),
      ],
      productRepository: _FakeProductManagementRepository(),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('manage_product_categories_button')));
    await tester.pumpAndSettle();

    expect(
      find.byKey(const Key('product_category_management_sheet')),
      findsOneWidget,
    );
    expect(
      find.byKey(const Key('add_product_category_button')),
      findsOneWidget,
    );
    expect(find.byKey(const Key('category_management_tile_1')), findsOneWidget);
    expect(find.text('Danh mục sản phẩm'), findsNothing);
    expect(find.text('Trà sữa trân châu'), findsOneWidget);
  });

  testWidgets('renders category tab with category list', (tester) async {
    await _pumpPage(
      tester,
      permissions: const [
        StorePermission(permissionId: 1, code: AppPermissionCodes.productView),
        StorePermission(
          permissionId: 2,
          code: AppPermissionCodes.productCreate,
        ),
      ],
      productRepository: _FakeProductManagementRepository(),
    );
    await tester.pumpAndSettle();

    await tester.tap(
      find.byKey(const Key('product_management_tab_categories')),
    );
    await tester.pumpAndSettle();

    expect(find.text('Danh mục sản phẩm'), findsOneWidget);
    expect(find.byKey(const Key('category_tab_add_button')), findsOneWidget);
    expect(find.byKey(const Key('product_category_tile_1')), findsOneWidget);
  });

  testWidgets(
    'product FAB opens create page and submits variants with toppings',
    (tester) async {
      final productRepository = _FakeProductManagementRepository();

      await _pumpRoutedPage(
        tester,
        permissions: const [
          StorePermission(
            permissionId: 1,
            code: AppPermissionCodes.productView,
          ),
          StorePermission(
            permissionId: 2,
            code: AppPermissionCodes.productCreate,
          ),
        ],
        productRepository: productRepository,
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('add_product_button')));
      await tester.pumpAndSettle();

      expect(find.text('Tạo sản phẩm'), findsOneWidget);
      expect(find.text('1. Thông tin món'), findsOneWidget);
      await tester.scrollUntilVisible(
        find.text('2. Biến thể / Size'),
        220,
        scrollable: find.byType(Scrollable).first,
      );
      expect(find.text('2. Biến thể / Size'), findsOneWidget);
      await tester.scrollUntilVisible(
        find.text('3. Topping áp dụng'),
        220,
        scrollable: find.byType(Scrollable).first,
      );
      expect(find.text('3. Topping áp dụng'), findsOneWidget);
      expect(find.text('Trân châu đen'), findsOneWidget);

      await tester.scrollUntilVisible(
        find.byKey(const Key('product_create_name_field')),
        -220,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.enterText(
        find.byKey(const Key('product_create_name_field')),
        'Trà sữa size',
      );
      await tester.scrollUntilVisible(
        find.byKey(const Key('product_create_multi_size_switch')),
        220,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.tap(find.text('Món này có nhiều size'));
      await tester.pumpAndSettle();

      await tester.scrollUntilVisible(
        find.byKey(const Key('product_create_size_s_price_field')),
        160,
        scrollable: find.byType(Scrollable).first,
      );
      expect(
        find.byKey(const Key('product_create_size_s_price_field')),
        findsOneWidget,
      );

      await tester.enterText(
        find.byKey(const Key('product_create_size_s_price_field')),
        '25000',
      );
      await tester.enterText(
        find.byKey(const Key('product_create_size_m_price_field')),
        '30000',
      );
      await tester.enterText(
        find.byKey(const Key('product_create_size_l_price_field')),
        '35000',
      );
      await tester.tap(find.byKey(const Key('product_create_topping_1')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('product_create_submit_button')));
      await tester.pumpAndSettle();

      expect(find.text('Tạo sản phẩm'), findsNothing);
      expect(productRepository.createProductCallCount, 1);
      expect(productRepository.lastToppingIds, [1]);
      expect(productRepository.lastVariants?.map((variant) => variant.name), [
        'Size S',
        'Size M',
        'Size L',
      ]);
      expect(
        productRepository.lastVariants
            ?.singleWhere((variant) => variant.isDefault)
            .name,
        'Size M',
      );
    },
  );
}

Future<void> _pumpPage(
  WidgetTester tester, {
  required List<StorePermission> permissions,
  required _FakeProductManagementRepository productRepository,
}) async {
  final workspaceRepository = _FakeWorkspaceRepository(permissions);

  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        loadStoreAccessContextUseCaseProvider.overrideWithValue(
          LoadStoreAccessContextUseCase(workspaceRepository),
        ),
        loadProductCategoriesUseCaseProvider.overrideWithValue(
          LoadProductCategoriesUseCase(productRepository),
        ),
        createProductCategoryUseCaseProvider.overrideWithValue(
          CreateProductCategoryUseCase(productRepository),
        ),
        updateProductCategoryUseCaseProvider.overrideWithValue(
          UpdateProductCategoryUseCase(productRepository),
        ),
        deleteProductCategoryUseCaseProvider.overrideWithValue(
          DeleteProductCategoryUseCase(productRepository),
        ),
        loadProductsUseCaseProvider.overrideWithValue(
          LoadProductsUseCase(productRepository),
        ),
        createProductUseCaseProvider.overrideWithValue(
          CreateProductUseCase(productRepository),
        ),
        updateProductSellStatusUseCaseProvider.overrideWithValue(
          UpdateProductSellStatusUseCase(productRepository),
        ),
        deleteProductUseCaseProvider.overrideWithValue(
          DeleteProductUseCase(productRepository),
        ),
      ],
      child: MaterialApp(
        theme: AppTheme.light,
        home: const ProductManagementPage(storeId: 5),
      ),
    ),
  );
}

Future<void> _pumpRoutedPage(
  WidgetTester tester, {
  required List<StorePermission> permissions,
  required _FakeProductManagementRepository productRepository,
}) async {
  final workspaceRepository = _FakeWorkspaceRepository(permissions);
  final router = GoRouter(
    initialLocation: '/stores/5/products',
    routes: [
      GoRoute(
        path: '/stores/:storeId/products',
        name: RouteNames.storeProductManagement,
        builder: (context, state) => const ProductManagementPage(storeId: 5),
      ),
      GoRoute(
        path: '/stores/:storeId/products/new',
        name: RouteNames.storeProductCreate,
        builder: (context, state) => const ProductCreatePage(storeId: 5),
      ),
    ],
  );
  addTearDown(router.dispose);

  await tester.pumpWidget(
    ProviderScope(
      overrides: _productOverrides(workspaceRepository, productRepository),
      child: MaterialApp.router(theme: AppTheme.light, routerConfig: router),
    ),
  );
}

List<Override> _productOverrides(
  _FakeWorkspaceRepository workspaceRepository,
  _FakeProductManagementRepository productRepository,
) {
  return [
    loadStoreAccessContextUseCaseProvider.overrideWithValue(
      LoadStoreAccessContextUseCase(workspaceRepository),
    ),
    loadProductCategoriesUseCaseProvider.overrideWithValue(
      LoadProductCategoriesUseCase(productRepository),
    ),
    loadProductToppingsUseCaseProvider.overrideWithValue(
      LoadProductToppingsUseCase(productRepository),
    ),
    createProductCategoryUseCaseProvider.overrideWithValue(
      CreateProductCategoryUseCase(productRepository),
    ),
    updateProductCategoryUseCaseProvider.overrideWithValue(
      UpdateProductCategoryUseCase(productRepository),
    ),
    deleteProductCategoryUseCaseProvider.overrideWithValue(
      DeleteProductCategoryUseCase(productRepository),
    ),
    loadProductsUseCaseProvider.overrideWithValue(
      LoadProductsUseCase(productRepository),
    ),
    createProductUseCaseProvider.overrideWithValue(
      CreateProductUseCase(productRepository),
    ),
    updateProductSellStatusUseCaseProvider.overrideWithValue(
      UpdateProductSellStatusUseCase(productRepository),
    ),
    deleteProductUseCaseProvider.overrideWithValue(
      DeleteProductUseCase(productRepository),
    ),
  ];
}

class _FakeWorkspaceRepository implements WorkspaceRepository {
  final List<StorePermission> permissions;

  const _FakeWorkspaceRepository(this.permissions);

  @override
  Future<StoreAccessContext> loadStoreAccessContext(int storeId) async {
    return StoreAccessContext(
      store: await loadStoreById(storeId),
      permissions: permissions,
    );
  }

  @override
  Future<Store> loadStoreById(int storeId) async {
    return Store(
      id: storeId,
      ownerAccountId: 1,
      storeName: 'Quán ơi',
      phone: '0900000000',
      address: 'Hồ Chí Minh',
      status: StoreStatus.active,
      isDeleted: false,
    );
  }

  @override
  Future<List<StorePermission>> loadMyStorePermissions(int storeId) async {
    return permissions;
  }

  @override
  Future<List<Store>> loadMyStores() async {
    return [await loadStoreById(5)];
  }

  @override
  Future<Store> createStore({
    required String storeName,
    required String phone,
    required String address,
  }) {
    throw UnimplementedError();
  }
}

class _FakeProductManagementRepository implements ProductManagementRepository {
  int loadCategoriesCallCount = 0;
  int loadToppingsCallCount = 0;
  int loadProductsCallCount = 0;
  int createProductCallCount = 0;
  List<ProductVariantDraft>? lastVariants;
  List<int>? lastToppingIds;

  final categories = <ProductCategory>[
    const ProductCategory(id: 1, storeId: 5, name: 'Đồ uống', isDeleted: false),
    const ProductCategory(
      id: 2,
      storeId: 5,
      name: 'Thực phẩm',
      isDeleted: false,
    ),
  ];

  final products = <Product>[
    const Product(
      id: 1,
      storeId: 5,
      categoryId: 1,
      categoryName: 'Đồ uống',
      name: 'Trà sữa trân châu',
      imageUrl: '',
      description: 'Trà sữa',
      preparationTime: 5,
      price: 25000,
      type: ProductType.drink,
      isSell: true,
      isDeleted: false,
    ),
  ];

  final toppings = <ProductTopping>[
    const ProductTopping(
      id: 1,
      storeId: 5,
      name: 'Trân châu đen',
      price: 5000,
      isDeleted: false,
    ),
  ];

  @override
  Future<List<ProductCategory>> loadCategories(int storeId) async {
    loadCategoriesCallCount += 1;
    return categories;
  }

  @override
  Future<List<ProductTopping>> loadToppings(int storeId) async {
    loadToppingsCallCount += 1;
    return toppings;
  }

  @override
  Future<List<Product>> loadProducts(int storeId) async {
    loadProductsCallCount += 1;
    return products;
  }

  @override
  Future<ProductCategory> createCategory({
    required int storeId,
    required String name,
  }) async {
    return ProductCategory(
      id: 3,
      storeId: storeId,
      name: name,
      isDeleted: false,
    );
  }

  @override
  Future<ProductCategory> updateCategory({
    required int categoryId,
    required String name,
  }) async {
    return ProductCategory(
      id: categoryId,
      storeId: 5,
      name: name,
      isDeleted: false,
    );
  }

  @override
  Future<void> deleteCategory(int categoryId) async {}

  @override
  Future<Product> createProduct({
    required int storeId,
    required int categoryId,
    required String name,
    required String imageUrl,
    required String description,
    required int preparationTime,
    required int price,
    required ProductType type,
    List<ProductVariantDraft>? variants,
    required List<int> toppingIds,
  }) async {
    createProductCallCount += 1;
    lastVariants = variants;
    lastToppingIds = toppingIds;
    return Product(
      id: 2,
      storeId: storeId,
      categoryId: categoryId,
      categoryName: 'Đồ uống',
      name: name,
      imageUrl: imageUrl,
      description: description,
      preparationTime: preparationTime,
      price: price,
      type: type,
      isSell: true,
      isDeleted: false,
    );
  }

  @override
  Future<void> updateProductSellStatus({
    required int productId,
    required bool isSell,
  }) async {}

  @override
  Future<void> deleteProduct(int productId) async {}
}

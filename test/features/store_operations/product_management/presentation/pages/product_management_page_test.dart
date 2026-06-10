import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:quan_oi/config/router_config.dart';
import 'package:quan_oi/core/constants/app_permission_codes.dart';
import 'package:quan_oi/core/theme/index.dart';
import 'package:quan_oi/features/store_operations/product_management/domain/entities/product.dart';
import 'package:quan_oi/features/store_operations/product_management/domain/entities/product_category.dart';
import 'package:quan_oi/features/store_operations/product_management/domain/entities/product_ingredient.dart';
import 'package:quan_oi/features/store_operations/product_management/domain/entities/product_recipe_draft.dart';
import 'package:quan_oi/features/store_operations/product_management/domain/entities/product_topping.dart';
import 'package:quan_oi/features/store_operations/product_management/domain/entities/product_type.dart';
import 'package:quan_oi/features/store_operations/product_management/domain/entities/product_variant_draft.dart';
import 'package:quan_oi/features/store_operations/product_management/domain/repositories/product_management_repository.dart';
import 'package:quan_oi/features/store_operations/product_management/domain/usecases/create_product_category_use_case.dart';
import 'package:quan_oi/features/store_operations/product_management/domain/usecases/create_product_topping_use_case.dart';
import 'package:quan_oi/features/store_operations/product_management/domain/usecases/create_product_use_case.dart';
import 'package:quan_oi/features/store_operations/product_management/domain/usecases/delete_product_category_use_case.dart';
import 'package:quan_oi/features/store_operations/product_management/domain/usecases/delete_product_topping_use_case.dart';
import 'package:quan_oi/features/store_operations/product_management/domain/usecases/delete_product_use_case.dart';
import 'package:quan_oi/features/store_operations/product_management/domain/usecases/load_product_categories_use_case.dart';
import 'package:quan_oi/features/store_operations/product_management/domain/usecases/load_product_detail_use_case.dart';
import 'package:quan_oi/features/store_operations/product_management/domain/usecases/load_product_ingredients_use_case.dart';
import 'package:quan_oi/features/store_operations/product_management/domain/usecases/load_product_toppings_use_case.dart';
import 'package:quan_oi/features/store_operations/product_management/domain/usecases/load_products_use_case.dart';
import 'package:quan_oi/features/store_operations/product_management/domain/usecases/update_product_category_use_case.dart';
import 'package:quan_oi/features/store_operations/product_management/domain/usecases/update_product_sell_status_use_case.dart';
import 'package:quan_oi/features/store_operations/product_management/domain/usecases/update_product_topping_use_case.dart';
import 'package:quan_oi/features/store_operations/product_management/domain/usecases/update_product_use_case.dart';
import 'package:quan_oi/features/store_operations/product_management/presentation/controllers/product_create_state.dart';
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
    expect(find.byKey(const Key('category_tab_add_button')), findsNothing);
    expect(find.byKey(const Key('product_category_tile_1')), findsOneWidget);

    await tester.tap(find.byKey(const Key('add_category_button')));
    await tester.pumpAndSettle();

    expect(
      find.byKey(const Key('product_category_management_sheet')),
      findsOneWidget,
    );
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
          StorePermission(
            permissionId: 3,
            code: AppPermissionCodes.productUpdate,
          ),
          StorePermission(
            permissionId: 4,
            code: AppPermissionCodes.productDelete,
          ),
        ],
        productRepository: productRepository,
      );
      await tester.pumpAndSettle();
      expect(productRepository.loadToppingsCallCount, 1);

      await tester.tap(find.byKey(const Key('add_product_button')));
      await tester.pumpAndSettle();
      expect(productRepository.loadToppingsCallCount, 1);

      expect(find.text('Tạo sản phẩm'), findsOneWidget);
      expect(find.byType(CircularProgressIndicator), findsNothing);
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
      expect(
        find.byKey(const Key('product_create_topping_field')),
        findsOneWidget,
      );

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
        find.byKey(const Key('product_create_variant_1_name_field')),
        160,
        scrollable: find.byType(Scrollable).first,
      );
      expect(
        find.byKey(const Key('product_create_variant_1_name_field')),
        findsOneWidget,
      );

      await tester.enterText(
        find.byKey(const Key('product_create_variant_1_name_field')),
        'Rau muống',
      );
      await tester.enterText(
        find.byKey(const Key('product_create_variant_1_price_field')),
        '5000',
      );
      await tester.tap(
        find.byKey(const Key('product_create_add_variant_button')),
      );
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byKey(const Key('product_create_variant_2_name_field')),
        'Rau cải',
      );
      await tester.enterText(
        find.byKey(const Key('product_create_variant_2_price_field')),
        '7000',
      );
      await tester.tap(
        find.byKey(const Key('product_create_variant_2_default_button')),
      );
      await tester.pumpAndSettle();
      await tester.tap(
        find.byKey(const Key('product_create_variant_2_default_button')),
      );
      await tester.pumpAndSettle();
      await tester.scrollUntilVisible(
        find.byKey(const Key('product_create_topping_field')),
        220,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.tap(find.byKey(const Key('product_create_topping_field')));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(
        find.byKey(const Key('product_create_topping_picker_sheet')),
        findsOneWidget,
      );
      await tester.tap(
        find.byKey(const Key('product_create_topping_picker_item_1')),
      );
      await tester.pumpAndSettle();
      await tester.tap(
        find.byKey(const Key('product_create_topping_picker_update_button')),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('product_create_submit_button')));
      await tester.pumpAndSettle();

      expect(find.text('Tạo sản phẩm'), findsNothing);
      expect(productRepository.createProductCallCount, 1);
      expect(productRepository.lastToppingIds, [1]);
      expect(productRepository.lastVariants?.map((variant) => variant.name), [
        'Rau muống',
        'Rau cải',
      ]);
      expect(
        productRepository.lastVariants?.every((variant) => !variant.isDefault),
        isTrue,
      );
    },
  );

  testWidgets('create page category picker and topping CRUD sheets work', (
    tester,
  ) async {
    final productRepository = _FakeProductManagementRepository();

    await _pumpRoutedPage(
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
      productRepository: productRepository,
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('add_product_button')));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('product_create_category_field')));
    await tester.pumpAndSettle();
    expect(
      find.byKey(const Key('product_create_category_picker_sheet')),
      findsOneWidget,
    );
    await tester.enterText(find.byType(TextField).last, 'Thực');
    await tester.pumpAndSettle();
    expect(
      find.byKey(const Key('product_create_category_picker_item_2')),
      findsOneWidget,
    );
    await tester.tap(
      find.byKey(const Key('product_create_category_picker_item_2')),
    );
    await tester.pumpAndSettle();
    await tester.tap(
      find.byKey(const Key('product_create_category_picker_update_button')),
    );
    await tester.pumpAndSettle();
    expect(find.text('Thực phẩm'), findsOneWidget);

    await tester.tap(find.byKey(const Key('product_create_category_field')));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Thêm danh mục'));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const Key('category_name_field')),
      'Bánh ngọt',
    );
    await tester.tap(find.byKey(const Key('category_form_submit_button')));
    await tester.pumpAndSettle();
    expect(
      productRepository.categories.map((category) => category.name),
      contains('Bánh ngọt'),
    );
    await tester.tap(
      find.byKey(const Key('product_create_category_picker_update_button')),
    );
    await tester.pumpAndSettle();

    await tester.scrollUntilVisible(
      find.byKey(const Key('product_create_topping_field')),
      220,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(find.byKey(const Key('product_create_topping_field')));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    await tester.tap(find.byTooltip('Thêm topping'));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const Key('topping_name_field')),
      'Kem cheese',
    );
    await tester.enterText(
      find.byKey(const Key('topping_price_field')),
      '9000',
    );
    await tester.tap(find.byKey(const Key('topping_form_submit_button')));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(productRepository.createToppingCallCount, 1);
    expect(find.text('Kem cheese'), findsWidgets);
    expect(
      find.byKey(const Key('product_create_topping_actions_2')),
      findsNothing,
    );

    await tester.tap(find.byKey(const Key('edit_product_toppings_button')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('edit_product_topping_2')));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const Key('topping_name_field')),
      'Kem cheese mặn',
    );
    await tester.tap(find.byKey(const Key('topping_form_submit_button')));
    await tester.pumpAndSettle();
    expect(productRepository.updateToppingCallCount, 1);
    expect(find.text('Kem cheese mặn'), findsWidgets);

    await tester.tap(find.byKey(const Key('delete_product_topping_2')));
    await tester.pumpAndSettle();
    await tester.tap(
      find.byKey(const Key('confirm_delete_product_topping_button')),
    );
    await tester.pumpAndSettle();
    expect(productRepository.deleteToppingCallCount, 1);
    expect(find.text('Kem cheese mặn'), findsNothing);
  });

  testWidgets('tap product opens detail, prefills and updates product', (
    tester,
  ) async {
    final productRepository = _FakeProductManagementRepository();

    await _pumpRoutedPage(
      tester,
      permissions: const [
        StorePermission(permissionId: 1, code: AppPermissionCodes.productView),
        StorePermission(
          permissionId: 2,
          code: AppPermissionCodes.productUpdate,
        ),
        StorePermission(
          permissionId: 3,
          code: AppPermissionCodes.productDelete,
        ),
      ],
      productRepository: productRepository,
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('product_tile_1')));
    await tester.pumpAndSettle();

    expect(find.text('Chi tiết sản phẩm'), findsOneWidget);
    expect(find.text('Cập nhật'), findsOneWidget);
    expect(
      tester
          .widget<TextFormField>(
            find.byKey(const Key('product_create_name_field')),
          )
          .controller
          ?.text,
      'Trà sữa trân châu',
    );

    await tester.enterText(
      find.byKey(const Key('product_create_name_field')),
      'Trà sữa cập nhật',
    );
    await tester.tap(find.byKey(const Key('product_create_category_field')));
    await tester.pumpAndSettle();
    await tester.tap(
      find.byKey(const Key('product_create_category_picker_item_2')),
    );
    await tester.pumpAndSettle();
    await tester.tap(
      find.byKey(const Key('product_create_category_picker_update_button')),
    );
    await tester.pumpAndSettle();
    expect(find.text('Thực phẩm'), findsOneWidget);

    await tester.scrollUntilVisible(
      find.byKey(const Key('product_create_multi_size_switch')),
      220,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(find.text('Món này có nhiều size'));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.byKey(const Key('product_create_variant_1_name_field')),
      160,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.enterText(
      find.byKey(const Key('product_create_variant_1_name_field')),
      'Size M',
    );
    await tester.enterText(
      find.byKey(const Key('product_create_variant_1_price_field')),
      '30000',
    );
    await tester.tap(
      find.byKey(const Key('product_create_add_variant_button')),
    );
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const Key('product_create_variant_2_name_field')),
      'Size L',
    );
    await tester.enterText(
      find.byKey(const Key('product_create_variant_2_price_field')),
      '35000',
    );
    await tester.tap(
      find.byKey(const Key('product_create_variant_2_default_button')),
    );
    await tester.pumpAndSettle();

    await tester.scrollUntilVisible(
      find.byKey(const Key('product_create_topping_field')),
      220,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(find.byKey(const Key('product_create_topping_field')));
    await tester.pumpAndSettle();
    await tester.tap(
      find.byKey(const Key('product_create_topping_picker_item_1')),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Đóng').last);
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('product_create_submit_button')));
    await tester.pumpAndSettle();

    expect(productRepository.updateProductCallCount, 1);
    expect(productRepository.lastUpdatedProductName, 'Trà sữa cập nhật');
    expect(productRepository.lastUpdatedCategoryId, 2);
    expect(productRepository.lastToppingIds, [1]);
    expect(productRepository.lastVariants?.map((variant) => variant.name), [
      'Size M',
      'Size L',
    ]);
    expect(
      productRepository.lastVariants
          ?.singleWhere((variant) => variant.isDefault)
          .name,
      'Size L',
    );
    expect(productRepository.loadProductsCallCount, greaterThan(1));
    expect(find.text('Chi tiết sản phẩm'), findsNothing);
  });

  testWidgets('edit product delete one size sends remaining variants', (
    tester,
  ) async {
    final productRepository = _FakeProductManagementRepository();

    await _pumpRoutedPage(
      tester,
      permissions: const [
        StorePermission(permissionId: 1, code: AppPermissionCodes.productView),
        StorePermission(
          permissionId: 2,
          code: AppPermissionCodes.productUpdate,
        ),
      ],
      productRepository: productRepository,
    );
    await tester.pumpAndSettle();

    await _openProductDetail(tester);
    await _buildTwoSizeRows(tester);
    await tester.tap(
      find.byKey(const Key('product_create_variant_1_delete_button')),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('product_create_submit_button')));
    await tester.pumpAndSettle();

    expect(productRepository.updateProductCallCount, 1);
    expect(productRepository.lastVariants?.map((variant) => variant.name), [
      'Size L',
    ]);
    expect(
      productRepository.lastVariants
          ?.singleWhere((variant) => variant.isDefault)
          .name,
      'Size L',
    );
  });

  testWidgets('edit product delete all sizes sends empty variants', (
    tester,
  ) async {
    final productRepository = _FakeProductManagementRepository();

    await _pumpRoutedPage(
      tester,
      permissions: const [
        StorePermission(permissionId: 1, code: AppPermissionCodes.productView),
        StorePermission(
          permissionId: 2,
          code: AppPermissionCodes.productUpdate,
        ),
      ],
      productRepository: productRepository,
    );
    await tester.pumpAndSettle();

    await _openProductDetail(tester);
    await _buildTwoSizeRows(tester);
    await tester.tap(
      find.byKey(const Key('product_create_variant_1_delete_button')),
    );
    await tester.pumpAndSettle();
    await tester.tap(
      find.byKey(const Key('product_create_variant_2_delete_button')),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('product_create_submit_button')));
    await tester.pumpAndSettle();

    expect(productRepository.updateProductCallCount, 1);
    expect(productRepository.lastVariants, isEmpty);
  });

  testWidgets('edit product topping add and delete update toppingIds payload', (
    tester,
  ) async {
    final productRepository = _FakeProductManagementRepository();

    await _pumpRoutedPage(
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
      productRepository: productRepository,
    );
    await tester.pumpAndSettle();

    await _openProductDetail(tester);
    await tester.scrollUntilVisible(
      find.byKey(const Key('product_create_topping_field')),
      220,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(find.byKey(const Key('product_create_topping_field')));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Thêm topping'));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const Key('topping_name_field')),
      'Kem cheese',
    );
    await tester.enterText(
      find.byKey(const Key('topping_price_field')),
      '9000',
    );
    await tester.tap(find.byKey(const Key('topping_form_submit_button')));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Đóng').last);
    await tester.pumpAndSettle();
    await tester.pump(const Duration(seconds: 4));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('product_create_submit_button')));
    await tester.pumpAndSettle();

    expect(productRepository.lastToppingIds, [2]);

    await _openProductDetail(tester);
    await tester.scrollUntilVisible(
      find.byKey(const Key('product_create_topping_field')),
      220,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(find.byKey(const Key('product_create_topping_field')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('edit_product_toppings_button')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('delete_product_topping_2')));
    await tester.pumpAndSettle();
    await tester.tap(
      find.byKey(const Key('confirm_delete_product_topping_button')),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Đóng').last);
    await tester.pumpAndSettle();
    await tester.pump(const Duration(seconds: 4));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('product_create_submit_button')));
    await tester.pumpAndSettle();

    expect(productRepository.deleteToppingCallCount, 1);
    expect(productRepository.lastToppingIds, isEmpty);
  });

  testWidgets('edit product delete confirms, deletes and reloads list', (
    tester,
  ) async {
    final productRepository = _FakeProductManagementRepository();

    await _pumpRoutedPage(
      tester,
      permissions: const [
        StorePermission(permissionId: 1, code: AppPermissionCodes.productView),
        StorePermission(
          permissionId: 2,
          code: AppPermissionCodes.productUpdate,
        ),
        StorePermission(
          permissionId: 3,
          code: AppPermissionCodes.productDelete,
        ),
      ],
      productRepository: productRepository,
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('product_tile_1')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('product_delete_button')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('confirm_delete_product_button')));
    await tester.pumpAndSettle();

    expect(productRepository.deleteProductCallCount, 1);
    expect(productRepository.products, isEmpty);
    expect(productRepository.loadProductsCallCount, greaterThan(1));
  });

  testWidgets('missing update permission blocks product detail form', (
    tester,
  ) async {
    final productRepository = _FakeProductManagementRepository();

    await _pumpRoutedPage(
      tester,
      permissions: const [
        StorePermission(permissionId: 1, code: AppPermissionCodes.productView),
      ],
      productRepository: productRepository,
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('product_tile_1')));
    await tester.pumpAndSettle();

    expect(find.text('Bạn chưa có quyền cập nhật sản phẩm'), findsOneWidget);
    expect(find.byKey(const Key('product_create_name_field')), findsNothing);
    expect(productRepository.loadProductDetailCallCount, 0);
    expect(productRepository.updateProductCallCount, 0);
  });
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
        loadProductToppingsUseCaseProvider.overrideWithValue(
          LoadProductToppingsUseCase(productRepository),
        ),
        loadProductIngredientsUseCaseProvider.overrideWithValue(
          LoadProductIngredientsUseCase(productRepository),
        ),
        createProductToppingUseCaseProvider.overrideWithValue(
          CreateProductToppingUseCase(productRepository),
        ),
        updateProductToppingUseCaseProvider.overrideWithValue(
          UpdateProductToppingUseCase(productRepository),
        ),
        deleteProductToppingUseCaseProvider.overrideWithValue(
          DeleteProductToppingUseCase(productRepository),
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
        loadProductDetailUseCaseProvider.overrideWithValue(
          LoadProductDetailUseCase(productRepository),
        ),
        createProductUseCaseProvider.overrideWithValue(
          CreateProductUseCase(productRepository),
        ),
        updateProductUseCaseProvider.overrideWithValue(
          UpdateProductUseCase(productRepository),
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

Future<void> _openProductDetail(WidgetTester tester) async {
  await tester.tap(find.byKey(const Key('product_tile_1')));
  await tester.pumpAndSettle();
}

Future<void> _buildTwoSizeRows(WidgetTester tester) async {
  await tester.scrollUntilVisible(
    find.byKey(const Key('product_create_multi_size_switch')),
    220,
    scrollable: find.byType(Scrollable).first,
  );
  await tester.tap(find.text('Món này có nhiều size'));
  await tester.pumpAndSettle();
  await tester.scrollUntilVisible(
    find.byKey(const Key('product_create_variant_1_name_field')),
    160,
    scrollable: find.byType(Scrollable).first,
  );
  await tester.enterText(
    find.byKey(const Key('product_create_variant_1_name_field')),
    'Size M',
  );
  await tester.enterText(
    find.byKey(const Key('product_create_variant_1_price_field')),
    '30000',
  );
  await tester.tap(find.byKey(const Key('product_create_add_variant_button')));
  await tester.pumpAndSettle();
  await tester.enterText(
    find.byKey(const Key('product_create_variant_2_name_field')),
    'Size L',
  );
  await tester.enterText(
    find.byKey(const Key('product_create_variant_2_price_field')),
    '35000',
  );
  await tester.tap(
    find.byKey(const Key('product_create_variant_2_default_button')),
  );
  await tester.pumpAndSettle();
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
        builder: (context, state) {
          final seedData = state.extra is ProductCreateSeedData
              ? state.extra! as ProductCreateSeedData
              : null;
          return ProductCreatePage(storeId: 5, seedData: seedData);
        },
      ),
      GoRoute(
        path: '/stores/:storeId/products/:productId',
        name: RouteNames.storeProductDetail,
        builder: (context, state) {
          final productId = int.parse(state.pathParameters['productId']!);
          final seedData = state.extra is ProductCreateSeedData
              ? state.extra! as ProductCreateSeedData
              : ProductCreateSeedData(
                  categories: const [],
                  toppings: const [],
                  editingProductId: productId,
                );
          return ProductCreatePage(storeId: 5, seedData: seedData);
        },
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
    loadProductIngredientsUseCaseProvider.overrideWithValue(
      LoadProductIngredientsUseCase(productRepository),
    ),
    createProductToppingUseCaseProvider.overrideWithValue(
      CreateProductToppingUseCase(productRepository),
    ),
    updateProductToppingUseCaseProvider.overrideWithValue(
      UpdateProductToppingUseCase(productRepository),
    ),
    deleteProductToppingUseCaseProvider.overrideWithValue(
      DeleteProductToppingUseCase(productRepository),
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
    loadProductDetailUseCaseProvider.overrideWithValue(
      LoadProductDetailUseCase(productRepository),
    ),
    createProductUseCaseProvider.overrideWithValue(
      CreateProductUseCase(productRepository),
    ),
    updateProductUseCaseProvider.overrideWithValue(
      UpdateProductUseCase(productRepository),
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

  @override
  Future<StoreAccessContext?> loadCachedStoreAccessContext({
    required int accountId,
    required int storeId,
  }) async {
    return null;
  }

  @override
  Future<void> saveStoreAccessContextCache({
    required int accountId,
    required StoreAccessContext context,
  }) async {}

  @override
  Future<void> clearStoreAccessContextCache({
    required int accountId,
    required int storeId,
  }) async {}

  @override
  Future<void> clearAllStoreAccessContextCache() async {}
}

class _FakeProductManagementRepository implements ProductManagementRepository {
  int loadCategoriesCallCount = 0;
  int loadToppingsCallCount = 0;
  int loadProductsCallCount = 0;
  int loadProductDetailCallCount = 0;
  int createProductCallCount = 0;
  int updateProductCallCount = 0;
  int deleteProductCallCount = 0;
  int createToppingCallCount = 0;
  int updateToppingCallCount = 0;
  int deleteToppingCallCount = 0;
  String? lastUpdatedProductName;
  int? lastUpdatedCategoryId;
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
    return [...categories];
  }

  @override
  Future<List<ProductTopping>> loadToppings(int storeId) async {
    loadToppingsCallCount += 1;
    return [...toppings];
  }

  @override
  Future<List<ProductIngredient>> loadIngredients(int storeId) async =>
      const [];

  @override
  Future<ProductTopping> createTopping({
    required int storeId,
    required String name,
    required int price,
  }) async {
    createToppingCallCount += 1;
    final topping = ProductTopping(
      id: toppings.length + 1,
      storeId: storeId,
      name: name,
      price: price,
      isDeleted: false,
    );
    toppings.add(topping);
    return topping;
  }

  @override
  Future<ProductTopping> updateTopping({
    required int toppingId,
    required String name,
    required int price,
  }) async {
    updateToppingCallCount += 1;
    final topping = ProductTopping(
      id: toppingId,
      storeId: 5,
      name: name,
      price: price,
      isDeleted: false,
    );
    final index = toppings.indexWhere((item) => item.id == toppingId);
    if (index != -1) {
      toppings[index] = topping;
    }
    return topping;
  }

  @override
  Future<void> deleteTopping(int toppingId) async {
    deleteToppingCallCount += 1;
    toppings.removeWhere((topping) => topping.id == toppingId);
  }

  @override
  Future<List<Product>> loadProducts(int storeId) async {
    loadProductsCallCount += 1;
    return [...products];
  }

  @override
  Future<Product> loadProductDetail(int productId) async {
    loadProductDetailCallCount += 1;
    return products.firstWhere((product) => product.id == productId);
  }

  @override
  Future<ProductCategory> createCategory({
    required int storeId,
    required String name,
  }) async {
    final category = ProductCategory(
      id: categories.length + 1,
      storeId: storeId,
      name: name,
      isDeleted: false,
    );
    categories.add(category);
    return category;
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
    required int costPrice,
    required ProductType type,
    List<ProductVariantDraft>? variants,
    required List<int> toppingIds,
    required List<ProductRecipeDraft> recipes,
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
  Future<Product> updateProduct({
    required int productId,
    required int categoryId,
    required String name,
    required String imageUrl,
    required String description,
    required int preparationTime,
    required int price,
    required int costPrice,
    required ProductType type,
    List<ProductVariantDraft>? variants,
    required List<int> toppingIds,
    required List<ProductRecipeDraft> recipes,
  }) async {
    updateProductCallCount += 1;
    lastUpdatedProductName = name;
    lastUpdatedCategoryId = categoryId;
    lastVariants = variants;
    lastToppingIds = toppingIds;
    final product = Product(
      id: productId,
      storeId: 5,
      categoryId: categoryId,
      categoryName: 'Đồ uống',
      name: name,
      imageUrl: imageUrl,
      description: description,
      preparationTime: preparationTime,
      price: price,
      type: type,
      variants: variants ?? const [],
      toppings: toppings
          .where((topping) => toppingIds.contains(topping.id))
          .toList(),
      isSell: true,
      isDeleted: false,
    );
    final index = products.indexWhere((product) => product.id == productId);
    if (index != -1) {
      products[index] = product;
    }
    return product;
  }

  @override
  Future<void> updateProductSellStatus({
    required int productId,
    required bool isSell,
  }) async {}

  @override
  Future<void> deleteProduct(int productId) async {
    deleteProductCallCount += 1;
    products.removeWhere((product) => product.id == productId);
  }
}

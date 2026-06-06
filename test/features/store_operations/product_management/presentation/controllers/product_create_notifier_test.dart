import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quan_oi/features/store_operations/product_management/domain/entities/product.dart';
import 'package:quan_oi/features/store_operations/product_management/domain/entities/product_category.dart';
import 'package:quan_oi/features/store_operations/product_management/domain/entities/product_topping.dart';
import 'package:quan_oi/features/store_operations/product_management/domain/entities/product_type.dart';
import 'package:quan_oi/features/store_operations/product_management/domain/entities/product_variant_draft.dart';
import 'package:quan_oi/features/store_operations/product_management/domain/repositories/product_management_repository.dart';
import 'package:quan_oi/features/store_operations/product_management/domain/usecases/create_product_use_case.dart';
import 'package:quan_oi/features/store_operations/product_management/domain/usecases/load_product_categories_use_case.dart';
import 'package:quan_oi/features/store_operations/product_management/domain/usecases/load_product_toppings_use_case.dart';
import 'package:quan_oi/features/store_operations/product_management/presentation/controllers/product_create_state.dart';
import 'package:quan_oi/features/store_operations/product_management/presentation/providers/product_management_providers.dart';

void main() {
  test(
    'without create permission enters forbidden and skips repository',
    () async {
      final repository = _FakeProductCreateRepository();
      final container = _container(repository);
      addTearDown(container.dispose);

      final access = _access(canCreate: false);
      await container
          .read(productCreateNotifierProvider(access).notifier)
          .load();

      final state = container.read(productCreateNotifierProvider(access));

      expect(state.status, ProductCreateStatus.forbidden);
      expect(repository.loadCategoriesCallCount, 0);
      expect(repository.loadToppingsCallCount, 0);
    },
  );

  test('loads categories and toppings', () async {
    final repository = _FakeProductCreateRepository();
    final container = _container(repository);
    addTearDown(container.dispose);

    final access = _access();
    await container.read(productCreateNotifierProvider(access).notifier).load();

    final state = container.read(productCreateNotifierProvider(access));

    expect(state.status, ProductCreateStatus.ready);
    expect(state.categories.map((category) => category.name), ['Đồ uống']);
    expect(state.toppings.map((topping) => topping.name), [
      'Trân châu đen',
      'Pudding trứng',
    ]);
  });

  test(
    'submit without variants sends null variants and selected toppings',
    () async {
      final repository = _FakeProductCreateRepository();
      final container = _container(repository);
      addTearDown(container.dispose);

      final access = _access();
      final notifier = container.read(
        productCreateNotifierProvider(access).notifier,
      );
      await notifier.load();

      await notifier.submit(
        const ProductCreateInput(
          name: 'Trà sữa',
          categoryId: 1,
          type: ProductType.drink,
          description: 'Ngọt vừa',
          preparationTime: 5,
          basePrice: 30000,
          hasMultipleSizes: false,
          variants: [],
          toppingIds: [1, 2],
        ),
      );

      expect(repository.createProductCallCount, 1);
      expect(repository.lastVariants, isNull);
      expect(repository.lastToppingIds, [1, 2]);
      expect(repository.lastPrice, 30000);
    },
  );

  test('submit with variants sends S/M/L prices and default size', () async {
    final repository = _FakeProductCreateRepository();
    final container = _container(repository);
    addTearDown(container.dispose);

    final access = _access();
    final notifier = container.read(
      productCreateNotifierProvider(access).notifier,
    );
    await notifier.load();

    await notifier.submit(
      const ProductCreateInput(
        name: 'Trà sữa size',
        categoryId: 1,
        type: ProductType.drink,
        description: '',
        preparationTime: 5,
        basePrice: null,
        hasMultipleSizes: true,
        variants: [
          ProductVariantDraft(name: 'Size S', price: 25000, isDefault: false),
          ProductVariantDraft(name: 'Size M', price: 30000, isDefault: true),
          ProductVariantDraft(name: 'Size L', price: 35000, isDefault: false),
        ],
        toppingIds: [2],
      ),
    );

    expect(repository.lastPrice, 30000);
    expect(repository.lastVariants?.map((variant) => variant.name), [
      'Size S',
      'Size M',
      'Size L',
    ]);
    expect(
      repository.lastVariants?.singleWhere((variant) => variant.isDefault).name,
      'Size M',
    );
    expect(repository.lastToppingIds, [2]);
  });

  test(
    'validates required fields and variants before repository call',
    () async {
      final repository = _FakeProductCreateRepository();
      final container = _container(repository);
      addTearDown(container.dispose);

      final access = _access();
      final notifier = container.read(
        productCreateNotifierProvider(access).notifier,
      );
      await notifier.load();

      await expectLater(
        notifier.submit(
          const ProductCreateInput(
            name: '',
            categoryId: 1,
            type: ProductType.drink,
            description: '',
            preparationTime: 0,
            basePrice: 10000,
            hasMultipleSizes: false,
            variants: [],
            toppingIds: [],
          ),
        ),
        throwsA(isA<Exception>()),
      );

      await expectLater(
        notifier.submit(
          const ProductCreateInput(
            name: 'Trà sữa',
            categoryId: 1,
            type: ProductType.drink,
            description: '',
            preparationTime: 0,
            basePrice: null,
            hasMultipleSizes: false,
            variants: [],
            toppingIds: [],
          ),
        ),
        throwsA(isA<Exception>()),
      );

      await expectLater(
        notifier.submit(
          const ProductCreateInput(
            name: 'Trà sữa',
            categoryId: 1,
            type: ProductType.drink,
            description: '',
            preparationTime: 0,
            basePrice: null,
            hasMultipleSizes: true,
            variants: [],
            toppingIds: [],
          ),
        ),
        throwsA(isA<Exception>()),
      );

      expect(repository.createProductCallCount, 0);
    },
  );
}

ProviderContainer _container(_FakeProductCreateRepository repository) {
  return ProviderContainer(
    overrides: [
      loadProductCategoriesUseCaseProvider.overrideWithValue(
        LoadProductCategoriesUseCase(repository),
      ),
      loadProductToppingsUseCaseProvider.overrideWithValue(
        LoadProductToppingsUseCase(repository),
      ),
      createProductUseCaseProvider.overrideWithValue(
        CreateProductUseCase(repository),
      ),
    ],
  );
}

ProductCreateAccess _access({bool canCreate = true}) {
  return ProductCreateAccess(storeId: 5, canCreateProduct: canCreate);
}

class _FakeProductCreateRepository implements ProductManagementRepository {
  int loadCategoriesCallCount = 0;
  int loadToppingsCallCount = 0;
  int createProductCallCount = 0;
  int? lastPrice;
  List<ProductVariantDraft>? lastVariants;
  List<int>? lastToppingIds;

  @override
  Future<List<ProductCategory>> loadCategories(int storeId) async {
    loadCategoriesCallCount += 1;
    return const [
      ProductCategory(id: 1, storeId: 5, name: 'Đồ uống', isDeleted: false),
    ];
  }

  @override
  Future<List<ProductTopping>> loadToppings(int storeId) async {
    loadToppingsCallCount += 1;
    return const [
      ProductTopping(
        id: 1,
        storeId: 5,
        name: 'Trân châu đen',
        price: 5000,
        isDeleted: false,
      ),
      ProductTopping(
        id: 2,
        storeId: 5,
        name: 'Pudding trứng',
        price: 7000,
        isDeleted: false,
      ),
    ];
  }

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
    lastPrice = price;
    lastVariants = variants;
    lastToppingIds = toppingIds;
    return Product(
      id: 9,
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
  Future<ProductCategory> createCategory({
    required int storeId,
    required String name,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<void> deleteCategory(int categoryId) {
    throw UnimplementedError();
  }

  @override
  Future<void> deleteProduct(int productId) {
    throw UnimplementedError();
  }

  @override
  Future<List<Product>> loadProducts(int storeId) {
    throw UnimplementedError();
  }

  @override
  Future<ProductCategory> updateCategory({
    required int categoryId,
    required String name,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<void> updateProductSellStatus({
    required int productId,
    required bool isSell,
  }) {
    throw UnimplementedError();
  }
}

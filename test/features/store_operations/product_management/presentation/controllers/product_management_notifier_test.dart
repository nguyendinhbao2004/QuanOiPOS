import 'package:flutter_test/flutter_test.dart';
import 'package:quan_oi/features/store_operations/product_management/domain/entities/product.dart';
import 'package:quan_oi/features/store_operations/product_management/domain/entities/product_category.dart';
import 'package:quan_oi/features/store_operations/product_management/domain/entities/product_ingredient.dart';
import 'package:quan_oi/features/store_operations/product_management/domain/entities/product_recipe_draft.dart';
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
import 'package:quan_oi/features/store_operations/product_management/presentation/controllers/product_management_state.dart';
import 'package:quan_oi/features/store_operations/product_management/presentation/providers/product_management_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

void main() {
  test(
    'without product view permission enters forbidden and skips repository',
    () async {
      final repository = _FakeProductManagementRepository();
      final container = _container(repository);
      addTearDown(container.dispose);

      final access = _access(canView: false);
      await container
          .read(productManagementNotifierProvider(access).notifier)
          .load();

      final state = container.read(productManagementNotifierProvider(access));

      expect(state.status, ProductManagementStatus.forbidden);
      expect(repository.loadCategoriesCallCount, 0);
      expect(repository.loadProductsCallCount, 0);
      expect(repository.loadToppingsCallCount, 0);
    },
  );

  test(
    'loads categories, products and toppings when create is allowed',
    () async {
      final repository = _FakeProductManagementRepository();
      final container = _container(repository);
      addTearDown(container.dispose);

      final access = _access();
      await container
          .read(productManagementNotifierProvider(access).notifier)
          .load();

      final state = container.read(productManagementNotifierProvider(access));

      expect(state.status, ProductManagementStatus.ready);
      expect(state.categories.map((category) => category.name), [
        'Đồ uống',
        'Thực phẩm',
      ]);
      expect(state.products.map((product) => product.name), [
        'Trà sữa trân châu',
        'Bánh mì',
      ]);
      expect(state.toppings.map((topping) => topping.name), ['Trân châu đen']);
      expect(repository.loadToppingsCallCount, 1);
    },
  );

  test('skips topping preload when create is not allowed', () async {
    final repository = _FakeProductManagementRepository();
    final container = _container(repository);
    addTearDown(container.dispose);

    final access = _access(canCreate: false);
    await container
        .read(productManagementNotifierProvider(access).notifier)
        .load();

    final state = container.read(productManagementNotifierProvider(access));

    expect(state.status, ProductManagementStatus.ready);
    expect(state.toppings, isEmpty);
    expect(repository.loadToppingsCallCount, 0);
  });

  test('filters products by category and local search query', () async {
    final repository = _FakeProductManagementRepository();
    final container = _container(repository);
    addTearDown(container.dispose);

    final access = _access();
    final notifier = container.read(
      productManagementNotifierProvider(access).notifier,
    );
    await notifier.load();

    notifier.selectCategory(1);
    notifier.setQuery('trân');

    final state = container.read(productManagementNotifierProvider(access));

    expect(state.visibleProducts.map((product) => product.name), [
      'Trà sữa trân châu',
    ]);
  });

  test('category mutations are blocked without matching permissions', () async {
    final repository = _FakeProductManagementRepository();
    final container = _container(repository);
    addTearDown(container.dispose);

    final access = _access(
      canCreate: false,
      canUpdate: false,
      canDelete: false,
    );
    final notifier = container.read(
      productManagementNotifierProvider(access).notifier,
    );
    await notifier.load();

    await expectLater(
      notifier.createCategory(name: 'Mới'),
      throwsA(isA<Exception>()),
    );
    await expectLater(
      notifier.updateCategory(categoryId: 1, name: 'Mới'),
      throwsA(isA<Exception>()),
    );
    await expectLater(notifier.deleteCategory(1), throwsA(isA<Exception>()));
    expect(repository.createCategoryCallCount, 0);
    expect(repository.updateCategoryCallCount, 0);
    expect(repository.deleteCategoryCallCount, 0);
  });

  test(
    'product delete and sell toggle are blocked without permissions',
    () async {
      final repository = _FakeProductManagementRepository();
      final container = _container(repository);
      addTearDown(container.dispose);

      final access = _access(canUpdate: false, canDelete: false);
      final notifier = container.read(
        productManagementNotifierProvider(access).notifier,
      );
      await notifier.load();

      await expectLater(
        notifier.updateProductSellStatus(productId: 1, isSell: false),
        throwsA(isA<Exception>()),
      );
      await expectLater(notifier.deleteProduct(1), throwsA(isA<Exception>()));
      expect(repository.updateSellStatusCallCount, 0);
      expect(repository.deleteProductCallCount, 0);
    },
  );
}

ProviderContainer _container(_FakeProductManagementRepository repository) {
  return ProviderContainer(
    overrides: [
      loadProductCategoriesUseCaseProvider.overrideWithValue(
        LoadProductCategoriesUseCase(repository),
      ),
      loadProductToppingsUseCaseProvider.overrideWithValue(
        LoadProductToppingsUseCase(repository),
      ),
      createProductCategoryUseCaseProvider.overrideWithValue(
        CreateProductCategoryUseCase(repository),
      ),
      updateProductCategoryUseCaseProvider.overrideWithValue(
        UpdateProductCategoryUseCase(repository),
      ),
      deleteProductCategoryUseCaseProvider.overrideWithValue(
        DeleteProductCategoryUseCase(repository),
      ),
      loadProductsUseCaseProvider.overrideWithValue(
        LoadProductsUseCase(repository),
      ),
      createProductUseCaseProvider.overrideWithValue(
        CreateProductUseCase(repository),
      ),
      updateProductSellStatusUseCaseProvider.overrideWithValue(
        UpdateProductSellStatusUseCase(repository),
      ),
      deleteProductUseCaseProvider.overrideWithValue(
        DeleteProductUseCase(repository),
      ),
    ],
  );
}

ProductManagementAccess _access({
  bool canView = true,
  bool canCreate = true,
  bool canUpdate = true,
  bool canDelete = true,
}) {
  return ProductManagementAccess(
    storeId: 5,
    canViewProduct: canView,
    canCreateProduct: canCreate,
    canUpdateProduct: canUpdate,
    canDeleteProduct: canDelete,
  );
}

class _FakeProductManagementRepository implements ProductManagementRepository {
  int loadCategoriesCallCount = 0;
  int createCategoryCallCount = 0;
  int updateCategoryCallCount = 0;
  int deleteCategoryCallCount = 0;
  int loadToppingsCallCount = 0;
  int createToppingCallCount = 0;
  int updateToppingCallCount = 0;
  int deleteToppingCallCount = 0;
  int loadProductsCallCount = 0;
  int loadProductDetailCallCount = 0;
  int createProductCallCount = 0;
  int updateProductCallCount = 0;
  int updateSellStatusCallCount = 0;
  int deleteProductCallCount = 0;

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
    const Product(
      id: 2,
      storeId: 5,
      categoryId: 2,
      categoryName: 'Thực phẩm',
      name: 'Bánh mì',
      imageUrl: '',
      description: 'Bánh mì nóng',
      preparationTime: 3,
      price: 20000,
      type: ProductType.food,
      isSell: true,
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
    return const [
      ProductTopping(
        id: 1,
        storeId: 5,
        name: 'Trân châu đen',
        price: 5000,
        isDeleted: false,
      ),
    ];
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
    return ProductTopping(
      id: 9,
      storeId: storeId,
      name: name,
      price: price,
      isDeleted: false,
    );
  }

  @override
  Future<ProductTopping> updateTopping({
    required int toppingId,
    required String name,
    required int price,
  }) async {
    updateToppingCallCount += 1;
    return ProductTopping(
      id: toppingId,
      storeId: 5,
      name: name,
      price: price,
      isDeleted: false,
    );
  }

  @override
  Future<void> deleteTopping(int toppingId) async {
    deleteToppingCallCount += 1;
  }

  @override
  Future<ProductCategory> createCategory({
    required int storeId,
    required String name,
  }) async {
    createCategoryCallCount += 1;
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
    updateCategoryCallCount += 1;
    return ProductCategory(
      id: categoryId,
      storeId: 5,
      name: name,
      isDeleted: false,
    );
  }

  @override
  Future<void> deleteCategory(int categoryId) async {
    deleteCategoryCallCount += 1;
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
    return Product(
      id: products.length + 1,
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
    return Product(
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
      isSell: true,
      isDeleted: false,
    );
  }

  @override
  Future<void> updateProductSellStatus({
    required int productId,
    required bool isSell,
  }) async {
    updateSellStatusCallCount += 1;
  }

  @override
  Future<void> deleteProduct(int productId) async {
    deleteProductCallCount += 1;
  }
}

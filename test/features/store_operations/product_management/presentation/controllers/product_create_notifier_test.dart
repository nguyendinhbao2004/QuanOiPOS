import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quan_oi/features/store_operations/product_management/domain/entities/product.dart';
import 'package:quan_oi/features/store_operations/product_management/domain/entities/product_category.dart';
import 'package:quan_oi/features/store_operations/product_management/domain/entities/inventory_deduction_mode.dart';
import 'package:quan_oi/features/store_operations/product_management/domain/entities/inventory_item_settings.dart';
import 'package:quan_oi/features/store_operations/product_management/domain/entities/product_ingredient.dart';
import 'package:quan_oi/features/store_operations/product_management/domain/entities/product_image_upload.dart';
import 'package:quan_oi/features/store_operations/product_management/domain/entities/product_recipe_draft.dart';
import 'package:quan_oi/features/store_operations/product_management/domain/entities/product_topping.dart';
import 'package:quan_oi/features/store_operations/product_management/domain/entities/product_type.dart';
import 'package:quan_oi/features/store_operations/product_management/domain/entities/product_variant_draft.dart';
import 'package:quan_oi/features/store_operations/product_management/domain/repositories/product_management_repository.dart';
import 'package:quan_oi/features/store_operations/product_management/domain/usecases/create_product_category_use_case.dart';
import 'package:quan_oi/features/store_operations/product_management/domain/usecases/create_product_ingredient_use_case.dart';
import 'package:quan_oi/features/store_operations/product_management/domain/usecases/create_product_topping_use_case.dart';
import 'package:quan_oi/features/store_operations/product_management/domain/usecases/create_product_use_case.dart';
import 'package:quan_oi/features/store_operations/product_management/domain/usecases/delete_product_topping_use_case.dart';
import 'package:quan_oi/features/store_operations/product_management/domain/usecases/delete_product_ingredient_use_case.dart';
import 'package:quan_oi/features/store_operations/product_management/domain/usecases/load_product_categories_use_case.dart';
import 'package:quan_oi/features/store_operations/product_management/domain/usecases/load_product_detail_use_case.dart';
import 'package:quan_oi/features/store_operations/product_management/domain/usecases/load_product_ingredients_use_case.dart';
import 'package:quan_oi/features/store_operations/product_management/domain/usecases/load_ingredient_inventory_settings_use_case.dart';
import 'package:quan_oi/features/store_operations/product_management/domain/usecases/load_product_inventory_settings_use_case.dart';
import 'package:quan_oi/features/store_operations/product_management/domain/usecases/load_product_toppings_use_case.dart';
import 'package:quan_oi/features/store_operations/product_management/domain/usecases/replace_product_recipe_use_case.dart';
import 'package:quan_oi/features/store_operations/product_management/domain/usecases/update_ingredient_inventory_settings_use_case.dart';
import 'package:quan_oi/features/store_operations/product_management/domain/usecases/update_product_inventory_settings_use_case.dart';
import 'package:quan_oi/features/store_operations/product_management/domain/usecases/update_product_topping_use_case.dart';
import 'package:quan_oi/features/store_operations/product_management/domain/usecases/update_product_ingredient_use_case.dart';
import 'package:quan_oi/features/store_operations/product_management/domain/usecases/update_product_use_case.dart';
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

  test('uses seed data without loading categories and toppings', () async {
    final repository = _FakeProductCreateRepository();
    final container = _container(repository);
    addTearDown(container.dispose);

    final access = ProductCreateAccess(
      storeId: 5,
      canCreateProduct: true,
      seedData: ProductCreateSeedData(
        categories: repository.categories,
        toppings: repository.toppings,
      ),
    );

    final state = container.read(productCreateNotifierProvider(access));

    expect(state.status, ProductCreateStatus.ready);
    expect(state.categories.map((category) => category.name), ['Đồ uống']);
    expect(state.toppings.map((topping) => topping.name), [
      'Trân châu đen',
      'Pudding trứng',
    ]);
    expect(repository.loadCategoriesCallCount, 0);
    expect(repository.loadToppingsCallCount, 0);
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
      expect(repository.updateProductInventorySettingsCallCount, 1);
      expect(repository.lastMinimumStock, 0);
      expect(
        repository.lastInventoryDeductionMode,
        InventoryDeductionMode.recipeOnly,
      );
    },
  );

  test(
    'submit with dynamic variants sends names, prices and default flag',
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
          name: 'Trà sữa size',
          categoryId: 1,
          type: ProductType.drink,
          description: '',
          preparationTime: 5,
          basePrice: null,
          hasMultipleSizes: true,
          variants: [
            ProductVariantDraft(
              name: 'Rau muống',
              price: 5000,
              isDefault: false,
            ),
            ProductVariantDraft(name: 'Rau cải', price: 7000, isDefault: true),
          ],
          toppingIds: [2],
        ),
      );

      expect(repository.lastPrice, 0);
      expect(repository.lastCostPrice, 0);
      expect(repository.lastVariants?.map((variant) => variant.name), [
        'Rau muống',
        'Rau cải',
      ]);
      expect(
        repository.lastVariants
            ?.singleWhere((variant) => variant.isDefault)
            .name,
        'Rau cải',
      );
      expect(repository.lastToppingIds, [2]);
    },
  );

  test('submit with dynamic variants allows no default option', () async {
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
        name: 'Trà sữa topping',
        categoryId: 1,
        type: ProductType.drink,
        description: '',
        preparationTime: 5,
        basePrice: null,
        hasMultipleSizes: true,
        variants: [
          ProductVariantDraft(name: 'Ít đá', price: 25000, isDefault: false),
          ProductVariantDraft(name: 'Nhiều đá', price: 30000, isDefault: false),
        ],
        toppingIds: [],
      ),
    );

    expect(repository.createProductCallCount, 1);
    expect(repository.lastPrice, 0);
    expect(repository.lastCostPrice, 0);
    expect(
      repository.lastVariants?.every((variant) => !variant.isDefault),
      isTrue,
    );
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

  test('update with dynamic variants sends current variants', () async {
    final repository = _FakeProductCreateRepository();
    final container = _container(repository);
    addTearDown(container.dispose);

    final access = _editingAccess(repository);
    final notifier = container.read(
      productCreateNotifierProvider(access).notifier,
    );
    await notifier.load();

    await notifier.update(
      const ProductCreateInput(
        name: 'Trà sữa size mới',
        categoryId: 1,
        type: ProductType.drink,
        description: '',
        preparationTime: 5,
        basePrice: null,
        hasMultipleSizes: true,
        variants: [
          ProductVariantDraft(name: 'Size M', price: 30000, isDefault: false),
          ProductVariantDraft(name: 'Size L', price: 35000, isDefault: true),
        ],
        toppingIds: [1],
      ),
    );

    expect(repository.updateProductCallCount, 1);
    expect(repository.lastPrice, 0);
    expect(repository.lastCostPrice, 0);
    expect(repository.lastVariants?.map((variant) => variant.name), [
      'Size M',
      'Size L',
    ]);
    expect(
      repository.lastVariants?.singleWhere((variant) => variant.isDefault).name,
      'Size L',
    );
    expect(repository.lastToppingIds, [1]);
    expect(repository.replaceProductRecipeCallCount, 1);
    expect(repository.updateProductInventorySettingsCallCount, 1);
  });

  test('update can clear variants when all size rows are removed', () async {
    final repository = _FakeProductCreateRepository();
    final container = _container(repository);
    addTearDown(container.dispose);

    final access = _editingAccess(repository);
    final notifier = container.read(
      productCreateNotifierProvider(access).notifier,
    );
    await notifier.load();

    await notifier.update(
      const ProductCreateInput(
        name: 'Trà sữa mặc định',
        categoryId: 1,
        type: ProductType.drink,
        description: '',
        preparationTime: 5,
        basePrice: 25000,
        hasMultipleSizes: true,
        variants: [],
        toppingIds: [],
      ),
    );

    expect(repository.updateProductCallCount, 1);
    expect(repository.lastVariants, isEmpty);
    expect(repository.lastPrice, 25000);
  });

  test('update sends empty variants when multi size is disabled', () async {
    final repository = _FakeProductCreateRepository();
    final container = _container(repository);
    addTearDown(container.dispose);

    final access = _editingAccess(repository);
    final notifier = container.read(
      productCreateNotifierProvider(access).notifier,
    );
    await notifier.load();

    await notifier.update(
      const ProductCreateInput(
        name: 'Trà sữa một giá',
        categoryId: 1,
        type: ProductType.drink,
        description: '',
        preparationTime: 5,
        basePrice: 28000,
        hasMultipleSizes: false,
        variants: [
          ProductVariantDraft(name: 'Size L', price: 35000, isDefault: true),
        ],
        toppingIds: [2],
      ),
    );

    expect(repository.updateProductCallCount, 1);
    expect(repository.lastVariants, isEmpty);
    expect(repository.lastToppingIds, [2]);
  });

  test('update rejects incomplete variant rows', () async {
    final repository = _FakeProductCreateRepository();
    final container = _container(repository);
    addTearDown(container.dispose);

    final access = _editingAccess(repository);
    final notifier = container.read(
      productCreateNotifierProvider(access).notifier,
    );
    await notifier.load();

    await expectLater(
      notifier.update(
        const ProductCreateInput(
          name: 'Trà sữa lỗi size',
          categoryId: 1,
          type: ProductType.drink,
          description: '',
          preparationTime: 5,
          basePrice: null,
          hasMultipleSizes: true,
          variants: [
            ProductVariantDraft(name: 'Size M', price: 30000, isDefault: true),
            ProductVariantDraft(name: '', price: 0, isDefault: false),
          ],
          toppingIds: [],
        ),
      ),
      throwsA(isA<Exception>()),
    );

    expect(repository.updateProductCallCount, 0);
  });

  test('creates category and updates state', () async {
    final repository = _FakeProductCreateRepository();
    final container = _container(repository);
    addTearDown(container.dispose);

    final access = _access();
    final notifier = container.read(
      productCreateNotifierProvider(access).notifier,
    );
    await notifier.load();

    final category = await notifier.createCategory(name: 'Bánh ngọt');
    final state = container.read(productCreateNotifierProvider(access));

    expect(category.name, 'Bánh ngọt');
    expect(repository.createCategoryCallCount, 1);
    expect(state.categories.map((item) => item.name), ['Đồ uống', 'Bánh ngọt']);
  });

  test('topping mutations update state', () async {
    final repository = _FakeProductCreateRepository();
    final container = _container(repository);
    addTearDown(container.dispose);

    final access = _access();
    final notifier = container.read(
      productCreateNotifierProvider(access).notifier,
    );
    await notifier.load();

    final created = await notifier.createTopping(
      name: 'Kem cheese',
      price: 9000,
    );
    await notifier.updateTopping(
      toppingId: created.id,
      name: 'Kem cheese mặn',
      price: 10000,
    );
    await notifier.deleteTopping(created.id);

    final state = container.read(productCreateNotifierProvider(access));

    expect(repository.createToppingCallCount, 1);
    expect(repository.updateToppingCallCount, 1);
    expect(repository.deleteToppingCallCount, 1);
    expect(state.toppings.any((topping) => topping.id == created.id), isFalse);
  });

  test('topping mutations are blocked without matching permissions', () async {
    final repository = _FakeProductCreateRepository();
    final container = _container(repository);
    addTearDown(container.dispose);

    final access = _access(
      canCreate: false,
      canUpdate: false,
      canDelete: false,
    );
    final notifier = container.read(
      productCreateNotifierProvider(access).notifier,
    );

    await expectLater(
      notifier.createTopping(name: 'Kem cheese', price: 9000),
      throwsA(isA<Exception>()),
    );
    await expectLater(
      notifier.updateTopping(toppingId: 1, name: 'Kem cheese', price: 9000),
      throwsA(isA<Exception>()),
    );
    await expectLater(notifier.deleteTopping(1), throwsA(isA<Exception>()));
    expect(repository.createToppingCallCount, 0);
    expect(repository.updateToppingCallCount, 0);
    expect(repository.deleteToppingCallCount, 0);
  });

  test('ingredient mutations update state', () async {
    final repository = _FakeProductCreateRepository();
    final container = _container(repository);
    addTearDown(container.dispose);

    final access = _access();
    final notifier = container.read(
      productCreateNotifierProvider(access).notifier,
    );
    await notifier.load();

    final created = await notifier.createIngredient(
      name: 'Sữa tươi',
      itemType: 1,
      unit: 'chai',
      capacity: 1000,
      minimumStock: 3,
      isTrackInventory: true,
    );
    await notifier.updateIngredient(
      ingredientId: created.id,
      name: 'Sữa tươi không đường',
      itemType: 1,
      unit: 'chai',
      capacity: 900,
      minimumStock: 2,
      isTrackInventory: false,
    );
    await notifier.deleteIngredient(created.id);

    final state = container.read(productCreateNotifierProvider(access));

    expect(repository.createIngredientCallCount, 1);
    expect(repository.updateIngredientCallCount, 1);
    expect(repository.updateIngredientInventorySettingsCallCount, 2);
    expect(repository.deleteIngredientCallCount, 1);
    expect(
      state.ingredients.any((ingredient) => ingredient.id == created.id),
      isFalse,
    );
  });

  test(
    'ingredient mutations are blocked without matching permissions',
    () async {
      final repository = _FakeProductCreateRepository();
      final container = _container(repository);
      addTearDown(container.dispose);

      final access = _access(
        canCreate: false,
        canUpdate: false,
        canDelete: false,
      );
      final notifier = container.read(
        productCreateNotifierProvider(access).notifier,
      );

      await expectLater(
        notifier.createIngredient(
          name: 'Sữa tươi',
          itemType: 1,
          unit: 'chai',
          capacity: 1000,
          minimumStock: 0,
          isTrackInventory: false,
        ),
        throwsA(isA<Exception>()),
      );
      await expectLater(
        notifier.updateIngredient(
          ingredientId: 1,
          name: 'Sữa tươi',
          itemType: 1,
          unit: 'chai',
          capacity: 1000,
          minimumStock: 0,
          isTrackInventory: false,
        ),
        throwsA(isA<Exception>()),
      );
      await expectLater(
        notifier.deleteIngredient(1),
        throwsA(isA<Exception>()),
      );
      expect(repository.createIngredientCallCount, 0);
      expect(repository.updateIngredientCallCount, 0);
      expect(repository.deleteIngredientCallCount, 0);
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
      loadProductIngredientsUseCaseProvider.overrideWithValue(
        LoadProductIngredientsUseCase(repository),
      ),
      loadIngredientInventorySettingsUseCaseProvider.overrideWithValue(
        LoadIngredientInventorySettingsUseCase(repository),
      ),
      loadProductInventorySettingsUseCaseProvider.overrideWithValue(
        LoadProductInventorySettingsUseCase(repository),
      ),
      createProductCategoryUseCaseProvider.overrideWithValue(
        CreateProductCategoryUseCase(repository),
      ),
      createProductIngredientUseCaseProvider.overrideWithValue(
        CreateProductIngredientUseCase(repository),
      ),
      updateProductIngredientUseCaseProvider.overrideWithValue(
        UpdateProductIngredientUseCase(repository),
      ),
      deleteProductIngredientUseCaseProvider.overrideWithValue(
        DeleteProductIngredientUseCase(repository),
      ),
      updateIngredientInventorySettingsUseCaseProvider.overrideWithValue(
        UpdateIngredientInventorySettingsUseCase(repository),
      ),
      createProductToppingUseCaseProvider.overrideWithValue(
        CreateProductToppingUseCase(repository),
      ),
      updateProductToppingUseCaseProvider.overrideWithValue(
        UpdateProductToppingUseCase(repository),
      ),
      deleteProductToppingUseCaseProvider.overrideWithValue(
        DeleteProductToppingUseCase(repository),
      ),
      createProductUseCaseProvider.overrideWithValue(
        CreateProductUseCase(repository),
      ),
      loadProductDetailUseCaseProvider.overrideWithValue(
        LoadProductDetailUseCase(repository),
      ),
      updateProductUseCaseProvider.overrideWithValue(
        UpdateProductUseCase(repository),
      ),
      updateProductInventorySettingsUseCaseProvider.overrideWithValue(
        UpdateProductInventorySettingsUseCase(repository),
      ),
      replaceProductRecipeUseCaseProvider.overrideWithValue(
        ReplaceProductRecipeUseCase(repository),
      ),
    ],
  );
}

ProductCreateAccess _access({
  bool canCreate = true,
  bool canUpdate = true,
  bool canDelete = true,
}) {
  return ProductCreateAccess(
    storeId: 5,
    canCreateProduct: canCreate,
    canUpdateProduct: canUpdate,
    canDeleteProduct: canDelete,
  );
}

ProductCreateAccess _editingAccess(_FakeProductCreateRepository repository) {
  return ProductCreateAccess(
    storeId: 5,
    canCreateProduct: true,
    canUpdateProduct: true,
    canDeleteProduct: true,
    seedData: ProductCreateSeedData(
      categories: repository.categories,
      toppings: repository.toppings,
      editingProduct: const Product(
        id: 7,
        storeId: 5,
        categoryId: 1,
        categoryName: 'Đồ uống',
        name: 'Trà sữa trân châu',
        imageUrl: '',
        description: 'Trà sữa',
        preparationTime: 5,
        price: 25000,
        type: ProductType.drink,
        variants: [
          ProductVariantDraft(name: 'Size M', price: 30000, isDefault: true),
        ],
        isSell: true,
        isDeleted: false,
      ),
    ),
  );
}

class _FakeProductCreateRepository implements ProductManagementRepository {
  int loadCategoriesCallCount = 0;
  int loadToppingsCallCount = 0;
  int loadProductDetailCallCount = 0;
  int loadIngredientsCallCount = 0;
  int createCategoryCallCount = 0;
  int createToppingCallCount = 0;
  int updateToppingCallCount = 0;
  int deleteToppingCallCount = 0;
  int createIngredientCallCount = 0;
  int updateIngredientCallCount = 0;
  int updateIngredientInventorySettingsCallCount = 0;
  int deleteIngredientCallCount = 0;
  int createProductCallCount = 0;
  int updateProductCallCount = 0;
  int updateProductInventorySettingsCallCount = 0;
  int replaceProductRecipeCallCount = 0;
  int? lastPrice;
  int? lastCostPrice;
  double? lastMinimumStock;
  bool? lastIsTrackInventory;
  InventoryDeductionMode? lastInventoryDeductionMode;
  List<ProductVariantDraft>? lastVariants;
  List<int>? lastToppingIds;
  List<ProductRecipeDraft>? lastRecipes;

  final categories = <ProductCategory>[
    ProductCategory(id: 1, storeId: 5, name: 'Đồ uống', isDeleted: false),
  ];

  final toppings = <ProductTopping>[
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

  final ingredients = <ProductIngredient>[
    const ProductIngredient(
      id: 1,
      storeId: 5,
      name: 'Trà',
      itemType: 1,
      unit: 'gram',
      quantity: 10,
      capacity: 1000,
      currentCapacity: 500,
      isActive: true,
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
  Future<List<ProductIngredient>> loadIngredients(int storeId) async {
    loadIngredientsCallCount += 1;
    return [...ingredients];
  }

  @override
  Future<List<IngredientInventorySettings>> loadIngredientInventorySettings(
    int storeId,
  ) async {
    return ingredients
        .map(
          (ingredient) => IngredientInventorySettings(
            ingredientId: ingredient.id,
            minimumStock: ingredient.minimumStock,
            isTrackInventory: ingredient.isTrackInventory,
          ),
        )
        .toList();
  }

  @override
  Future<List<ProductInventorySettings>> loadProductInventorySettings(
    int storeId,
  ) async => const [];

  @override
  Future<ProductIngredient> createIngredient({
    required int storeId,
    required String name,
    required int itemType,
    required String unit,
    required int capacity,
  }) async {
    createIngredientCallCount += 1;
    final ingredient = ProductIngredient(
      id: ingredients.length + 1,
      storeId: storeId,
      name: name,
      itemType: itemType,
      unit: unit,
      quantity: 0,
      capacity: capacity,
      currentCapacity: capacity,
      isActive: true,
      isDeleted: false,
    );
    ingredients.add(ingredient);
    return ingredient;
  }

  @override
  Future<ProductIngredient> updateIngredient({
    required int ingredientId,
    required String name,
    required int itemType,
    required String unit,
    required int capacity,
  }) async {
    updateIngredientCallCount += 1;
    final ingredient = ProductIngredient(
      id: ingredientId,
      storeId: 5,
      name: name,
      itemType: itemType,
      unit: unit,
      quantity: 0,
      capacity: capacity,
      currentCapacity: capacity,
      isActive: true,
      isDeleted: false,
    );
    final index = ingredients.indexWhere((item) => item.id == ingredientId);
    if (index != -1) {
      ingredients[index] = ingredient;
    }
    return ingredient;
  }

  @override
  Future<void> deleteIngredient(int ingredientId) async {
    deleteIngredientCallCount += 1;
    ingredients.removeWhere((ingredient) => ingredient.id == ingredientId);
  }

  @override
  Future<void> updateIngredientInventorySettings({
    required int ingredientId,
    required double minimumStock,
    required bool isTrackInventory,
  }) async {
    updateIngredientInventorySettingsCallCount += 1;
    lastMinimumStock = minimumStock;
    lastIsTrackInventory = isTrackInventory;
    final index = ingredients.indexWhere((item) => item.id == ingredientId);
    if (index != -1) {
      ingredients[index] = ingredients[index].copyWith(
        minimumStock: minimumStock,
        isTrackInventory: isTrackInventory,
      );
    }
  }

  @override
  Future<Product> loadProductDetail(int productId) async {
    loadProductDetailCallCount += 1;
    return Product(
      id: productId,
      storeId: 5,
      categoryId: 1,
      categoryName: 'Đồ uống',
      name: 'Trà sữa trân châu',
      imageUrl: '',
      description: 'Trà sữa',
      preparationTime: 5,
      price: 25000,
      type: ProductType.drink,
      toppings: toppings.take(1).toList(),
      isSell: true,
      isDeleted: false,
    );
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
  Future<Product> createProduct({
    required int storeId,
    required int categoryId,
    required String name,
    ProductImageUpload? imageUpload,
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
    lastPrice = price;
    lastCostPrice = costPrice;
    lastVariants = variants;
    lastToppingIds = toppingIds;
    lastRecipes = recipes;
    return Product(
      id: 9,
      storeId: storeId,
      categoryId: categoryId,
      categoryName: 'Đồ uống',
      name: name,
      imageUrl: imageUpload == null ? '' : 'https://cdn.example/product.jpg',
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
    required int storeId,
    required int categoryId,
    required String name,
    required String existingImageUrl,
    ProductImageUpload? imageUpload,
    required String description,
    required int preparationTime,
    required int price,
    required int costPrice,
    required ProductType type,
    List<ProductVariantDraft>? variants,
    required List<int> toppingIds,
  }) async {
    updateProductCallCount += 1;
    lastPrice = price;
    lastCostPrice = costPrice;
    lastVariants = variants;
    lastToppingIds = toppingIds;
    return Product(
      id: productId,
      storeId: 5,
      categoryId: categoryId,
      categoryName: 'Đồ uống',
      name: name,
      imageUrl: imageUpload == null
          ? existingImageUrl
          : 'https://cdn.example/product.jpg',
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
  }

  @override
  Future<void> deleteCategory(int categoryId) {
    throw UnimplementedError();
  }

  @override
  Future<void> updateProductInventorySettings({
    required int productId,
    required double minimumStock,
    required bool isTrackInventory,
    required InventoryDeductionMode inventoryDeductionMode,
  }) async {
    updateProductInventorySettingsCallCount += 1;
    lastMinimumStock = minimumStock;
    lastIsTrackInventory = isTrackInventory;
    lastInventoryDeductionMode = inventoryDeductionMode;
  }

  @override
  Future<void> replaceProductRecipe({
    required int productId,
    required List<ProductRecipeDraft> recipes,
  }) async {
    replaceProductRecipeCallCount += 1;
    lastRecipes = recipes;
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

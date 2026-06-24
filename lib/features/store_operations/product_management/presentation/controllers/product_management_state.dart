import '../../domain/entities/product.dart';
import '../../domain/entities/product_category.dart';
import '../../domain/entities/product_ingredient.dart';
import '../../domain/entities/product_topping.dart';

enum ProductManagementStatus { initial, loading, ready, forbidden, error }

enum ProductManagementTab {
  products('Sản phẩm'),
  ingredients('Nguyên liệu'),
  categories('Danh mục');

  final String label;

  const ProductManagementTab(this.label);
}

class ProductManagementAccess {
  final int storeId;
  final bool canViewProduct;
  final bool canCreateProduct;
  final bool canUpdateProduct;
  final bool canDeleteProduct;

  const ProductManagementAccess({
    required this.storeId,
    required this.canViewProduct,
    required this.canCreateProduct,
    required this.canUpdateProduct,
    required this.canDeleteProduct,
  });

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is ProductManagementAccess &&
            runtimeType == other.runtimeType &&
            storeId == other.storeId &&
            canViewProduct == other.canViewProduct &&
            canCreateProduct == other.canCreateProduct &&
            canUpdateProduct == other.canUpdateProduct &&
            canDeleteProduct == other.canDeleteProduct;
  }

  @override
  int get hashCode => Object.hash(
    storeId,
    canViewProduct,
    canCreateProduct,
    canUpdateProduct,
    canDeleteProduct,
  );
}

class ProductManagementState {
  final ProductManagementStatus status;
  final List<ProductCategory> categories;
  final List<ProductTopping> toppings;
  final List<ProductIngredient> ingredients;
  final List<Product> products;
  final ProductManagementTab selectedTab;
  final int? selectedCategoryId;
  final String query;
  final String? errorMessage;

  const ProductManagementState({
    required this.status,
    this.categories = const [],
    this.toppings = const [],
    this.ingredients = const [],
    this.products = const [],
    this.selectedTab = ProductManagementTab.products,
    this.selectedCategoryId,
    this.query = '',
    this.errorMessage,
  });

  const ProductManagementState.initial()
    : status = ProductManagementStatus.initial,
      categories = const [],
      toppings = const [],
      ingredients = const [],
      products = const [],
      selectedTab = ProductManagementTab.products,
      selectedCategoryId = null,
      query = '',
      errorMessage = null;

  bool get isLoading =>
      status == ProductManagementStatus.initial ||
      status == ProductManagementStatus.loading;

  List<Product> get visibleProducts {
    final normalizedQuery = query.toLowerCase();
    return products.where((product) {
      final matchesCategory =
          selectedCategoryId == null ||
          product.categoryId == selectedCategoryId;
      final matchesQuery =
          normalizedQuery.isEmpty ||
          product.name.toLowerCase().contains(normalizedQuery) ||
          product.description.toLowerCase().contains(normalizedQuery) ||
          product.categoryName.toLowerCase().contains(normalizedQuery);

      return matchesCategory && matchesQuery;
    }).toList();
  }

  List<ProductCategory> get visibleCategories {
    final normalizedQuery = query.toLowerCase();
    if (normalizedQuery.isEmpty) {
      return categories;
    }

    return categories
        .where(
          (category) => category.name.toLowerCase().contains(normalizedQuery),
        )
        .toList();
  }

  List<ProductIngredient> get visibleIngredients {
    final normalizedQuery = query.toLowerCase();
    if (normalizedQuery.isEmpty) {
      return ingredients;
    }

    return ingredients
        .where(
          (ingredient) =>
              ingredient.name.toLowerCase().contains(normalizedQuery) ||
              ingredient.unit.toLowerCase().contains(normalizedQuery),
        )
        .toList();
  }

  ProductManagementState copyWith({
    ProductManagementStatus? status,
    List<ProductCategory>? categories,
    List<ProductTopping>? toppings,
    List<ProductIngredient>? ingredients,
    List<Product>? products,
    ProductManagementTab? selectedTab,
    int? selectedCategoryId,
    bool clearSelectedCategory = false,
    String? query,
    String? errorMessage,
    bool clearError = false,
  }) {
    return ProductManagementState(
      status: status ?? this.status,
      categories: categories ?? this.categories,
      toppings: toppings ?? this.toppings,
      ingredients: ingredients ?? this.ingredients,
      products: products ?? this.products,
      selectedTab: selectedTab ?? this.selectedTab,
      selectedCategoryId: clearSelectedCategory
          ? null
          : (selectedCategoryId ?? this.selectedCategoryId),
      query: query ?? this.query,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }
}

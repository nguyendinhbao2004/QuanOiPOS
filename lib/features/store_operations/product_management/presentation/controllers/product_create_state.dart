import '../../domain/entities/product_category.dart';
import '../../domain/entities/product_topping.dart';
import '../../domain/entities/product_type.dart';
import '../../domain/entities/product_variant_draft.dart';

enum ProductCreateStatus {
  initial,
  loading,
  ready,
  forbidden,
  submitting,
  success,
  error,
}

class ProductCreateAccess {
  final int storeId;
  final bool canCreateProduct;

  const ProductCreateAccess({
    required this.storeId,
    required this.canCreateProduct,
  });

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is ProductCreateAccess &&
            runtimeType == other.runtimeType &&
            storeId == other.storeId &&
            canCreateProduct == other.canCreateProduct;
  }

  @override
  int get hashCode => Object.hash(storeId, canCreateProduct);
}

class ProductCreateInput {
  final String name;
  final int categoryId;
  final ProductType type;
  final String description;
  final int preparationTime;
  final int? basePrice;
  final bool hasMultipleSizes;
  final List<ProductVariantDraft> variants;
  final List<int> toppingIds;

  const ProductCreateInput({
    required this.name,
    required this.categoryId,
    required this.type,
    required this.description,
    required this.preparationTime,
    required this.basePrice,
    required this.hasMultipleSizes,
    required this.variants,
    required this.toppingIds,
  });
}

class ProductCreateState {
  final ProductCreateStatus status;
  final List<ProductCategory> categories;
  final List<ProductTopping> toppings;
  final String? errorMessage;

  const ProductCreateState({
    required this.status,
    this.categories = const [],
    this.toppings = const [],
    this.errorMessage,
  });

  const ProductCreateState.initial()
    : status = ProductCreateStatus.initial,
      categories = const [],
      toppings = const [],
      errorMessage = null;

  bool get isLoading =>
      status == ProductCreateStatus.initial ||
      status == ProductCreateStatus.loading;

  ProductCreateState copyWith({
    ProductCreateStatus? status,
    List<ProductCategory>? categories,
    List<ProductTopping>? toppings,
    String? errorMessage,
    bool clearError = false,
  }) {
    return ProductCreateState(
      status: status ?? this.status,
      categories: categories ?? this.categories,
      toppings: toppings ?? this.toppings,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }
}

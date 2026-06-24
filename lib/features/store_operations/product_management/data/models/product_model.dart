import '../../domain/entities/product.dart';
import '../../domain/entities/product_ingredient.dart';
import '../../domain/entities/product_recipe_draft.dart';
import '../../domain/entities/product_topping.dart';
import '../../domain/entities/product_type.dart';
import '../../domain/entities/product_variant_draft.dart';
import '../../domain/entities/inventory_deduction_mode.dart';

class ProductModel {
  final int id;
  final int storeId;
  final int categoryId;
  final String categoryName;
  final String name;
  final String imageUrl;
  final String description;
  final int preparationTime;
  final int price;
  final int costPrice;
  final double quantity;
  final double minimumStock;
  final double averageUnitCost;
  final double lastImportUnitCost;
  final bool isTrackInventory;
  final InventoryDeductionMode inventoryDeductionMode;
  final ProductType type;
  final List<ProductVariantDraft> variants;
  final List<ProductTopping> toppings;
  final List<ProductRecipeDraft> recipes;
  final bool isActive;
  final bool isLowStock;
  final bool isOutOfStock;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final bool isDeleted;

  const ProductModel({
    required this.id,
    required this.storeId,
    required this.categoryId,
    required this.categoryName,
    required this.name,
    required this.imageUrl,
    required this.description,
    required this.preparationTime,
    required this.price,
    required this.costPrice,
    required this.quantity,
    required this.minimumStock,
    required this.averageUnitCost,
    required this.lastImportUnitCost,
    required this.isTrackInventory,
    required this.inventoryDeductionMode,
    required this.type,
    this.variants = const [],
    this.toppings = const [],
    this.recipes = const [],
    required this.isActive,
    required this.isLowStock,
    required this.isOutOfStock,
    this.createdAt,
    this.updatedAt,
    required this.isDeleted,
  });

  factory ProductModel.fromJson(Object? json) {
    if (json is! Map<String, dynamic>) {
      throw const FormatException('Invalid product data');
    }

    final category = json['category'];

    final storeId = _intValue(json['storeId']);

    return ProductModel(
      id: _intValue(json['id'] ?? json['productId']),
      storeId: storeId,
      categoryId: _intValue(
        json['categoryId'] ??
            (category is Map<String, dynamic> ? category['id'] : null),
      ),
      categoryName: _stringValue(
        json['categoryName'] ??
            (category is Map<String, dynamic> ? category['name'] : null),
      ),
      name: _stringValue(json['name'], fallback: 'Sản phẩm'),
      imageUrl: _stringValue(json['imageUrl']),
      description: _stringValue(json['description']),
      preparationTime: _intValue(json['preparationTime']),
      price: _intValue(json['price']),
      costPrice: _intValue(json['costPrice']),
      quantity: _doubleValue(json['quantity']),
      minimumStock: _doubleValue(json['minimumStock']),
      averageUnitCost: _doubleValue(json['averageUnitCost']),
      lastImportUnitCost: _doubleValue(json['lastImportUnitCost']),
      isTrackInventory: _boolValue(json['isTrackInventory']),
      inventoryDeductionMode: InventoryDeductionMode.fromApi(
        json['inventoryDeductionMode'],
      ),
      type: ProductType.fromValue(json['type']),
      variants: _variantDrafts(json['variants']),
      toppings: _toppings(json['toppings'], storeId),
      recipes: const [],
      isActive: _boolValue(json['isActive'], fallback: true),
      isLowStock: _boolValue(json['isLowStock']),
      isOutOfStock: _boolValue(json['isOutOfStock']),
      createdAt: _dateValue(json['createdAt']),
      updatedAt: _dateValue(json['updatedAt']),
      isDeleted: _boolValue(json['isDeleted']),
    );
  }

  static List<ProductModel> listFromJson(Object? json) {
    if (json == null) {
      return const [];
    }

    if (json is List) {
      return json.map(ProductModel.fromJson).toList();
    }

    if (json is Map<String, dynamic>) {
      final items = json['items'] ?? json['products'] ?? json['data'];
      if (items is List) {
        return items.map(ProductModel.fromJson).toList();
      }
    }

    throw const FormatException('Invalid product list data');
  }

  Product toEntity() {
    return Product(
      id: id,
      storeId: storeId,
      categoryId: categoryId,
      categoryName: categoryName,
      name: name,
      imageUrl: imageUrl,
      description: description,
      preparationTime: preparationTime,
      price: price,
      costPrice: costPrice,
      quantity: quantity,
      minimumStock: minimumStock,
      averageUnitCost: averageUnitCost,
      lastImportUnitCost: lastImportUnitCost,
      isTrackInventory: isTrackInventory,
      inventoryDeductionMode: inventoryDeductionMode,
      type: type,
      variants: variants,
      toppings: toppings,
      recipes: recipes,
      isActive: isActive,
      isLowStock: isLowStock,
      isOutOfStock: isOutOfStock,
      createdAt: createdAt,
      updatedAt: updatedAt,
      isDeleted: isDeleted,
    );
  }

  static int _intValue(Object? value) {
    if (value is num) {
      return value.toInt();
    }

    if (value is String) {
      return int.tryParse(value) ?? 0;
    }

    return 0;
  }

  static double _doubleValue(Object? value) {
    if (value is num) {
      return value.toDouble();
    }

    if (value is String) {
      return double.tryParse(value) ?? 0;
    }

    return 0;
  }

  static String _stringValue(Object? value, {String fallback = ''}) {
    if (value == null) {
      return fallback;
    }

    final text = value.toString().trim();
    return text.isEmpty ? fallback : text;
  }

  static bool _boolValue(Object? value, {bool fallback = false}) {
    if (value is bool) {
      return value;
    }

    if (value is String) {
      final text = value.toLowerCase();
      if (text == 'true') {
        return true;
      }

      if (text == 'false') {
        return false;
      }
    }

    if (value is num) {
      return value != 0;
    }

    return fallback;
  }

  static List<ProductVariantDraft> _variantDrafts(Object? value) {
    if (value is! List) {
      return const [];
    }

    return value
        .whereType<Map<String, dynamic>>()
        .map(
          (variant) => ProductVariantDraft(
            id: _optionalIntValue(variant['id'] ?? variant['variantId']),
            name: _stringValue(variant['name'], fallback: 'Mặc định'),
            price: _intValue(variant['price']),
            costPrice: _intValue(variant['costPrice']),
            isDefault: _boolValue(variant['isDefault']),
            isActive: _boolValue(variant['isActive'], fallback: true),
            quantity: _doubleValue(variant['quantity']),
            minimumStock: _doubleValue(variant['minimumStock']),
            averageUnitCost: _doubleValue(variant['averageUnitCost']),
            lastImportUnitCost: _doubleValue(variant['lastImportUnitCost']),
            isTrackInventory: _boolValue(variant['isTrackInventory']),
            isLowStock: _boolValue(variant['isLowStock']),
            isOutOfStock: _boolValue(variant['isOutOfStock']),
          ),
        )
        .toList();
  }

  static List<ProductTopping> _toppings(Object? value, int storeId) {
    if (value is! List) {
      return const [];
    }

    return value
        .whereType<Map<String, dynamic>>()
        .map(
          (topping) => ProductTopping(
            id: _intValue(topping['id'] ?? topping['toppingId']),
            storeId: _intValue(topping['storeId']) == 0
                ? storeId
                : _intValue(topping['storeId']),
            name: _stringValue(topping['name'], fallback: 'Topping'),
            price: _intValue(topping['price']),
            isDeleted: _boolValue(topping['isDeleted']),
          ),
        )
        .toList();
  }

  static List<ProductRecipeDraft> recipeListFromJson(Object? value) {
    if (value is! List) {
      return const [];
    }

    return value.whereType<Map<String, dynamic>>().map((recipe) {
      final ingredientJson = recipe['ingredient'];
      final ingredient = ingredientJson is Map<String, dynamic>
          ? ProductIngredient(
              id: _intValue(
                ingredientJson['id'] ?? ingredientJson['ingredientId'],
              ),
              storeId: _intValue(ingredientJson['storeId']),
              name: _stringValue(
                ingredientJson['name'],
                fallback: 'Nguyên liệu',
              ),
              itemType: _intValue(ingredientJson['itemType']),
              unit: _stringValue(ingredientJson['unit']),
              quantity: _doubleValue(ingredientJson['quantity']),
              minimumStock: _doubleValue(ingredientJson['minimumStock']),
              averageUnitCost: _doubleValue(ingredientJson['averageUnitCost']),
              lastImportUnitCost: _doubleValue(
                ingredientJson['lastImportUnitCost'],
              ),
              isTrackInventory: _boolValue(ingredientJson['isTrackInventory']),
              isLowStock: _boolValue(ingredientJson['isLowStock']),
              isOutOfStock: _boolValue(ingredientJson['isOutOfStock']),
              capacity: _intValue(ingredientJson['capacity']),
              currentCapacity: _intValue(ingredientJson['currentCapacity']),
              isActive: _boolValue(ingredientJson['isActive'], fallback: true),
              isDeleted: _boolValue(ingredientJson['isDeleted']),
            )
          : null;

      final recipeId = _intValue(recipe['id']);
      return ProductRecipeDraft(
        id: recipeId == 0 ? null : recipeId,
        ingredientId: _intValue(recipe['ingredientId'] ?? ingredient?.id),
        ingredient: ingredient,
        quantity: _doubleValue(recipe['quantity']),
        capacity: _doubleValue(recipe['capacity']),
      );
    }).toList();
  }

  static int? _optionalIntValue(Object? value) {
    final parsed = _intValue(value);
    return parsed == 0 ? null : parsed;
  }

  static DateTime? _dateValue(Object? value) {
    if (value is DateTime) {
      return value;
    }

    if (value is String && value.trim().isNotEmpty) {
      return DateTime.tryParse(value);
    }

    return null;
  }
}

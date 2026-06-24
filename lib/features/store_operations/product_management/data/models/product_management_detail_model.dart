import '../../domain/entities/product_ingredient.dart';
import '../../domain/entities/product_management_detail.dart';
import '../../domain/entities/product_recipe_draft.dart';
import '../../domain/entities/product_topping.dart';
import '../../domain/entities/product_variant_draft.dart';
import '../../domain/entities/product_variant_recipe_adjustment.dart';
import 'product_model.dart';

class ProductManagementDetailModel {
  final ProductModel product;
  final List<ProductVariantDraft> variants;
  final List<ProductRecipeDraft> recipes;
  final List<ProductVariantRecipeAdjustment> variantRecipeAdjustments;
  final List<ProductTopping> toppings;

  const ProductManagementDetailModel({
    required this.product,
    required this.variants,
    required this.recipes,
    required this.variantRecipeAdjustments,
    required this.toppings,
  });

  factory ProductManagementDetailModel.fromJson(Object? json) {
    final map = _asMap(json);
    final productModel = ProductModel.fromJson(
      map['product'] ?? map['Product'],
    );
    final adjustments = _listFromJson(
      map['variantRecipeAdjustments'] ?? map['VariantRecipeAdjustments'],
      _adjustmentFromJson,
    );

    return ProductManagementDetailModel(
      product: productModel,
      variants: _listFromJson(
        map['variants'] ?? map['Variants'],
        (item) => _variantFromJson(item, adjustments),
      ),
      recipes: _listFromJson(map['recipes'] ?? map['Recipes'], _recipeFromJson),
      variantRecipeAdjustments: adjustments,
      toppings: _listFromJson(
        map['toppings'] ?? map['Toppings'],
        (item) => _toppingFromJson(item, productModel.storeId),
      ),
    );
  }

  ProductManagementDetail toEntity() {
    final productEntity = product.toEntity();
    return ProductManagementDetail(
      product: productEntity,
      variants: variants,
      recipes: recipes,
      variantRecipeAdjustments: variantRecipeAdjustments,
      toppings: toppings,
    );
  }

  static ProductVariantDraft _variantFromJson(
    Object? json,
    List<ProductVariantRecipeAdjustment> adjustments,
  ) {
    final map = _asMap(json);
    final id = _optionalIntValue(map['id'] ?? map['variantId']);
    return ProductVariantDraft(
      id: id,
      name: _stringValue(map['name'], fallback: 'Mặc định'),
      price: _intValue(map['price']),
      costPrice: _intValue(map['costPrice']),
      isDefault: _boolValue(map['isDefault']),
      isActive: _boolValue(map['isActive'], fallback: true),
      quantity: _doubleValue(map['quantity']),
      minimumStock: _doubleValue(map['minimumStock']),
      averageUnitCost: _doubleValue(map['averageUnitCost']),
      lastImportUnitCost: _doubleValue(map['lastImportUnitCost']),
      isTrackInventory: _boolValue(map['isTrackInventory']),
      isLowStock: _boolValue(map['isLowStock']),
      isOutOfStock: _boolValue(map['isOutOfStock']),
      recipeAdjustments: id == null
          ? const []
          : adjustments
                .where((adjustment) => adjustment.variantId == id)
                .toList(),
    );
  }

  static ProductRecipeDraft _recipeFromJson(Object? json) {
    final map = _asMap(json);
    final ingredientId = _intValue(map['ingredientId']);
    return ProductRecipeDraft(
      id: _optionalIntValue(map['id']),
      ingredientId: ingredientId,
      ingredient: _ingredientFromRecipeJson(map),
      quantity: _doubleValue(map['quantity']),
      capacity: _doubleValue(map['capacity']),
    );
  }

  static ProductVariantRecipeAdjustment _adjustmentFromJson(Object? json) {
    final map = _asMap(json);
    final ingredientId = _intValue(map['ingredientId']);
    return ProductVariantRecipeAdjustment(
      id: _optionalIntValue(map['id']),
      variantId: _intValue(map['variantId']),
      ingredientId: ingredientId,
      ingredient: _ingredientFromAdjustmentJson(map),
      ingredientName: _stringValue(map['ingredientName']),
      ingredientUnit: _stringValue(map['ingredientUnit']),
      quantityDelta: _doubleValue(map['quantityDelta']),
      isActive: _boolValue(map['isActive'], fallback: true),
    );
  }

  static ProductTopping _toppingFromJson(Object? json, int storeId) {
    final map = _asMap(json);
    return ProductTopping(
      id: _intValue(map['toppingId'] ?? map['id']),
      storeId: _intValue(map['storeId']) == 0
          ? storeId
          : _intValue(map['storeId']),
      name: _stringValue(map['name'], fallback: 'Topping'),
      price: _intValue(map['price']),
      isDeleted: !_boolValue(map['isActive'], fallback: true),
    );
  }

  static ProductIngredient? _ingredientFromRecipeJson(
    Map<String, dynamic> map,
  ) {
    final ingredientJson = map['ingredient'];
    if (ingredientJson is Map<String, dynamic>) {
      return _ingredientFromMap(ingredientJson);
    }

    final ingredientId = _intValue(map['ingredientId']);
    final ingredientName = _stringValue(map['ingredientName']);
    if (ingredientId <= 0 && ingredientName.isEmpty) {
      return null;
    }

    return _minimalIngredient(
      id: ingredientId,
      name: ingredientName.isEmpty
          ? 'Nguyên liệu #$ingredientId'
          : ingredientName,
      unit: _stringValue(map['ingredientUnit']),
    );
  }

  static ProductIngredient? _ingredientFromAdjustmentJson(
    Map<String, dynamic> map,
  ) {
    final ingredientJson = map['ingredient'];
    if (ingredientJson is Map<String, dynamic>) {
      return _ingredientFromMap(ingredientJson);
    }

    final ingredientId = _intValue(map['ingredientId']);
    final ingredientName = _stringValue(map['ingredientName']);
    if (ingredientId <= 0 && ingredientName.isEmpty) {
      return null;
    }

    return _minimalIngredient(
      id: ingredientId,
      name: ingredientName.isEmpty
          ? 'Nguyên liệu #$ingredientId'
          : ingredientName,
      unit: _stringValue(map['ingredientUnit']),
    );
  }

  static ProductIngredient _ingredientFromMap(Map<String, dynamic> map) {
    return ProductIngredient(
      id: _intValue(map['id'] ?? map['ingredientId']),
      storeId: _intValue(map['storeId']),
      name: _stringValue(map['name'], fallback: 'Nguyên liệu'),
      itemType: _intValue(map['itemType']),
      unit: _stringValue(map['unit']),
      quantity: _doubleValue(map['quantity']),
      minimumStock: _doubleValue(map['minimumStock']),
      averageUnitCost: _doubleValue(map['averageUnitCost']),
      lastImportUnitCost: _doubleValue(map['lastImportUnitCost']),
      isTrackInventory: _boolValue(map['isTrackInventory']),
      isLowStock: _boolValue(map['isLowStock']),
      isOutOfStock: _boolValue(map['isOutOfStock']),
      capacity: _intValue(map['capacity']),
      currentCapacity: _intValue(map['currentCapacity']),
      isActive: _boolValue(map['isActive'], fallback: true),
      isDeleted: _boolValue(map['isDeleted']),
    );
  }

  static ProductIngredient _minimalIngredient({
    required int id,
    required String name,
    required String unit,
  }) {
    return ProductIngredient(
      id: id,
      storeId: 0,
      name: name,
      itemType: 1,
      unit: unit,
      quantity: 0,
      capacity: 0,
      currentCapacity: 0,
      isActive: true,
      isDeleted: false,
    );
  }

  static Map<String, dynamic> _asMap(Object? json) {
    if (json is Map<String, dynamic>) {
      return json;
    }

    throw const FormatException('Invalid product management detail data');
  }

  static List<T> _listFromJson<T>(
    Object? json,
    T Function(Object? item) mapper,
  ) {
    if (json is! List) {
      return const [];
    }

    return json.map(mapper).toList();
  }

  static int _intValue(Object? value, {int fallback = 0}) {
    if (value is num) {
      return value.toInt();
    }

    if (value is String) {
      return int.tryParse(value) ?? fallback;
    }

    return fallback;
  }

  static int? _optionalIntValue(Object? value) {
    final parsed = _intValue(value);
    return parsed == 0 ? null : parsed;
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
}

import 'package:dio/dio.dart';

import '../../../../../core/network/dio/dio_client.dart';
import '../../domain/entities/product_image_upload.dart';
import '../models/product_category_model.dart';
import '../models/product_ingredient_model.dart';
import '../models/product_image_upload_url_model.dart';
import '../models/inventory_item_settings_models.dart';
import '../models/product_management_request_models.dart';
import '../models/product_model.dart';
import '../models/product_topping_model.dart';

class ProductManagementRemoteDataSource {
  final DioClient _dioClient;
  final Dio _imageUploadDio;

  ProductManagementRemoteDataSource(this._dioClient, this._imageUploadDio);

  Future<String> uploadProductImage({
    required int storeId,
    required ProductImageUpload image,
  }) async {
    if (!image.isSupported) {
      throw Exception('Định dạng ảnh không được hỗ trợ');
    }

    for (var attempt = 0; attempt < 2; attempt++) {
      try {
        final uploadTarget = await _requestProductImageUploadUrl(
          storeId: storeId,
          contentType: image.contentType,
        );
        await _imageUploadDio.put<void>(
          uploadTarget.uploadUrl,
          data: image.bytes,
          options: Options(
            contentType: image.contentType,
            responseType: ResponseType.plain,
          ),
        );
        return uploadTarget.imageUrl;
      } catch (_) {
        if (attempt == 1) {
          throw Exception('Không thể tải ảnh lên. Vui lòng thử lại.');
        }
      }
    }

    throw Exception('Không thể tải ảnh lên. Vui lòng thử lại.');
  }

  Future<ProductImageUploadUrlModel> _requestProductImageUploadUrl({
    required int storeId,
    required String contentType,
  }) async {
    final response = await _dioClient.postResponse<ProductImageUploadUrlModel>(
      '/products/image-upload-url',
      data: {'storeId': storeId, 'contentType': contentType},
      dataFromJson: ProductImageUploadUrlModel.fromJson,
    );

    if (!response.succeeded || response.data == null) {
      _throwRequestFailure(
        response.message,
        response.errors,
        'Không thể chuẩn bị tải ảnh sản phẩm',
      );
    }

    return response.data!;
  }

  Future<List<ProductCategoryModel>> getCategoriesByStore(int storeId) async {
    final response = await _dioClient.getResponse<List<ProductCategoryModel>>(
      '/categories/store/$storeId',
      dataFromJson: ProductCategoryModel.listFromJson,
    );

    if (!response.succeeded || response.data == null) {
      _throwRequestFailure(
        response.message,
        response.errors,
        'Không thể tải danh mục sản phẩm',
      );
    }

    return response.data!;
  }

  Future<List<ProductToppingModel>> getToppingsByStore(int storeId) async {
    final response = await _dioClient.getResponse<List<ProductToppingModel>>(
      '/toppings/store/$storeId',
      dataFromJson: ProductToppingModel.listFromJson,
    );

    if (!response.succeeded || response.data == null) {
      _throwRequestFailure(
        response.message,
        response.errors,
        'Không thể tải topping',
      );
    }

    return response.data!;
  }

  Future<List<ProductIngredientModel>> getIngredientsByStore(
    int storeId,
  ) async {
    final response = await _dioClient.getResponse<List<ProductIngredientModel>>(
      '/ingredients/store/$storeId',
      dataFromJson: ProductIngredientModel.listFromJson,
    );

    if (!response.succeeded || response.data == null) {
      _throwRequestFailure(
        response.message,
        response.errors,
        'Không thể tải nguyên liệu',
      );
    }

    return response.data!;
  }

  Future<List<IngredientInventorySettingsModel>> getIngredientInventorySettings(
    int storeId,
  ) async {
    final response = await _dioClient
        .getResponse<List<IngredientInventorySettingsModel>>(
          '/inventory/ingredients',
          queryParameters: {'storeId': storeId, 'status': 'all'},
          dataFromJson: IngredientInventorySettingsModel.listFromJson,
        );

    if (!response.succeeded || response.data == null) {
      _throwRequestFailure(
        response.message,
        response.errors,
        'Không thể tải cấu hình tồn nguyên liệu',
      );
    }

    return response.data!;
  }

  Future<ProductIngredientModel> createIngredient(
    CreateProductIngredientRequestModel request,
  ) async {
    final response = await _dioClient.postResponse<ProductIngredientModel>(
      '/ingredients',
      data: request.toJson(),
      dataFromJson: ProductIngredientModel.fromJson,
    );

    if (!response.succeeded || response.data == null) {
      _throwRequestFailure(
        response.message,
        response.errors,
        'Không thể thêm nguyên liệu',
      );
    }

    return response.data!;
  }

  Future<ProductIngredientModel> updateIngredient({
    required int ingredientId,
    required UpdateProductIngredientRequestModel request,
  }) async {
    final response = await _dioClient.putResponse<ProductIngredientModel>(
      '/ingredients/$ingredientId',
      data: request.toJson(),
      dataFromJson: ProductIngredientModel.fromJson,
    );

    if (!response.succeeded || response.data == null) {
      _throwRequestFailure(
        response.message,
        response.errors,
        'Không thể cập nhật nguyên liệu',
      );
    }

    return response.data!;
  }

  Future<void> deleteIngredient(int ingredientId) async {
    final response = await _dioClient.deleteResponse<Object?>(
      '/ingredients/$ingredientId',
    );

    if (!response.succeeded) {
      _throwRequestFailure(
        response.message,
        response.errors,
        'Không thể xóa nguyên liệu',
      );
    }
  }

  Future<ProductToppingModel> createTopping(
    CreateProductToppingRequestModel request,
  ) async {
    final response = await _dioClient.postResponse<ProductToppingModel>(
      '/toppings',
      data: request.toJson(),
      dataFromJson: ProductToppingModel.fromJson,
    );

    if (!response.succeeded || response.data == null) {
      _throwRequestFailure(
        response.message,
        response.errors,
        'Không thể thêm topping',
      );
    }

    return response.data!;
  }

  Future<ProductToppingModel> updateTopping({
    required int toppingId,
    required UpdateProductToppingRequestModel request,
  }) async {
    final response = await _dioClient.putResponse<ProductToppingModel>(
      '/toppings/$toppingId',
      data: request.toJson(),
      dataFromJson: ProductToppingModel.fromJson,
    );

    if (!response.succeeded || response.data == null) {
      _throwRequestFailure(
        response.message,
        response.errors,
        'Không thể cập nhật topping',
      );
    }

    return response.data!;
  }

  Future<void> deleteTopping(int toppingId) async {
    final response = await _dioClient.deleteResponse<Object?>(
      '/toppings/$toppingId',
    );

    if (!response.succeeded) {
      _throwRequestFailure(
        response.message,
        response.errors,
        'Không thể xóa topping',
      );
    }
  }

  Future<ProductCategoryModel> createCategory(
    CreateProductCategoryRequestModel request,
  ) async {
    final response = await _dioClient.postResponse<ProductCategoryModel>(
      '/categories',
      data: request.toJson(),
      dataFromJson: ProductCategoryModel.fromJson,
    );

    if (!response.succeeded || response.data == null) {
      _throwRequestFailure(
        response.message,
        response.errors,
        'Không thể thêm danh mục',
      );
    }

    return response.data!;
  }

  Future<ProductCategoryModel> updateCategory({
    required int categoryId,
    required UpdateProductCategoryRequestModel request,
  }) async {
    final response = await _dioClient.putResponse<ProductCategoryModel>(
      '/categories/$categoryId',
      data: request.toJson(),
      dataFromJson: ProductCategoryModel.fromJson,
    );

    if (!response.succeeded || response.data == null) {
      _throwRequestFailure(
        response.message,
        response.errors,
        'Không thể cập nhật danh mục',
      );
    }

    return response.data!;
  }

  Future<void> deleteCategory(int categoryId) async {
    final response = await _dioClient.deleteResponse<Object?>(
      '/categories/$categoryId',
    );

    if (!response.succeeded) {
      _throwRequestFailure(
        response.message,
        response.errors,
        'Không thể xóa danh mục',
      );
    }
  }

  Future<List<ProductModel>> getProductsByStore(int storeId) async {
    final response = await _dioClient.getResponse<List<ProductModel>>(
      '/products/store/$storeId',
      dataFromJson: ProductModel.listFromJson,
    );

    if (!response.succeeded || response.data == null) {
      _throwRequestFailure(
        response.message,
        response.errors,
        'Không thể tải danh sách sản phẩm',
      );
    }

    return response.data!;
  }

  Future<List<ProductInventorySettingsModel>> getProductInventorySettings(
    int storeId,
  ) async {
    final response = await _dioClient
        .getResponse<List<ProductInventorySettingsModel>>(
          '/inventory/products',
          queryParameters: {'storeId': storeId, 'status': 'all'},
          dataFromJson: ProductInventorySettingsModel.listFromJson,
        );

    if (!response.succeeded || response.data == null) {
      _throwRequestFailure(
        response.message,
        response.errors,
        'Không thể tải cấu hình tồn sản phẩm',
      );
    }

    return response.data!;
  }

  Future<ProductModel> getProductById(int productId) async {
    final response = await _dioClient.getResponse<ProductModel>(
      '/products/$productId',
      dataFromJson: ProductModel.fromJson,
    );

    if (!response.succeeded || response.data == null) {
      _throwRequestFailure(
        response.message,
        response.errors,
        'Không thể tải chi tiết sản phẩm',
      );
    }

    return response.data!;
  }

  Future<ProductModel> createProduct(CreateProductRequestModel request) async {
    final response = await _dioClient.postResponse<ProductModel>(
      '/products',
      data: request.toJson(),
      dataFromJson: ProductModel.fromJson,
    );

    if (!response.succeeded || response.data == null) {
      _throwRequestFailure(
        response.message,
        response.errors,
        'Không thể thêm sản phẩm',
      );
    }

    return response.data!;
  }

  Future<ProductModel> updateProduct({
    required int productId,
    required UpdateProductRequestModel request,
  }) async {
    final response = await _dioClient.putResponse<ProductModel>(
      '/products/$productId',
      data: request.toJson(),
      dataFromJson: ProductModel.fromJson,
    );

    if (!response.succeeded || response.data == null) {
      _throwRequestFailure(
        response.message,
        response.errors,
        'Không thể cập nhật sản phẩm',
      );
    }

    return response.data!;
  }

  Future<void> updateIngredientInventorySettings({
    required int ingredientId,
    required UpdateIngredientInventorySettingsRequestModel request,
  }) async {
    final response = await _dioClient.putResponse<Object?>(
      '/inventory/ingredients/$ingredientId/settings',
      data: request.toJson(),
    );

    if (!response.succeeded) {
      _throwRequestFailure(
        response.message,
        response.errors,
        'Không thể cập nhật cấu hình tồn nguyên liệu',
      );
    }
  }

  Future<void> updateProductInventorySettings({
    required int productId,
    required UpdateProductInventorySettingsRequestModel request,
  }) async {
    final response = await _dioClient.putResponse<Object?>(
      '/inventory/products/$productId/inventory-settings',
      data: request.toJson(),
    );

    if (!response.succeeded) {
      _throwRequestFailure(
        response.message,
        response.errors,
        'Không thể cập nhật cấu hình tồn sản phẩm',
      );
    }
  }

  Future<void> replaceProductRecipe({
    required int productId,
    required ReplaceProductRecipeRequestModel request,
  }) async {
    final response = await _dioClient.putResponse<Object?>(
      '/inventory/products/$productId/recipe',
      data: request.toJson(),
    );

    if (!response.succeeded) {
      _throwRequestFailure(
        response.message,
        response.errors,
        'Không thể cập nhật công thức sản phẩm',
      );
    }
  }

  Future<void> updateProductSellStatus({
    required int productId,
    required UpdateProductSellStatusRequestModel request,
  }) async {
    final response = await _dioClient.patchResponse<Object?>(
      '/products/$productId/is-sell',
      data: request.toJson(),
    );

    if (!response.succeeded) {
      _throwRequestFailure(
        response.message,
        response.errors,
        'Không thể cập nhật trạng thái bán',
      );
    }
  }

  Future<void> deleteProduct(int productId) async {
    final response = await _dioClient.deleteResponse<Object?>(
      '/products/$productId',
    );

    if (!response.succeeded) {
      _throwRequestFailure(
        response.message,
        response.errors,
        'Không thể xóa sản phẩm',
      );
    }
  }

  Never _throwRequestFailure(
    String? message,
    List<String> errors,
    String fallbackMessage,
  ) {
    throw Exception(_failureMessage(message, errors, fallbackMessage));
  }

  String _failureMessage(
    String? message,
    List<String> errors,
    String fallbackMessage,
  ) {
    final cleanMessage = message?.trim();
    if (cleanMessage != null && cleanMessage.isNotEmpty) {
      return cleanMessage;
    }

    if (errors.isNotEmpty) {
      return errors.first;
    }

    return fallbackMessage;
  }
}

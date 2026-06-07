import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../core/di/injection.dart';
import '../../data/datasources/product_management_remote_data_source.dart';
import '../../domain/repositories/product_management_repository.dart';
import '../../domain/usecases/create_product_category_use_case.dart';
import '../../domain/usecases/create_product_topping_use_case.dart';
import '../../domain/usecases/create_product_use_case.dart';
import '../../domain/usecases/delete_product_category_use_case.dart';
import '../../domain/usecases/delete_product_topping_use_case.dart';
import '../../domain/usecases/delete_product_use_case.dart';
import '../../domain/usecases/load_product_categories_use_case.dart';
import '../../domain/usecases/load_product_detail_use_case.dart';
import '../../domain/usecases/load_product_toppings_use_case.dart';
import '../../domain/usecases/load_products_use_case.dart';
import '../../domain/usecases/update_product_category_use_case.dart';
import '../../domain/usecases/update_product_sell_status_use_case.dart';
import '../../domain/usecases/update_product_topping_use_case.dart';
import '../../domain/usecases/update_product_use_case.dart';
import '../controllers/product_create_notifier.dart';
import '../controllers/product_create_state.dart';
import '../controllers/product_management_notifier.dart';
import '../controllers/product_management_state.dart';

final productManagementRemoteDataSourceProvider =
    Provider<ProductManagementRemoteDataSource>((ref) {
      return locator<ProductManagementRemoteDataSource>();
    });

final productManagementRepositoryProvider =
    Provider<ProductManagementRepository>((ref) {
      return locator<ProductManagementRepository>();
    });

final loadProductCategoriesUseCaseProvider =
    Provider<LoadProductCategoriesUseCase>((ref) {
      return locator<LoadProductCategoriesUseCase>();
    });

final loadProductToppingsUseCaseProvider = Provider<LoadProductToppingsUseCase>(
  (ref) {
    return locator<LoadProductToppingsUseCase>();
  },
);

final createProductToppingUseCaseProvider =
    Provider<CreateProductToppingUseCase>((ref) {
      return locator<CreateProductToppingUseCase>();
    });

final updateProductToppingUseCaseProvider =
    Provider<UpdateProductToppingUseCase>((ref) {
      return locator<UpdateProductToppingUseCase>();
    });

final deleteProductToppingUseCaseProvider =
    Provider<DeleteProductToppingUseCase>((ref) {
      return locator<DeleteProductToppingUseCase>();
    });

final createProductCategoryUseCaseProvider =
    Provider<CreateProductCategoryUseCase>((ref) {
      return locator<CreateProductCategoryUseCase>();
    });

final updateProductCategoryUseCaseProvider =
    Provider<UpdateProductCategoryUseCase>((ref) {
      return locator<UpdateProductCategoryUseCase>();
    });

final deleteProductCategoryUseCaseProvider =
    Provider<DeleteProductCategoryUseCase>((ref) {
      return locator<DeleteProductCategoryUseCase>();
    });

final loadProductsUseCaseProvider = Provider<LoadProductsUseCase>((ref) {
  return locator<LoadProductsUseCase>();
});

final createProductUseCaseProvider = Provider<CreateProductUseCase>((ref) {
  return locator<CreateProductUseCase>();
});

final loadProductDetailUseCaseProvider = Provider<LoadProductDetailUseCase>((
  ref,
) {
  return locator<LoadProductDetailUseCase>();
});

final updateProductUseCaseProvider = Provider<UpdateProductUseCase>((ref) {
  return locator<UpdateProductUseCase>();
});

final updateProductSellStatusUseCaseProvider =
    Provider<UpdateProductSellStatusUseCase>((ref) {
      return locator<UpdateProductSellStatusUseCase>();
    });

final deleteProductUseCaseProvider = Provider<DeleteProductUseCase>((ref) {
  return locator<DeleteProductUseCase>();
});

final productManagementNotifierProvider = NotifierProvider.autoDispose
    .family<
      ProductManagementNotifier,
      ProductManagementState,
      ProductManagementAccess
    >(ProductManagementNotifier.new);

final productCreateNotifierProvider = NotifierProvider.autoDispose
    .family<ProductCreateNotifier, ProductCreateState, ProductCreateAccess>(
      ProductCreateNotifier.new,
    );

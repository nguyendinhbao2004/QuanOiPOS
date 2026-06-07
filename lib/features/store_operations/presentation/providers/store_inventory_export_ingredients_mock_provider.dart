import 'package:flutter_riverpod/flutter_riverpod.dart';

final storeInventoryExportIngredientsMockProvider =
    Provider<List<StoreInventoryExportIngredientMockItem>>((ref) {
      // TODO: Replace mock data when inventory export ingredients API is available.
      return const [
        StoreInventoryExportIngredientMockItem(
          name: 'Đường',
          code: 'NL0001',
          stockQuantity: 12,
          unit: 'kg',
        ),
        StoreInventoryExportIngredientMockItem(
          name: 'Sữa tươi',
          code: 'NL0002',
          stockQuantity: 8,
          unit: 'lít',
        ),
        StoreInventoryExportIngredientMockItem(
          name: 'Trà ô long',
          code: 'NL0003',
          stockQuantity: 6,
          unit: 'kg',
        ),
        StoreInventoryExportIngredientMockItem(
          name: 'Bột cacao',
          code: 'NL0004',
          stockQuantity: 4,
          unit: 'kg',
        ),
        StoreInventoryExportIngredientMockItem(
          name: 'Chanh',
          code: 'NL0005',
          stockQuantity: 30,
          unit: 'quả',
        ),
        StoreInventoryExportIngredientMockItem(
          name: 'Mật ong',
          code: 'NL0006',
          stockQuantity: 5,
          unit: 'lít',
        ),
      ];
    });

class StoreInventoryExportIngredientMockItem {
  final String name;
  final String code;
  final int stockQuantity;
  final String unit;

  const StoreInventoryExportIngredientMockItem({
    required this.name,
    required this.code,
    required this.stockQuantity,
    required this.unit,
  });
}

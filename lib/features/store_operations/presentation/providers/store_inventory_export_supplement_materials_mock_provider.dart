import 'package:flutter_riverpod/flutter_riverpod.dart';

final storeInventoryExportSupplementMaterialsMockProvider =
    Provider<List<StoreInventoryExportSupplementMaterialMockItem>>((ref) {
      // TODO: Replace mock data when supplement materials API is available.
      return const [
        StoreInventoryExportSupplementMaterialMockItem(
          name: 'Đường',
          code: 'NVL0001',
          stockQuantity: 12,
          unit: 'kg',
        ),
        StoreInventoryExportSupplementMaterialMockItem(
          name: 'Sữa tươi',
          code: 'NVL0002',
          stockQuantity: 8,
          unit: 'lít',
        ),
        StoreInventoryExportSupplementMaterialMockItem(
          name: 'Trà ô long',
          code: 'NVL0003',
          stockQuantity: 6,
          unit: 'kg',
        ),
        StoreInventoryExportSupplementMaterialMockItem(
          name: 'Bột cacao',
          code: 'NVL0004',
          stockQuantity: 4,
          unit: 'kg',
        ),
        StoreInventoryExportSupplementMaterialMockItem(
          name: 'Chanh',
          code: 'NVL0005',
          stockQuantity: 30,
          unit: 'quả',
        ),
        StoreInventoryExportSupplementMaterialMockItem(
          name: 'Mật ong',
          code: 'NVL0006',
          stockQuantity: 5,
          unit: 'lít',
        ),
      ];
    });

class StoreInventoryExportSupplementMaterialMockItem {
  final String name;
  final String code;
  final int stockQuantity;
  final String unit;

  const StoreInventoryExportSupplementMaterialMockItem({
    required this.name,
    required this.code,
    required this.stockQuantity,
    required this.unit,
  });
}

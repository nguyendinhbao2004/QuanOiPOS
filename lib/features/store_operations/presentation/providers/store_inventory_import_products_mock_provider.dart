import 'package:flutter_riverpod/flutter_riverpod.dart';

final storeInventoryImportProductsMockProvider =
    Provider<List<StoreInventoryImportProductMockItem>>((ref) {
      // TODO: Replace mock data when inventory import products API is available.
      return const [
        StoreInventoryImportProductMockItem(
          name: 'Revive',
          sku: 'SP0098',
          stockQuantity: 4,
        ),
        StoreInventoryImportProductMockItem(
          name: 'Ô long tea',
          sku: 'SP0082',
          stockQuantity: 7,
        ),
        StoreInventoryImportProductMockItem(
          name: 'Bí đao',
          sku: 'SP0075',
          stockQuantity: 4,
        ),
        StoreInventoryImportProductMockItem(
          name: 'Coca',
          sku: 'SP0050',
          stockQuantity: 7,
        ),
        StoreInventoryImportProductMockItem(
          name: 'Bò cụng redbull',
          sku: 'SP0039',
          stockQuantity: 8,
        ),
        StoreInventoryImportProductMockItem(
          name: 'Mèo mi',
          sku: 'SP0044',
          stockQuantity: 3,
        ),
        StoreInventoryImportProductMockItem(
          name: 'Revive chanh muối',
          sku: 'SP0068',
          stockQuantity: 5,
        ),
        StoreInventoryImportProductMockItem(
          name: 'Number 1 chanh',
          sku: 'SP0088',
          stockQuantity: 0,
        ),
        StoreInventoryImportProductMockItem(
          name: 'Lipovitan tăng lực mật ong',
          sku: 'SP0080',
          stockQuantity: 0,
        ),
      ];
    });

class StoreInventoryImportProductMockItem {
  final String name;
  final String sku;
  final int stockQuantity;

  const StoreInventoryImportProductMockItem({
    required this.name,
    required this.sku,
    required this.stockQuantity,
  });
}

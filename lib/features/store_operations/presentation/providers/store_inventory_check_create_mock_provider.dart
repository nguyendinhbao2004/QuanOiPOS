import 'package:flutter_riverpod/flutter_riverpod.dart';

final storeInventoryCheckCreateMockProvider =
    Provider<StoreInventoryCheckCreateMockData>((ref) {
      // TODO: Replace mock data when inventory check create API is available.
      return const StoreInventoryCheckCreateMockData(
        products: [
          StoreInventoryCheckCreateItem(
            name: 'Thăng Long',
            code: 'SP0048',
            stockText: '9',
          ),
          StoreInventoryCheckCreateItem(
            name: 'Sài gòn bạc',
            code: 'SP0038',
            stockText: '1',
          ),
          StoreInventoryCheckCreateItem(
            name: 'Number 1',
            code: 'SP0072',
            stockText: '3',
          ),
          StoreInventoryCheckCreateItem(
            name: 'Sữa đậu nành',
            code: 'SP0135',
            stockText: '0',
          ),
          StoreInventoryCheckCreateItem(
            name: 'Mèo mi',
            code: 'SP0044',
            stockText: '2',
          ),
          StoreInventoryCheckCreateItem(
            name: 'Bí đao',
            code: 'SP0075',
            stockText: '3',
          ),
          StoreInventoryCheckCreateItem(
            name: 'C2 đào',
            code: 'SP0070',
            stockText: '3',
          ),
          StoreInventoryCheckCreateItem(
            name: 'Coca',
            code: 'SP0050',
            stockText: '7',
          ),
          StoreInventoryCheckCreateItem(
            name: 'Bò cụng redbull',
            code: 'SP0039',
            stockText: '8',
          ),
        ],
        ingredients: [
          StoreInventoryCheckCreateItem(
            name: 'Đường',
            code: 'NL0001',
            stockText: '12 kg',
          ),
          StoreInventoryCheckCreateItem(
            name: 'Sữa tươi',
            code: 'NL0002',
            stockText: '8 lít',
          ),
          StoreInventoryCheckCreateItem(
            name: 'Trà ô long',
            code: 'NL0003',
            stockText: '6 kg',
          ),
          StoreInventoryCheckCreateItem(
            name: 'Bột cacao',
            code: 'NL0004',
            stockText: '4 kg',
          ),
          StoreInventoryCheckCreateItem(
            name: 'Chanh',
            code: 'NL0005',
            stockText: '30 quả',
          ),
          StoreInventoryCheckCreateItem(
            name: 'Mật ong',
            code: 'NL0006',
            stockText: '5 lít',
          ),
        ],
      );
    });

class StoreInventoryCheckCreateMockData {
  final List<StoreInventoryCheckCreateItem> products;
  final List<StoreInventoryCheckCreateItem> ingredients;

  const StoreInventoryCheckCreateMockData({
    required this.products,
    required this.ingredients,
  });
}

class StoreInventoryCheckCreateItem {
  final String name;
  final String code;
  final String stockText;

  const StoreInventoryCheckCreateItem({
    required this.name,
    required this.code,
    required this.stockText,
  });
}

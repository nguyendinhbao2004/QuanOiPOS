import 'package:flutter_riverpod/flutter_riverpod.dart';

final storeInventoryExportMockProvider =
    Provider<List<StoreInventoryExportMockItem>>((ref) {
      // TODO: Replace mock data when inventory export API contract is available.
      return const [
        StoreInventoryExportMockItem(
          code: '#XH1948',
          createdAtText: '09:05 22/05/26',
          status: 'Hoàn thành',
          creatorName: 'Lê Minh An',
          totalText: '0',
        ),
      ];
    });

class StoreInventoryExportMockItem {
  final String code;
  final String createdAtText;
  final String status;
  final String creatorName;
  final String totalText;

  const StoreInventoryExportMockItem({
    required this.code,
    required this.createdAtText,
    required this.status,
    required this.creatorName,
    required this.totalText,
  });
}

import 'owner_dashboard_top_product.dart';

class OwnerDashboardMetrics {
  final double totalRevenue;
  final double paidRevenue;
  final int completedOrderCount;
  final int cancelledOrderCount;
  final double averageOrderValue;
  final List<OwnerDashboardTopProduct> topProducts;

  const OwnerDashboardMetrics({
    required this.totalRevenue,
    required this.paidRevenue,
    required this.completedOrderCount,
    required this.cancelledOrderCount,
    required this.averageOrderValue,
    required this.topProducts,
  });

  bool get hasSalesData =>
      totalRevenue > 0 ||
      paidRevenue > 0 ||
      completedOrderCount > 0 ||
      topProducts.isNotEmpty;
}

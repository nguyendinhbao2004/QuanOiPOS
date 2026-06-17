import '../../domain/entities/owner_dashboard_insight.dart';
import '../../domain/entities/owner_dashboard_insight_type.dart';
import '../../domain/entities/owner_dashboard_metrics.dart';
import '../../domain/entities/owner_dashboard_top_product.dart';

class OwnerDashboardInsightModel {
  final int id;
  final int storeId;
  final int type;
  final DateTime fromDate;
  final DateTime toDate;
  final String content;
  final OwnerDashboardMetricsModel metrics;
  final DateTime? createdAt;

  const OwnerDashboardInsightModel({
    required this.id,
    required this.storeId,
    required this.type,
    required this.fromDate,
    required this.toDate,
    required this.content,
    required this.metrics,
    required this.createdAt,
  });

  factory OwnerDashboardInsightModel.fromJson(Object? json) {
    final map = _asMap(json);
    return OwnerDashboardInsightModel(
      id: _asInt(map['id']),
      storeId: _asInt(map['storeId']),
      type: _asInt(map['type'], fallback: 1),
      fromDate: _asDateTime(map['fromDate']),
      toDate: _asDateTime(map['toDate']),
      content: _asString(map['content']),
      metrics: OwnerDashboardMetricsModel.fromJson(map['metrics']),
      createdAt: _asNullableDateTime(map['createdAt']),
    );
  }

  OwnerDashboardInsight toEntity() {
    return OwnerDashboardInsight(
      id: id,
      storeId: storeId,
      type: OwnerDashboardInsightType.fromApiValue(type),
      fromDate: fromDate,
      toDate: toDate,
      content: content,
      metrics: metrics.toEntity(),
      createdAt: createdAt,
    );
  }
}

class OwnerDashboardMetricsModel {
  final double totalRevenue;
  final double paidRevenue;
  final int completedOrderCount;
  final int cancelledOrderCount;
  final double averageOrderValue;
  final List<OwnerDashboardTopProductModel> topProducts;

  const OwnerDashboardMetricsModel({
    required this.totalRevenue,
    required this.paidRevenue,
    required this.completedOrderCount,
    required this.cancelledOrderCount,
    required this.averageOrderValue,
    required this.topProducts,
  });

  factory OwnerDashboardMetricsModel.fromJson(Object? json) {
    final map = _asMap(json);
    return OwnerDashboardMetricsModel(
      totalRevenue: _asDouble(map['totalRevenue']),
      paidRevenue: _asDouble(map['paidRevenue']),
      completedOrderCount: _asInt(map['completedOrderCount']),
      cancelledOrderCount: _asInt(map['cancelledOrderCount']),
      averageOrderValue: _asDouble(map['averageOrderValue']),
      topProducts: _asList(
        map['topProducts'],
      ).map(OwnerDashboardTopProductModel.fromJson).toList(),
    );
  }

  OwnerDashboardMetrics toEntity() {
    return OwnerDashboardMetrics(
      totalRevenue: totalRevenue,
      paidRevenue: paidRevenue,
      completedOrderCount: completedOrderCount,
      cancelledOrderCount: cancelledOrderCount,
      averageOrderValue: averageOrderValue,
      topProducts: topProducts.map((product) => product.toEntity()).toList(),
    );
  }
}

class OwnerDashboardTopProductModel {
  final int productId;
  final String productName;
  final int orderItemCount;

  const OwnerDashboardTopProductModel({
    required this.productId,
    required this.productName,
    required this.orderItemCount,
  });

  factory OwnerDashboardTopProductModel.fromJson(Object? json) {
    final map = _asMap(json);
    return OwnerDashboardTopProductModel(
      productId: _asInt(map['productId']),
      productName: _asString(map['productName']),
      orderItemCount: _asInt(map['orderItemCount']),
    );
  }

  OwnerDashboardTopProduct toEntity() {
    return OwnerDashboardTopProduct(
      productId: productId,
      productName: productName,
      orderItemCount: orderItemCount,
    );
  }
}

Map<String, dynamic> _asMap(Object? json) {
  if (json is Map<String, dynamic>) {
    return json;
  }

  if (json is Map) {
    return json.map((key, value) => MapEntry(key.toString(), value));
  }

  return const {};
}

List<Object?> _asList(Object? json) {
  if (json is List) {
    return json;
  }

  return const [];
}

int _asInt(Object? value, {int fallback = 0}) {
  if (value is int) {
    return value;
  }

  if (value is num) {
    return value.toInt();
  }

  if (value is String) {
    return int.tryParse(value) ?? fallback;
  }

  return fallback;
}

double _asDouble(Object? value) {
  if (value is num) {
    return value.toDouble();
  }

  if (value is String) {
    return double.tryParse(value) ?? 0;
  }

  return 0;
}

String _asString(Object? value) {
  return value?.toString() ?? '';
}

DateTime _asDateTime(Object? value) {
  return _asNullableDateTime(value) ?? DateTime.fromMillisecondsSinceEpoch(0);
}

DateTime? _asNullableDateTime(Object? value) {
  if (value is DateTime) {
    return value;
  }

  if (value is String && value.trim().isNotEmpty) {
    return DateTime.tryParse(value);
  }

  return null;
}

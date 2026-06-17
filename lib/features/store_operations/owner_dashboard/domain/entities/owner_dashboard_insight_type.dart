enum OwnerDashboardInsightType {
  trend(1, 'Trend'),
  suggestion(2, 'Suggestion');

  final int apiValue;
  final String label;

  const OwnerDashboardInsightType(this.apiValue, this.label);

  static OwnerDashboardInsightType fromApiValue(int value) {
    return OwnerDashboardInsightType.values.firstWhere(
      (type) => type.apiValue == value,
      orElse: () => OwnerDashboardInsightType.trend,
    );
  }
}

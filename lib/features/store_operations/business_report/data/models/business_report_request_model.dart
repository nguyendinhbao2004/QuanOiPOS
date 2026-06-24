class BusinessReportRequestModel {
  final int storeId;
  final DateTime fromDate;
  final DateTime toDate;
  final int timezoneOffsetMinutes;
  final int type;

  const BusinessReportRequestModel({
    required this.storeId,
    required this.fromDate,
    required this.toDate,
    required this.timezoneOffsetMinutes,
    this.type = 3,
  });

  Map<String, dynamic> toJson() {
    return {
      'storeId': storeId,
      'fromDate': _formatDate(fromDate),
      'toDate': _formatDate(toDate),
      'timezoneOffsetMinutes': timezoneOffsetMinutes,
      'type': type,
    };
  }

  String _formatDate(DateTime value) {
    final local = DateTime(value.year, value.month, value.day);
    final month = local.month.toString().padLeft(2, '0');
    final day = local.day.toString().padLeft(2, '0');
    return '${local.year}-$month-$day';
  }
}

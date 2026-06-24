import '../../domain/entities/business_report.dart';

enum BusinessReportStatus { initial, loading, ready, error }

class BusinessReportState {
  final BusinessReportStatus status;
  final DateTime fromDate;
  final DateTime toDate;
  final BusinessReport? report;
  final String? errorMessage;

  const BusinessReportState({
    required this.status,
    required this.fromDate,
    required this.toDate,
    required this.report,
    required this.errorMessage,
  });

  factory BusinessReportState.initial() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    return BusinessReportState(
      status: BusinessReportStatus.initial,
      fromDate: today.subtract(const Duration(days: 29)),
      toDate: today,
      report: null,
      errorMessage: null,
    );
  }

  bool get isLoading => status == BusinessReportStatus.loading;

  int get rangeLengthInDays {
    return DateTime(toDate.year, toDate.month, toDate.day)
            .difference(DateTime(fromDate.year, fromDate.month, fromDate.day))
            .inDays +
        1;
  }

  BusinessReportState copyWith({
    BusinessReportStatus? status,
    DateTime? fromDate,
    DateTime? toDate,
    BusinessReport? report,
    String? errorMessage,
    bool clearReport = false,
    bool clearError = false,
  }) {
    return BusinessReportState(
      status: status ?? this.status,
      fromDate: fromDate ?? this.fromDate,
      toDate: toDate ?? this.toDate,
      report: clearReport ? null : (report ?? this.report),
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }
}

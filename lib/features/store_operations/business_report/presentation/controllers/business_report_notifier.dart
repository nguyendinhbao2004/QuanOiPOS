import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/business_report_providers.dart';
import 'business_report_state.dart';

class BusinessReportNotifier
    extends AutoDisposeFamilyNotifier<BusinessReportState, int> {
  static const int _maxRangeDays = 90;

  late final int _storeId;

  @override
  BusinessReportState build(int arg) {
    _storeId = arg;
    return BusinessReportState.initial();
  }

  void changeDateRange(DateTime fromDate, DateTime toDate) {
    state = state.copyWith(
      fromDate: _dateOnly(fromDate),
      toDate: _dateOnly(toDate),
      clearError: true,
    );
  }

  Future<void> createReport() async {
    if (state.isLoading) {
      return;
    }

    if (state.fromDate.isAfter(state.toDate)) {
      state = state.copyWith(
        status: BusinessReportStatus.error,
        errorMessage: 'Ngày bắt đầu không được lớn hơn ngày kết thúc.',
      );
      return;
    }

    if (state.rangeLengthInDays > _maxRangeDays) {
      state = state.copyWith(
        status: BusinessReportStatus.error,
        errorMessage: 'Khoảng ngày tối đa là 90 ngày.',
      );
      return;
    }

    state = state.copyWith(
      status: BusinessReportStatus.loading,
      clearError: true,
    );

    try {
      final now = DateTime.now();
      final report = await ref.read(createBusinessReportUseCaseProvider)(
        storeId: _storeId,
        fromDate: state.fromDate,
        toDate: state.toDate,
        timezoneOffsetMinutes: now.timeZoneOffset.inMinutes,
      );

      state = state.copyWith(
        status: BusinessReportStatus.ready,
        report: report,
        clearError: true,
      );
    } catch (error) {
      state = state.copyWith(
        status: BusinessReportStatus.error,
        errorMessage: _cleanError(error),
      );
    }
  }

  DateTime _dateOnly(DateTime value) {
    return DateTime(value.year, value.month, value.day);
  }

  String _cleanError(Object error) {
    return error.toString().replaceFirst('Exception: ', '');
  }
}

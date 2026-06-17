enum OwnerDashboardPeriodType {
  day('Ngày'),
  week('Tuần'),
  month('Tháng');

  final String label;

  const OwnerDashboardPeriodType(this.label);
}

class OwnerDashboardPeriod {
  final OwnerDashboardPeriodType type;
  final DateTime anchorDate;
  final DateTime fromDate;
  final DateTime toDate;

  const OwnerDashboardPeriod({
    required this.type,
    required this.anchorDate,
    required this.fromDate,
    required this.toDate,
  });

  factory OwnerDashboardPeriod.today({DateTime? now}) {
    return OwnerDashboardPeriod.from(
      type: OwnerDashboardPeriodType.day,
      anchorDate: now ?? DateTime.now(),
    );
  }

  factory OwnerDashboardPeriod.from({
    required OwnerDashboardPeriodType type,
    required DateTime anchorDate,
  }) {
    final localAnchor = anchorDate.toLocal();
    final dayStart = DateTime(
      localAnchor.year,
      localAnchor.month,
      localAnchor.day,
    );

    return switch (type) {
      OwnerDashboardPeriodType.day => OwnerDashboardPeriod(
        type: type,
        anchorDate: dayStart,
        fromDate: dayStart,
        toDate: _endOfDay(dayStart),
      ),
      OwnerDashboardPeriodType.week => _weekPeriod(dayStart),
      OwnerDashboardPeriodType.month => _monthPeriod(dayStart),
    };
  }

  OwnerDashboardPeriod changeType(OwnerDashboardPeriodType nextType) {
    return OwnerDashboardPeriod.from(type: nextType, anchorDate: anchorDate);
  }

  OwnerDashboardPeriod changeAnchor(DateTime nextAnchor) {
    return OwnerDashboardPeriod.from(type: type, anchorDate: nextAnchor);
  }

  static OwnerDashboardPeriod _weekPeriod(DateTime dayStart) {
    final start = dayStart.subtract(Duration(days: dayStart.weekday - 1));
    return OwnerDashboardPeriod(
      type: OwnerDashboardPeriodType.week,
      anchorDate: dayStart,
      fromDate: start,
      toDate: _endOfDay(start.add(const Duration(days: 6))),
    );
  }

  static OwnerDashboardPeriod _monthPeriod(DateTime dayStart) {
    final start = DateTime(dayStart.year, dayStart.month);
    final nextMonth = DateTime(dayStart.year, dayStart.month + 1);
    return OwnerDashboardPeriod(
      type: OwnerDashboardPeriodType.month,
      anchorDate: dayStart,
      fromDate: start,
      toDate: nextMonth.subtract(const Duration(milliseconds: 1)),
    );
  }

  static DateTime _endOfDay(DateTime dayStart) {
    return dayStart
        .add(const Duration(days: 1))
        .subtract(const Duration(milliseconds: 1));
  }
}

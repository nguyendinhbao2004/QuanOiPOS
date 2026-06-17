import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/owner_dashboard_insight_type.dart';
import '../../domain/entities/owner_dashboard_period.dart';
import '../providers/owner_dashboard_providers.dart';
import 'owner_dashboard_state.dart';

class OwnerDashboardNotifier
    extends AutoDisposeFamilyNotifier<OwnerDashboardState, int> {
  late final int _storeId;
  bool _initialLoadStarted = false;

  @override
  OwnerDashboardState build(int arg) {
    _storeId = arg;
    Future.microtask(load);
    return OwnerDashboardState.initial();
  }

  Future<void> load() async {
    if (_initialLoadStarted && state.status == OwnerDashboardStatus.loading) {
      return;
    }

    _initialLoadStarted = true;
    state = state.copyWith(
      status: OwnerDashboardStatus.loading,
      clearError: true,
    );

    try {
      final insight = await ref.read(loadOwnerDashboardInsightUseCaseProvider)(
        storeId: _storeId,
        period: state.period,
        type: state.type,
      );
      state = state.copyWith(
        status: OwnerDashboardStatus.ready,
        insight: insight,
        clearError: true,
      );
    } catch (error) {
      state = state.copyWith(
        status: OwnerDashboardStatus.error,
        errorMessage: _cleanError(error),
      );
    }
  }

  Future<void> changePeriodType(OwnerDashboardPeriodType type) async {
    if (state.period.type == type) {
      return;
    }

    state = state.copyWith(period: state.period.changeType(type));
    await load();
  }

  Future<void> changeAnchorDate(DateTime anchorDate) async {
    state = state.copyWith(period: state.period.changeAnchor(anchorDate));
    await load();
  }

  Future<void> changeInsightType(OwnerDashboardInsightType type) async {
    if (state.type == type) {
      return;
    }

    state = state.copyWith(type: type);
    await load();
  }

  String _cleanError(Object error) {
    return error.toString().replaceFirst('Exception: ', '');
  }
}

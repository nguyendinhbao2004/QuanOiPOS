import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/table_area_group.dart';
import '../providers/table_management_providers.dart';
import 'table_management_state.dart';

class TableManagementNotifier
    extends
        AutoDisposeFamilyNotifier<TableManagementState, TableManagementAccess> {
  late final TableManagementAccess _access;
  bool _initialLoadStarted = false;

  @override
  TableManagementState build(TableManagementAccess arg) {
    _access = arg;
    Future.microtask(load);
    return TableManagementState.initial().copyWith(
      canViewTables: arg.canViewTables,
    );
  }

  Future<void> load() async {
    if (_initialLoadStarted && state.status == TableManagementStatus.loading) {
      return;
    }

    _initialLoadStarted = true;

    if (!_access.canViewAreas) {
      state = state.copyWith(
        status: TableManagementStatus.forbidden,
        canViewTables: _access.canViewTables,
        errorMessage: 'Bạn chưa có quyền xem quản lý bàn',
      );
      return;
    }

    state = state.copyWith(
      status: TableManagementStatus.loading,
      canViewTables: _access.canViewTables,
      clearError: true,
    );

    try {
      final areas = await ref.read(loadAreasUseCaseProvider)(_access.storeId);
      final tableGroups = _access.canViewTables
          ? await ref.read(loadTableGroupsUseCaseProvider)(
              storeId: _access.storeId,
              areaId: state.selectedAreaId,
            )
          : const <TableAreaGroup>[];

      state = state.copyWith(
        status: TableManagementStatus.ready,
        areas: areas,
        tableGroups: tableGroups,
        canViewTables: _access.canViewTables,
        clearError: true,
      );
    } catch (error) {
      state = state.copyWith(
        status: TableManagementStatus.error,
        errorMessage: _cleanError(error),
      );
    }
  }

  Future<void> selectArea(int? areaId) async {
    if (state.selectedAreaId == areaId) {
      return;
    }

    state = state.copyWith(
      selectedAreaId: areaId,
      clearSelectedArea: areaId == null,
    );

    if (!_access.canViewTables) {
      return;
    }

    await load();
  }

  void setStatusFilter(TableStatusFilter filter) {
    state = state.copyWith(statusFilter: filter);
  }

  String _cleanError(Object error) {
    return error.toString().replaceFirst('Exception: ', '');
  }
}

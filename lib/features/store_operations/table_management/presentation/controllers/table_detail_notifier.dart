import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/area.dart';
import '../../domain/entities/dining_table.dart';
import '../../domain/entities/table_status.dart';
import '../providers/table_management_providers.dart';
import 'table_detail_state.dart';

class TableDetailNotifier
    extends AutoDisposeFamilyNotifier<TableDetailState, TableDetailAccess> {
  late final TableDetailAccess _access;
  bool _initialLoadStarted = false;

  @override
  TableDetailState build(TableDetailAccess arg) {
    _access = arg;
    Future.microtask(load);
    return const TableDetailState.initial();
  }

  Future<void> load() async {
    if (_initialLoadStarted && state.status == TableDetailStatus.loading) {
      return;
    }

    _initialLoadStarted = true;

    if (!_access.canViewTable) {
      state = state.copyWith(
        status: TableDetailStatus.forbidden,
        errorMessage: 'Bạn chưa có quyền xem chi tiết bàn',
      );
      return;
    }

    state = state.copyWith(
      status: TableDetailStatus.loading,
      isMutating: false,
      hasChanged: false,
      clearError: true,
    );

    try {
      final tableFuture = ref.read(loadTableDetailUseCaseProvider)(
        _access.tableId,
      );
      final sessionsFuture = ref.read(loadTableSessionsUseCaseProvider)(
        _access.tableId,
      );

      final table = await tableFuture;
      final sessions = await sessionsFuture;
      final area = await _loadAreaOrNull(table.areaId);

      state = state.copyWith(
        status: TableDetailStatus.ready,
        table: table,
        area: area,
        clearArea: area == null,
        sessions: sessions,
        clearError: true,
      );
    } catch (error) {
      state = state.copyWith(
        status: TableDetailStatus.error,
        errorMessage: _cleanError(error),
      );
    }
  }

  Future<void> toggleDisabled() async {
    _ensureAllowed(
      _access.canUpdateTable,
      'Bạn chưa có quyền cập nhật trạng thái bàn',
    );

    final table = _requireTable();
    final nextStatus = table.status == TableStatus.available
        ? TableStatus.disabled
        : TableStatus.available;

    await _mutate(() async {
      await ref.read(updateTableStatusUseCaseProvider)(
        tableId: table.id,
        status: nextStatus,
      );
      await _refreshData();
      state = state.copyWith(hasChanged: true);
    });
  }

  Future<void> openSession() async {
    _ensureAllowed(_access.canOpenSession, 'Bạn chưa có quyền mở phiên bàn');

    final table = _requireTable();
    if (table.status != TableStatus.available &&
        table.status != TableStatus.reserved) {
      throw Exception('Chỉ có thể mở phiên cho bàn trống hoặc đã đặt');
    }

    await _mutate(() async {
      await ref.read(openTableSessionUseCaseProvider)(table.id);
      await _refreshData();
      state = state.copyWith(hasChanged: true);
    });
  }

  Future<void> _refreshData() async {
    final table = await ref.read(loadTableDetailUseCaseProvider)(
      _access.tableId,
    );
    final sessions = await ref.read(loadTableSessionsUseCaseProvider)(
      _access.tableId,
    );
    final area = await _loadAreaOrNull(table.areaId);

    state = state.copyWith(
      status: TableDetailStatus.ready,
      table: table,
      area: area,
      clearArea: area == null,
      sessions: sessions,
      clearError: true,
    );
  }

  Future<void> _mutate(Future<void> Function() action) async {
    state = state.copyWith(isMutating: true, clearError: true);
    try {
      await action();
    } catch (error) {
      state = state.copyWith(errorMessage: _cleanError(error));
      rethrow;
    } finally {
      state = state.copyWith(isMutating: false);
    }
  }

  Future<Area?> _loadAreaOrNull(int areaId) async {
    try {
      return await ref.read(loadAreaDetailUseCaseProvider)(areaId);
    } catch (_) {
      return null;
    }
  }

  DiningTable _requireTable() {
    final table = state.table;
    if (table == null) {
      throw Exception('Chưa có dữ liệu bàn');
    }

    return table;
  }

  void _ensureAllowed(bool isAllowed, String message) {
    if (!isAllowed) {
      throw Exception(message);
    }
  }

  String _cleanError(Object error) {
    return error.toString().replaceFirst('Exception: ', '');
  }
}

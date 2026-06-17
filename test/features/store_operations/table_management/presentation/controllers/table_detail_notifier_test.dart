import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quan_oi/features/store_operations/table_management/domain/entities/area.dart';
import 'package:quan_oi/features/store_operations/table_management/domain/entities/dining_table.dart';
import 'package:quan_oi/features/store_operations/table_management/domain/entities/table_area_group.dart';
import 'package:quan_oi/features/store_operations/table_management/domain/entities/table_session.dart';
import 'package:quan_oi/features/store_operations/table_management/domain/entities/table_status.dart';
import 'package:quan_oi/features/store_operations/table_management/domain/repositories/table_management_repository.dart';
import 'package:quan_oi/features/store_operations/table_management/domain/usecases/load_area_detail_use_case.dart';
import 'package:quan_oi/features/store_operations/table_management/domain/usecases/load_table_detail_use_case.dart';
import 'package:quan_oi/features/store_operations/table_management/domain/usecases/load_table_sessions_use_case.dart';
import 'package:quan_oi/features/store_operations/table_management/domain/usecases/open_table_session_use_case.dart';
import 'package:quan_oi/features/store_operations/table_management/domain/usecases/update_table_status_use_case.dart';
import 'package:quan_oi/features/store_operations/table_management/presentation/controllers/table_detail_state.dart';
import 'package:quan_oi/features/store_operations/table_management/presentation/providers/table_management_providers.dart';

void main() {
  test('without TABLE.VIEW enters forbidden and skips repository', () async {
    final repository = _FakeTableDetailRepository();
    final container = _container(repository);
    addTearDown(container.dispose);

    final access = _access(canView: false);
    await container.read(tableDetailNotifierProvider(access).notifier).load();

    final state = container.read(tableDetailNotifierProvider(access));

    expect(state.status, TableDetailStatus.forbidden);
    expect(repository.loadTableDetailCallCount, 0);
    expect(repository.loadTableSessionsCallCount, 0);
  });

  test('loads current session and history sessions', () async {
    final repository = _FakeTableDetailRepository(
      tableStatus: TableStatus.occupied,
    );
    final container = _container(repository);
    addTearDown(container.dispose);

    final access = _access(tableId: 4);
    await container.read(tableDetailNotifierProvider(access).notifier).load();

    final state = container.read(tableDetailNotifierProvider(access));

    expect(state.status, TableDetailStatus.ready);
    expect(state.currentSession?.id, 10);
    expect(state.historySessions.map((session) => session.id), [11, 12]);
    expect(state.areaName, 'Bên trong');
  });

  test('toggle status is blocked without TABLE.UPDATE', () async {
    final repository = _FakeTableDetailRepository();
    final container = _container(repository);
    addTearDown(container.dispose);

    final access = _access(canUpdate: false);
    final notifier = container.read(
      tableDetailNotifierProvider(access).notifier,
    );
    await notifier.load();

    await expectLater(notifier.toggleDisabled(), throwsA(isA<Exception>()));
    expect(repository.updateTableStatusCallCount, 0);
  });

  test('open session is blocked without TABLE.OPEN_SESSION', () async {
    final repository = _FakeTableDetailRepository();
    final container = _container(repository);
    addTearDown(container.dispose);

    final access = _access(canOpenSession: false);
    final notifier = container.read(
      tableDetailNotifierProvider(access).notifier,
    );
    await notifier.load();

    await expectLater(notifier.openSession(), throwsA(isA<Exception>()));
    expect(repository.openTableSessionCallCount, 0);
    expect(repository.updateTableStatusCallCount, 0);
  });

  test('open session creates table session and refetches data', () async {
    final repository = _FakeTableDetailRepository();
    final container = _container(repository);
    addTearDown(container.dispose);

    final access = _access();
    final notifier = container.read(
      tableDetailNotifierProvider(access).notifier,
    );
    await notifier.load();
    final initialTableLoadCount = repository.loadTableDetailCallCount;

    await notifier.openSession();
    final state = container.read(tableDetailNotifierProvider(access));

    expect(repository.openTableSessionCallCount, 1);
    expect(repository.updateTableStatusCallCount, 0);
    expect(
      repository.loadTableDetailCallCount,
      greaterThan(initialTableLoadCount),
    );
    expect(state.hasChanged, isTrue);
  });
}

ProviderContainer _container(_FakeTableDetailRepository repository) {
  return ProviderContainer(
    overrides: [
      loadTableDetailUseCaseProvider.overrideWithValue(
        LoadTableDetailUseCase(repository),
      ),
      loadAreaDetailUseCaseProvider.overrideWithValue(
        LoadAreaDetailUseCase(repository),
      ),
      loadTableSessionsUseCaseProvider.overrideWithValue(
        LoadTableSessionsUseCase(repository),
      ),
      updateTableStatusUseCaseProvider.overrideWithValue(
        UpdateTableStatusUseCase(repository),
      ),
      openTableSessionUseCaseProvider.overrideWithValue(
        OpenTableSessionUseCase(repository),
      ),
    ],
  );
}

TableDetailAccess _access({
  int tableId = 3,
  bool canView = true,
  bool canUpdate = true,
  bool canOpenSession = true,
}) {
  return TableDetailAccess(
    storeId: 5,
    tableId: tableId,
    canViewTable: canView,
    canUpdateTable: canUpdate,
    canOpenSession: canOpenSession,
  );
}

class _FakeTableDetailRepository implements TableManagementRepository {
  final TableStatus tableStatus;
  int loadTableDetailCallCount = 0;
  int loadAreaDetailCallCount = 0;
  int loadTableSessionsCallCount = 0;
  int updateTableStatusCallCount = 0;
  int openTableSessionCallCount = 0;
  TableStatus? lastUpdatedStatus;

  _FakeTableDetailRepository({this.tableStatus = TableStatus.available});

  @override
  Future<DiningTable> loadTableDetail(int tableId) async {
    loadTableDetailCallCount += 1;
    return DiningTable(
      id: tableId,
      storeId: 5,
      areaId: 6,
      name: 'Bàn $tableId',
      capacity: 4,
      status: tableStatus,
      isDeleted: false,
    );
  }

  @override
  Future<Area> loadAreaDetail(int areaId) async {
    loadAreaDetailCallCount += 1;
    return Area(
      id: areaId,
      storeId: 5,
      name: 'Bên trong',
      description: '',
      displayOrder: 1,
      isActive: true,
      isDeleted: false,
    );
  }

  @override
  Future<List<TableSession>> loadTableSessions(int tableId) async {
    loadTableSessionsCallCount += 1;
    return [
      TableSession(
        id: 10,
        tableId: tableId,
        openTime: DateTime(2026, 6, 10, 11),
        status: TableSessionStatus.open,
        isDeleted: false,
      ),
      TableSession(
        id: 11,
        tableId: tableId,
        openTime: DateTime(2026, 6, 9, 11),
        closeTime: DateTime(2026, 6, 9, 12),
        status: TableSessionStatus.closed,
        isDeleted: false,
      ),
      TableSession(
        id: 12,
        tableId: tableId,
        openTime: DateTime(2026, 6, 8, 11),
        closeTime: DateTime(2026, 6, 8, 11, 30),
        status: TableSessionStatus.cancelled,
        isDeleted: false,
      ),
    ];
  }

  @override
  Future<List<TableSession>> loadOpenTableSessions(int tableId) async {
    return const [];
  }

  @override
  Future<void> updateTableStatus({
    required int tableId,
    required TableStatus status,
  }) async {
    updateTableStatusCallCount += 1;
    lastUpdatedStatus = status;
  }

  @override
  Future<TableSession> openTableSession(int tableId) async {
    openTableSessionCallCount += 1;
    return TableSession(
      id: 99,
      tableId: tableId,
      openTime: DateTime(2026, 6, 10, 12),
      status: TableSessionStatus.open,
      isDeleted: false,
    );
  }

  @override
  Future<void> closeTableSession(int tableSessionId) async {
    throw UnimplementedError();
  }

  @override
  Future<List<Area>> loadAreas(int storeId) async => const [];

  @override
  Future<List<TableAreaGroup>> loadTableGroups({
    required int storeId,
    int? areaId,
  }) async => const [];

  @override
  Future<Area> createArea({
    required int storeId,
    required String name,
    required String description,
  }) async => throw UnimplementedError();

  @override
  Future<DiningTable> createTable({
    required int storeId,
    required int areaId,
    required String name,
    required int capacity,
  }) async => throw UnimplementedError();

  @override
  Future<DiningTable> updateTable({
    required int tableId,
    required int areaId,
    required String name,
    required int capacity,
  }) async => throw UnimplementedError();

  @override
  Future<Area> updateArea({
    required int areaId,
    required String name,
    required String description,
  }) async => throw UnimplementedError();

  @override
  Future<Area> updateAreaDisplayOrder({
    required int areaId,
    required int displayOrder,
  }) async => throw UnimplementedError();

  @override
  Future<void> deleteArea(int areaId) async {}
}

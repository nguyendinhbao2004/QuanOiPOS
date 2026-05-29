import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quan_oi/core/storage/last_active_store_storage.dart';
import 'package:quan_oi/features/workspace_context/domain/usecases/clear_last_active_store_use_case.dart';
import 'package:quan_oi/features/workspace_context/domain/usecases/load_last_active_store_use_case.dart';
import 'package:quan_oi/features/workspace_context/domain/usecases/save_last_active_store_use_case.dart';
import 'package:quan_oi/features/workspace_context/presentation/controllers/last_active_store_state.dart';
import 'package:quan_oi/features/workspace_context/presentation/providers/workspace_context_providers.dart';

void main() {
  test(
    'last active store notifier loads stored id on provider creation',
    () async {
      final storage = _FakeLastActiveStoreStorage(initialStoreId: 5);
      final container = _containerWithStorage(storage);
      addTearDown(container.dispose);

      expect(
        container.read(lastActiveStoreNotifierProvider).status,
        LastActiveStoreStatus.bootstrapping,
      );

      await _flushMicrotasks();

      final state = container.read(lastActiveStoreNotifierProvider);
      expect(state.status, LastActiveStoreStatus.ready);
      expect(state.lastStoreId, 5);
    },
  );

  test('save updates state and storage', () async {
    final storage = _FakeLastActiveStoreStorage();
    final container = _containerWithStorage(storage);
    addTearDown(container.dispose);

    container.read(lastActiveStoreNotifierProvider);
    await _flushMicrotasks();

    await container.read(lastActiveStoreNotifierProvider.notifier).save(7);

    expect(storage.lastStoreId, 7);
    expect(container.read(lastActiveStoreNotifierProvider).lastStoreId, 7);
  });

  test('clear removes state and storage', () async {
    final storage = _FakeLastActiveStoreStorage(initialStoreId: 5);
    final container = _containerWithStorage(storage);
    addTearDown(container.dispose);

    container.read(lastActiveStoreNotifierProvider);
    await _flushMicrotasks();

    await container.read(lastActiveStoreNotifierProvider.notifier).clear();

    expect(storage.lastStoreId, isNull);
    expect(container.read(lastActiveStoreNotifierProvider).lastStoreId, isNull);
  });
}

ProviderContainer _containerWithStorage(_FakeLastActiveStoreStorage storage) {
  return ProviderContainer(
    overrides: [
      loadLastActiveStoreUseCaseProvider.overrideWithValue(
        LoadLastActiveStoreUseCase(storage),
      ),
      saveLastActiveStoreUseCaseProvider.overrideWithValue(
        SaveLastActiveStoreUseCase(storage),
      ),
      clearLastActiveStoreUseCaseProvider.overrideWithValue(
        ClearLastActiveStoreUseCase(storage),
      ),
    ],
  );
}

Future<void> _flushMicrotasks() async {
  await Future<void>.delayed(Duration.zero);
  await Future<void>.delayed(Duration.zero);
}

class _FakeLastActiveStoreStorage implements LastActiveStoreStorage {
  int? lastStoreId;

  _FakeLastActiveStoreStorage({int? initialStoreId})
    : lastStoreId = initialStoreId;

  @override
  Future<int?> getLastActiveStoreId() async {
    return lastStoreId;
  }

  @override
  Future<void> saveLastActiveStoreId(int storeId) async {
    lastStoreId = storeId;
  }

  @override
  Future<void> clearLastActiveStoreId() async {
    lastStoreId = null;
  }
}

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quan_oi/features/workspace_context/domain/entities/store.dart';
import 'package:quan_oi/features/workspace_context/domain/entities/store_access_context.dart';
import 'package:quan_oi/features/workspace_context/domain/entities/store_permission.dart';
import 'package:quan_oi/features/workspace_context/domain/exceptions/store_access_denied_exception.dart';
import 'package:quan_oi/features/workspace_context/domain/repositories/workspace_repository.dart';
import 'package:quan_oi/features/workspace_context/domain/usecases/load_my_stores_use_case.dart';
import 'package:quan_oi/features/workspace_context/domain/usecases/load_store_access_context_use_case.dart';
import 'package:quan_oi/features/workspace_context/presentation/controllers/store_access_state.dart';
import 'package:quan_oi/features/workspace_context/presentation/providers/workspace_context_providers.dart';

void main() {
  test(
    'store access notifier loads access context on provider creation',
    () async {
      final repository = _FakeWorkspaceRepository();
      final container = _containerWithRepository(repository);
      addTearDown(container.dispose);
      final subscription = _listen(container, 2);
      addTearDown(subscription.close);

      expect(
        container.read(storeAccessNotifierProvider(2)).status,
        StoreAccessStatus.initial,
      );

      await _flushMicrotasks();

      final state = container.read(storeAccessNotifierProvider(2));
      expect(state.status, StoreAccessStatus.ready);
      expect(state.context?.store.id, 2);
      expect(state.can('DASHBOARD.VIEW'), isTrue);
      expect(state.can('STORE.UPDATE'), isTrue);
      expect(state.can('AREA.VIEW'), isFalse);
    },
  );

  test(
    'store access notifier exposes forbidden when permission API denies',
    () async {
      final repository = _FakeWorkspaceRepository(
        accessError: const StoreAccessDeniedException(
          'Tài khoản người dùng không có quyền truy cập vào cửa hàng!',
        ),
      );
      final container = _containerWithRepository(repository);
      addTearDown(container.dispose);
      final subscription = _listen(container, 2);
      addTearDown(subscription.close);

      container.read(storeAccessNotifierProvider(2));
      await _flushMicrotasks();

      final state = container.read(storeAccessNotifierProvider(2));
      expect(state.status, StoreAccessStatus.forbidden);
      expect(
        state.errorMessage,
        'Tài khoản người dùng không có quyền truy cập vào cửa hàng!',
      );
    },
  );

  test(
    'store access notifier exposes error for generic load failures',
    () async {
      final repository = _FakeWorkspaceRepository(
        accessError: Exception('Network down'),
      );
      final container = _containerWithRepository(repository);
      addTearDown(container.dispose);
      final subscription = _listen(container, 2);
      addTearDown(subscription.close);

      container.read(storeAccessNotifierProvider(2));
      await _flushMicrotasks();

      final state = container.read(storeAccessNotifierProvider(2));
      expect(state.status, StoreAccessStatus.error);
      expect(state.errorMessage, 'Network down');
    },
  );
}

ProviderContainer _containerWithRepository(
  _FakeWorkspaceRepository repository,
) {
  return ProviderContainer(
    overrides: [
      loadMyStoresUseCaseProvider.overrideWithValue(
        LoadMyStoresUseCase(repository),
      ),
      loadStoreAccessContextUseCaseProvider.overrideWithValue(
        LoadStoreAccessContextUseCase(repository),
      ),
    ],
  );
}

Future<void> _flushMicrotasks() async {
  await Future<void>.delayed(Duration.zero);
  await Future<void>.delayed(Duration.zero);
}

ProviderSubscription<StoreAccessState> _listen(
  ProviderContainer container,
  int storeId,
) {
  return container.listen<StoreAccessState>(
    storeAccessNotifierProvider(storeId),
    (previous, next) {},
  );
}

class _FakeWorkspaceRepository implements WorkspaceRepository {
  final Exception? accessError;

  const _FakeWorkspaceRepository({this.accessError});

  @override
  Future<List<Store>> loadMyStores() async {
    return const [_store];
  }

  @override
  Future<Store> loadStoreById(int storeId) async {
    return _store;
  }

  @override
  Future<List<StorePermission>> loadMyStorePermissions(int storeId) async {
    return const [
      StorePermission(permissionId: 1, code: 'DASHBOARD.VIEW'),
      StorePermission(permissionId: 3, code: 'STORE.UPDATE'),
    ];
  }

  @override
  Future<StoreAccessContext> loadStoreAccessContext(int storeId) async {
    final error = accessError;
    if (error != null) {
      throw error;
    }

    return StoreAccessContext(
      store: await loadStoreById(storeId),
      permissions: await loadMyStorePermissions(storeId),
    );
  }
}

const _store = Store(
  id: 2,
  ownerAccountId: 8,
  storeName: 'Buffet Poseidon',
  phone: '0961813466',
  address: 'TTTM Vincom Plaza',
  status: StoreStatus.active,
  isDeleted: false,
);

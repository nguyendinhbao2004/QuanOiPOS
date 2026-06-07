import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quan_oi/core/storage/last_active_store_storage.dart';
import 'package:quan_oi/features/auth/domain/entities/account_type.dart';
import 'package:quan_oi/features/auth/presentation/controllers/auth_notifier.dart';
import 'package:quan_oi/features/auth/presentation/controllers/auth_state.dart';
import 'package:quan_oi/features/auth/presentation/providers/auth_providers.dart';
import 'package:quan_oi/features/workspace_context/domain/entities/store.dart';
import 'package:quan_oi/features/workspace_context/domain/entities/store_access_context.dart';
import 'package:quan_oi/features/workspace_context/domain/entities/store_permission.dart';
import 'package:quan_oi/features/workspace_context/domain/exceptions/store_access_denied_exception.dart';
import 'package:quan_oi/features/workspace_context/domain/repositories/workspace_repository.dart';
import 'package:quan_oi/features/workspace_context/domain/usecases/clear_last_active_store_use_case.dart';
import 'package:quan_oi/features/workspace_context/domain/usecases/clear_store_access_context_cache_use_case.dart';
import 'package:quan_oi/features/workspace_context/domain/usecases/load_cached_store_access_context_use_case.dart';
import 'package:quan_oi/features/workspace_context/domain/usecases/load_last_active_store_use_case.dart';
import 'package:quan_oi/features/workspace_context/domain/usecases/load_my_stores_use_case.dart';
import 'package:quan_oi/features/workspace_context/domain/usecases/load_store_access_context_use_case.dart';
import 'package:quan_oi/features/workspace_context/domain/usecases/save_last_active_store_use_case.dart';
import 'package:quan_oi/features/workspace_context/domain/usecases/save_store_access_context_cache_use_case.dart';
import 'package:quan_oi/features/workspace_context/presentation/controllers/store_access_state.dart';
import 'package:quan_oi/features/workspace_context/presentation/providers/workspace_context_providers.dart';

void main() {
  test(
    'store access notifier loads access context on provider creation',
    () async {
      final repository = _FakeWorkspaceRepository();
      final lastActiveStoreStorage = _FakeLastActiveStoreStorage();
      final container = _containerWithRepository(
        repository,
        lastActiveStoreStorage: lastActiveStoreStorage,
      );
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
      expect(lastActiveStoreStorage.lastStoreId, 2);
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
      final lastActiveStoreStorage = _FakeLastActiveStoreStorage(
        initialStoreId: 2,
      );
      final container = _containerWithRepository(
        repository,
        lastActiveStoreStorage: lastActiveStoreStorage,
      );
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
      expect(lastActiveStoreStorage.lastStoreId, isNull);
    },
  );

  test(
    'store access notifier exposes error for generic load failures',
    () async {
      final repository = _FakeWorkspaceRepository(
        accessError: Exception('Network down'),
      );
      final lastActiveStoreStorage = _FakeLastActiveStoreStorage(
        initialStoreId: 2,
      );
      final container = _containerWithRepository(
        repository,
        lastActiveStoreStorage: lastActiveStoreStorage,
      );
      addTearDown(container.dispose);
      final subscription = _listen(container, 2);
      addTearDown(subscription.close);

      container.read(storeAccessNotifierProvider(2));
      await _flushMicrotasks();

      final state = container.read(storeAccessNotifierProvider(2));
      expect(state.status, StoreAccessStatus.error);
      expect(state.errorMessage, 'Network down');
      expect(lastActiveStoreStorage.lastStoreId, isNull);
    },
  );

  test(
    'store access notifier renders cached context while refreshing remote data',
    () async {
      final remoteCompleter = Completer<StoreAccessContext>();
      final repository = _FakeWorkspaceRepository(
        cachedContext: _cachedAccessContext,
        accessCompleter: remoteCompleter,
      );
      final container = _containerWithRepository(repository);
      addTearDown(container.dispose);
      final subscription = _listen(container, 2);
      addTearDown(subscription.close);

      container.read(storeAccessNotifierProvider(2));
      await _flushMicrotasks();

      var state = container.read(storeAccessNotifierProvider(2));
      expect(state.status, StoreAccessStatus.ready);
      expect(state.context?.store.storeName, 'Cached Buffet');
      expect(state.isFromCache, isTrue);
      expect(state.isRefreshing, isTrue);

      remoteCompleter.complete(_remoteAccessContext);
      await _flushMicrotasks();

      state = container.read(storeAccessNotifierProvider(2));
      expect(state.status, StoreAccessStatus.ready);
      expect(state.context?.store.storeName, 'Buffet Poseidon');
      expect(state.isFromCache, isFalse);
      expect(state.isRefreshing, isFalse);
      expect(state.can('STORE.UPDATE'), isTrue);
      expect(repository.savedCache?.store.storeName, 'Buffet Poseidon');
    },
  );

  test(
    'store access notifier clears cached context when refreshed access is denied',
    () async {
      final repository = _FakeWorkspaceRepository(
        cachedContext: _cachedAccessContext,
        accessError: const StoreAccessDeniedException('Không còn quyền'),
      );
      final lastActiveStoreStorage = _FakeLastActiveStoreStorage(
        initialStoreId: 2,
      );
      final container = _containerWithRepository(
        repository,
        lastActiveStoreStorage: lastActiveStoreStorage,
      );
      addTearDown(container.dispose);
      final subscription = _listen(container, 2);
      addTearDown(subscription.close);

      container.read(storeAccessNotifierProvider(2));
      await _flushMicrotasks();

      final state = container.read(storeAccessNotifierProvider(2));
      expect(state.status, StoreAccessStatus.forbidden);
      expect(repository.cachedContext, isNull);
      expect(lastActiveStoreStorage.lastStoreId, isNull);
    },
  );

  test(
    'store access notifier keeps cached context visible on refresh error',
    () async {
      final repository = _FakeWorkspaceRepository(
        cachedContext: _cachedAccessContext,
        accessError: Exception('Network down'),
      );
      final lastActiveStoreStorage = _FakeLastActiveStoreStorage(
        initialStoreId: 2,
      );
      final container = _containerWithRepository(
        repository,
        lastActiveStoreStorage: lastActiveStoreStorage,
      );
      addTearDown(container.dispose);
      final subscription = _listen(container, 2);
      addTearDown(subscription.close);

      container.read(storeAccessNotifierProvider(2));
      await _flushMicrotasks();

      final state = container.read(storeAccessNotifierProvider(2));
      expect(state.status, StoreAccessStatus.ready);
      expect(state.context?.store.storeName, 'Cached Buffet');
      expect(state.refreshErrorMessage, 'Network down');
      expect(lastActiveStoreStorage.lastStoreId, 2);
    },
  );
}

ProviderContainer _containerWithRepository(
  _FakeWorkspaceRepository repository, {
  _FakeLastActiveStoreStorage? lastActiveStoreStorage,
}) {
  final storeStorage = lastActiveStoreStorage ?? _FakeLastActiveStoreStorage();

  return ProviderContainer(
    overrides: [
      authNotifierProvider.overrideWith(
        () => _FixedAuthNotifier(
          const AuthState(
            status: AuthStatus.authenticated,
            accountId: 8,
            accountType: AccountType.storeUser,
            fullName: 'Test User',
            email: 'user@quanoi.test',
          ),
        ),
      ),
      loadMyStoresUseCaseProvider.overrideWithValue(
        LoadMyStoresUseCase(repository),
      ),
      loadStoreAccessContextUseCaseProvider.overrideWithValue(
        LoadStoreAccessContextUseCase(repository),
      ),
      loadCachedStoreAccessContextUseCaseProvider.overrideWithValue(
        LoadCachedStoreAccessContextUseCase(repository),
      ),
      saveStoreAccessContextCacheUseCaseProvider.overrideWithValue(
        SaveStoreAccessContextCacheUseCase(repository),
      ),
      clearStoreAccessContextCacheUseCaseProvider.overrideWithValue(
        ClearStoreAccessContextCacheUseCase(repository),
      ),
      ..._lastActiveStoreOverrides(storeStorage),
    ],
  );
}

List<Override> _lastActiveStoreOverrides(_FakeLastActiveStoreStorage storage) {
  return [
    loadLastActiveStoreUseCaseProvider.overrideWithValue(
      LoadLastActiveStoreUseCase(storage),
    ),
    saveLastActiveStoreUseCaseProvider.overrideWithValue(
      SaveLastActiveStoreUseCase(storage),
    ),
    clearLastActiveStoreUseCaseProvider.overrideWithValue(
      ClearLastActiveStoreUseCase(storage),
    ),
  ];
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

class _FixedAuthNotifier extends AuthNotifier {
  final AuthState fixedState;

  _FixedAuthNotifier(this.fixedState);

  @override
  AuthState build() {
    return fixedState;
  }
}

class _FakeWorkspaceRepository implements WorkspaceRepository {
  final Exception? accessError;
  final Completer<StoreAccessContext>? accessCompleter;
  StoreAccessContext? cachedContext;
  StoreAccessContext? savedCache;

  _FakeWorkspaceRepository({
    this.accessError,
    this.accessCompleter,
    this.cachedContext,
  });

  @override
  Future<List<Store>> loadMyStores() async {
    return const [_store];
  }

  @override
  Future<Store> createStore({
    required String storeName,
    required String phone,
    required String address,
  }) async {
    return _store;
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

    final completer = accessCompleter;
    if (completer != null) {
      return completer.future;
    }

    return StoreAccessContext(
      store: await loadStoreById(storeId),
      permissions: await loadMyStorePermissions(storeId),
    );
  }

  @override
  Future<StoreAccessContext?> loadCachedStoreAccessContext({
    required int accountId,
    required int storeId,
  }) async {
    return cachedContext;
  }

  @override
  Future<void> saveStoreAccessContextCache({
    required int accountId,
    required StoreAccessContext context,
  }) async {
    savedCache = context;
    cachedContext = context;
  }

  @override
  Future<void> clearStoreAccessContextCache({
    required int accountId,
    required int storeId,
  }) async {
    cachedContext = null;
  }

  @override
  Future<void> clearAllStoreAccessContextCache() async {
    cachedContext = null;
  }
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

const _store = Store(
  id: 2,
  ownerAccountId: 8,
  storeName: 'Buffet Poseidon',
  phone: '0961813466',
  address: 'TTTM Vincom Plaza',
  status: StoreStatus.active,
  isDeleted: false,
);

const _cachedStore = Store(
  id: 2,
  ownerAccountId: 8,
  storeName: 'Cached Buffet',
  phone: '0961813466',
  address: 'Cached address',
  status: StoreStatus.active,
  isDeleted: false,
);

const _cachedAccessContext = StoreAccessContext(
  store: _cachedStore,
  permissions: [StorePermission(permissionId: 1, code: 'DASHBOARD.VIEW')],
);

const _remoteAccessContext = StoreAccessContext(
  store: _store,
  permissions: [
    StorePermission(permissionId: 1, code: 'DASHBOARD.VIEW'),
    StorePermission(permissionId: 3, code: 'STORE.UPDATE'),
  ],
);

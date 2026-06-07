import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../auth/presentation/providers/auth_providers.dart';
import '../../domain/entities/store_access_context.dart';
import '../../domain/exceptions/store_access_denied_exception.dart';
import '../providers/workspace_context_providers.dart';
import 'store_access_state.dart';

class StoreAccessNotifier
    extends AutoDisposeFamilyNotifier<StoreAccessState, int> {
  late final int _storeId;
  bool _initialLoadStarted = false;

  @override
  StoreAccessState build(int storeId) {
    _storeId = storeId;
    Future.microtask(loadAccess);
    return const StoreAccessState.initial();
  }

  Future<void> loadAccess() async {
    if (_initialLoadStarted && state.status == StoreAccessStatus.loading) {
      return;
    }

    _initialLoadStarted = true;
    final accountId = _activeAccountId;

    if (accountId != null) {
      final cachedContext = await _loadCachedStoreAccessContext(accountId);
      if (cachedContext != null) {
        state = state.copyWith(
          status: StoreAccessStatus.ready,
          context: cachedContext,
          isFromCache: true,
          isRefreshing: true,
          clearError: true,
          clearRefreshError: true,
        );
        await _refreshRemoteAccess(
          accountId: accountId,
          hasCachedContext: true,
        );
        return;
      }
    }

    state = state.copyWith(
      status: StoreAccessStatus.loading,
      isFromCache: false,
      isRefreshing: false,
      clearContext: true,
      clearError: true,
      clearRefreshError: true,
    );
    await _refreshRemoteAccess(accountId: accountId, hasCachedContext: false);
  }

  int? get _activeAccountId {
    final int? accountId;
    try {
      accountId = ref.read(authNotifierProvider).accountId;
    } catch (_) {
      return null;
    }

    if (accountId == null || accountId <= 0) {
      return null;
    }

    return accountId;
  }

  Future<void> _refreshRemoteAccess({
    required int? accountId,
    required bool hasCachedContext,
  }) async {
    try {
      final useCase = ref.read(loadStoreAccessContextUseCaseProvider);
      final context = await useCase(_storeId);
      await _saveLastActiveStore();
      if (accountId != null) {
        await _saveCachedStoreAccessContext(
          accountId: accountId,
          context: context,
        );
      }
      state = state.copyWith(
        status: StoreAccessStatus.ready,
        context: context,
        isFromCache: false,
        isRefreshing: false,
        clearError: true,
        clearRefreshError: true,
      );
    } on StoreAccessDeniedException catch (error) {
      if (accountId != null) {
        await _clearCachedStoreAccessContext(accountId);
      }
      await _clearLastActiveStore();
      state = StoreAccessState(
        status: StoreAccessStatus.forbidden,
        errorMessage: error.message,
      );
    } catch (error) {
      if (hasCachedContext && state.context != null) {
        state = state.copyWith(
          status: StoreAccessStatus.ready,
          refreshErrorMessage: _cleanError(error),
          isRefreshing: false,
          isFromCache: true,
          clearError: true,
        );
        return;
      }

      await _clearLastActiveStore();
      state = StoreAccessState(
        status: StoreAccessStatus.error,
        errorMessage: _cleanError(error),
      );
    }
  }

  Future<StoreAccessContext?> _loadCachedStoreAccessContext(
    int accountId,
  ) async {
    try {
      return await ref.read(loadCachedStoreAccessContextUseCaseProvider)(
        accountId: accountId,
        storeId: _storeId,
      );
    } catch (_) {
      return null;
    }
  }

  Future<void> _saveCachedStoreAccessContext({
    required int accountId,
    required StoreAccessContext context,
  }) async {
    try {
      await ref.read(saveStoreAccessContextCacheUseCaseProvider)(
        accountId: accountId,
        context: context,
      );
    } catch (_) {
      // Cache writes should not block access to a valid store.
    }
  }

  Future<void> _clearCachedStoreAccessContext(int accountId) async {
    try {
      await ref.read(clearStoreAccessContextCacheUseCaseProvider)(
        accountId: accountId,
        storeId: _storeId,
      );
    } catch (_) {
      // Ignore cache cleanup failures and keep the access error visible.
    }
  }

  String _cleanError(Object error) {
    return error.toString().replaceFirst('Exception: ', '');
  }

  Future<void> _saveLastActiveStore() async {
    try {
      await ref.read(lastActiveStoreNotifierProvider.notifier).save(_storeId);
    } catch (_) {
      // Last-store persistence is a UX shortcut and should not block access.
    }
  }

  Future<void> _clearLastActiveStore() async {
    try {
      await ref.read(lastActiveStoreNotifierProvider.notifier).clear();
    } catch (_) {
      // Ignore persistence failures and keep the access error visible.
    }
  }
}

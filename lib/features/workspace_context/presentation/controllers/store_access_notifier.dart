import 'package:flutter_riverpod/flutter_riverpod.dart';

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
    state = state.copyWith(status: StoreAccessStatus.loading, clearError: true);

    try {
      final useCase = ref.read(loadStoreAccessContextUseCaseProvider);
      final context = await useCase(_storeId);
      await _saveLastActiveStore();
      state = state.copyWith(
        status: StoreAccessStatus.ready,
        context: context,
        clearError: true,
      );
    } on StoreAccessDeniedException catch (error) {
      await _clearLastActiveStore();
      state = state.copyWith(
        status: StoreAccessStatus.forbidden,
        errorMessage: error.message,
      );
    } catch (error) {
      await _clearLastActiveStore();
      state = state.copyWith(
        status: StoreAccessStatus.error,
        errorMessage: _cleanError(error),
      );
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

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/workspace_context_providers.dart';
import 'last_active_store_state.dart';

class LastActiveStoreNotifier extends Notifier<LastActiveStoreState> {
  bool _bootstrapStarted = false;

  @override
  LastActiveStoreState build() {
    Future.microtask(load);
    return const LastActiveStoreState.bootstrapping();
  }

  Future<void> load() async {
    if (_bootstrapStarted && state.isBootstrapping) {
      return;
    }

    _bootstrapStarted = true;

    try {
      final storeId = await ref.read(loadLastActiveStoreUseCaseProvider)();
      state = LastActiveStoreState(
        status: LastActiveStoreStatus.ready,
        lastStoreId: storeId,
      );
    } catch (error) {
      state = LastActiveStoreState(
        status: LastActiveStoreStatus.error,
        errorMessage: _cleanError(error),
      );
    }
  }

  Future<void> save(int storeId) async {
    await ref.read(saveLastActiveStoreUseCaseProvider)(storeId);
    state = LastActiveStoreState(
      status: LastActiveStoreStatus.ready,
      lastStoreId: storeId,
    );
  }

  Future<void> clear() async {
    await ref.read(clearLastActiveStoreUseCaseProvider)();
    state = const LastActiveStoreState(status: LastActiveStoreStatus.ready);
  }

  String _cleanError(Object error) {
    return error.toString().replaceFirst('Exception: ', '');
  }
}

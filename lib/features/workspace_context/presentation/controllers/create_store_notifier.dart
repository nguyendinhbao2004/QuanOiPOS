import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/workspace_context_providers.dart';
import 'create_store_state.dart';

class CreateStoreNotifier extends AutoDisposeNotifier<CreateStoreState> {
  @override
  CreateStoreState build() {
    return const CreateStoreState.initial();
  }

  Future<void> submit({
    required String storeName,
    required String phone,
    required String address,
  }) async {
    if (state.isSubmitting) {
      return;
    }

    state = state.copyWith(
      status: CreateStoreStatus.submitting,
      clearError: true,
    );

    try {
      final useCase = ref.read(createStoreUseCaseProvider);
      final store = await useCase(
        storeName: storeName.trim(),
        phone: phone.trim(),
        address: address.trim(),
      );
      state = CreateStoreState(status: CreateStoreStatus.success, store: store);
    } catch (error) {
      state = CreateStoreState(
        status: CreateStoreStatus.failure,
        errorMessage: _cleanError(error),
      );
    }
  }

  void reset() {
    state = const CreateStoreState.initial();
  }

  String _cleanError(Object error) {
    return error.toString().replaceFirst('Exception: ', '');
  }
}

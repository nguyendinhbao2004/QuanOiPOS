import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/di/injection.dart';
import '../../../../core/storage/last_active_store_storage.dart';
import '../../data/datasources/workspace_remote_data_source.dart';
import '../../domain/repositories/workspace_repository.dart';
import '../../domain/usecases/clear_last_active_store_use_case.dart';
import '../../domain/usecases/create_store_use_case.dart';
import '../../domain/usecases/load_last_active_store_use_case.dart';
import '../../domain/usecases/load_my_stores_use_case.dart';
import '../../domain/usecases/load_store_access_context_use_case.dart';
import '../../domain/usecases/save_last_active_store_use_case.dart';
import '../controllers/create_store_notifier.dart';
import '../controllers/create_store_state.dart';
import '../controllers/last_active_store_notifier.dart';
import '../controllers/last_active_store_state.dart';
import '../controllers/my_stores_notifier.dart';
import '../controllers/my_stores_state.dart';
import '../controllers/store_access_notifier.dart';
import '../controllers/store_access_state.dart';

final workspaceRemoteDataSourceProvider = Provider<WorkspaceRemoteDataSource>((
  ref,
) {
  return locator<WorkspaceRemoteDataSource>();
});

final workspaceRepositoryProvider = Provider<WorkspaceRepository>((ref) {
  return locator<WorkspaceRepository>();
});

final lastActiveStoreStorageProvider = Provider<LastActiveStoreStorage>((ref) {
  return locator<LastActiveStoreStorage>();
});

final loadMyStoresUseCaseProvider = Provider<LoadMyStoresUseCase>((ref) {
  return locator<LoadMyStoresUseCase>();
});

final createStoreUseCaseProvider = Provider<CreateStoreUseCase>((ref) {
  return locator<CreateStoreUseCase>();
});

final loadStoreAccessContextUseCaseProvider =
    Provider<LoadStoreAccessContextUseCase>((ref) {
      return locator<LoadStoreAccessContextUseCase>();
    });

final loadLastActiveStoreUseCaseProvider = Provider<LoadLastActiveStoreUseCase>(
  (ref) {
    return locator<LoadLastActiveStoreUseCase>();
  },
);

final saveLastActiveStoreUseCaseProvider = Provider<SaveLastActiveStoreUseCase>(
  (ref) {
    return locator<SaveLastActiveStoreUseCase>();
  },
);

final clearLastActiveStoreUseCaseProvider =
    Provider<ClearLastActiveStoreUseCase>((ref) {
      return locator<ClearLastActiveStoreUseCase>();
    });

final myStoresNotifierProvider =
    NotifierProvider.autoDispose<MyStoresNotifier, MyStoresState>(
      MyStoresNotifier.new,
    );

final createStoreNotifierProvider =
    NotifierProvider.autoDispose<CreateStoreNotifier, CreateStoreState>(
      CreateStoreNotifier.new,
    );

final lastActiveStoreNotifierProvider =
    NotifierProvider<LastActiveStoreNotifier, LastActiveStoreState>(
      LastActiveStoreNotifier.new,
    );

final storeAccessNotifierProvider = NotifierProvider.autoDispose
    .family<StoreAccessNotifier, StoreAccessState, int>(
      StoreAccessNotifier.new,
    );

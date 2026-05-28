import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/di/injection.dart';
import '../../data/datasources/workspace_remote_data_source.dart';
import '../../domain/repositories/workspace_repository.dart';
import '../../domain/usecases/load_my_stores_use_case.dart';
import '../../domain/usecases/load_store_access_context_use_case.dart';
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

final loadMyStoresUseCaseProvider = Provider<LoadMyStoresUseCase>((ref) {
  return locator<LoadMyStoresUseCase>();
});

final loadStoreAccessContextUseCaseProvider =
    Provider<LoadStoreAccessContextUseCase>((ref) {
      return locator<LoadStoreAccessContextUseCase>();
    });

final myStoresNotifierProvider =
    NotifierProvider.autoDispose<MyStoresNotifier, MyStoresState>(
      MyStoresNotifier.new,
    );

final storeAccessNotifierProvider = NotifierProvider.autoDispose
    .family<StoreAccessNotifier, StoreAccessState, int>(
      StoreAccessNotifier.new,
    );

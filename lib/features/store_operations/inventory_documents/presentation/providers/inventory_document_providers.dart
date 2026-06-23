import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../../core/di/injection.dart';
import '../../data/datasources/inventory_document_remote_data_source.dart';
import '../../domain/repositories/inventory_document_repository.dart';
import '../../domain/usecases/inventory_document_use_cases.dart';
import '../controllers/inventory_document_notifiers.dart';
import '../controllers/inventory_document_state.dart';

final inventoryDocumentRemoteDataSourceProvider =
    Provider<InventoryDocumentRemoteDataSource>(
      (ref) => locator<InventoryDocumentRemoteDataSource>(),
    );
final inventoryDocumentRepositoryProvider =
    Provider<InventoryDocumentRepository>(
      (ref) => locator<InventoryDocumentRepository>(),
    );
final loadInventoryImportsUseCaseProvider =
    Provider<LoadInventoryImportsUseCase>(
      (ref) => locator<LoadInventoryImportsUseCase>(),
    );
final loadInventoryDocumentsUseCaseProvider =
    Provider<LoadInventoryDocumentsUseCase>(
      (ref) => locator<LoadInventoryDocumentsUseCase>(),
    );
final loadInventoryDocumentUseCaseProvider =
    Provider<LoadInventoryDocumentUseCase>(
      (ref) => locator<LoadInventoryDocumentUseCase>(),
    );
final loadInventoryVendorsUseCaseProvider =
    Provider<LoadInventoryVendorsUseCase>(
      (ref) => locator<LoadInventoryVendorsUseCase>(),
    );
final createInventoryVendorUseCaseProvider =
    Provider<CreateInventoryVendorUseCase>(
      (ref) => locator<CreateInventoryVendorUseCase>(),
    );
final loadInventorySelectableItemsUseCaseProvider =
    Provider<LoadInventorySelectableItemsUseCase>(
      (ref) => locator<LoadInventorySelectableItemsUseCase>(),
    );
final createInventoryImportUseCaseProvider =
    Provider<CreateInventoryImportUseCase>(
      (ref) => locator<CreateInventoryImportUseCase>(),
    );
final updateInventoryImportUseCaseProvider =
    Provider<UpdateInventoryImportUseCase>(
      (ref) => locator<UpdateInventoryImportUseCase>(),
    );
final completeInventoryImportUseCaseProvider =
    Provider<CompleteInventoryImportUseCase>(
      (ref) => locator<CompleteInventoryImportUseCase>(),
    );
final createInventoryDocumentUseCaseProvider =
    Provider<CreateInventoryDocumentUseCase>(
      (ref) => locator<CreateInventoryDocumentUseCase>(),
    );
final updateInventoryDocumentUseCaseProvider =
    Provider<UpdateInventoryDocumentUseCase>(
      (ref) => locator<UpdateInventoryDocumentUseCase>(),
    );
final completeInventoryDocumentUseCaseProvider =
    Provider<CompleteInventoryDocumentUseCase>(
      (ref) => locator<CompleteInventoryDocumentUseCase>(),
    );
final cancelInventoryDocumentUseCaseProvider =
    Provider<CancelInventoryDocumentUseCase>(
      (ref) => locator<CancelInventoryDocumentUseCase>(),
    );
final inventoryDocumentListNotifierProvider = NotifierProvider.autoDispose
    .family<
      InventoryDocumentListNotifier,
      InventoryDocumentListState,
      InventoryDocumentListArgs
    >(InventoryDocumentListNotifier.new);
final inventoryDocumentEditorNotifierProvider = NotifierProvider.autoDispose
    .family<
      InventoryDocumentEditorNotifier,
      InventoryDocumentEditorState,
      InventoryDocumentEditorArgs
    >(InventoryDocumentEditorNotifier.new);

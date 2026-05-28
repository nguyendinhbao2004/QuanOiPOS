import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/theme/index.dart';
import '../../../workspace_context/domain/entities/store.dart';
import '../../../workspace_context/presentation/controllers/my_stores_state.dart';
import '../../../workspace_context/presentation/providers/workspace_context_providers.dart';
import 'store_bottom_sheet_panel.dart';
import 'store_switch_list_tile.dart';

class StoreSwitcherBottomSheet extends ConsumerWidget {
  final int activeStoreId;

  const StoreSwitcherBottomSheet({super.key, required this.activeStoreId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(myStoresNotifierProvider);

    return StoreBottomSheetPanel(
      title: 'Chuyển cửa hàng',
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppConstants.spacingLg,
            ),
            child: Column(
              children: [
                TextField(
                  key: const Key('store_switcher_search_field'),
                  onChanged: (query) => ref
                      .read(myStoresNotifierProvider.notifier)
                      .updateSearchQuery(query),
                  textInputAction: TextInputAction.search,
                  decoration: const InputDecoration(
                    hintText: 'Tìm kiếm tên cửa hàng...',
                    prefixIcon: Icon(Icons.search_rounded),
                  ),
                ),
                const SizedBox(height: AppConstants.spacingMd),
                OutlinedButton.icon(
                  key: const Key('store_switcher_add_store_button'),
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text(
                          'Thêm cửa hàng mới sẽ được triển khai sau',
                        ),
                      ),
                    );
                  },
                  icon: const Icon(Icons.add_circle_outline_rounded),
                  label: const Text('Thêm cửa hàng mới'),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppConstants.spacingMd),
          Expanded(
            child: switch (state.status) {
              MyStoresStatus.initial || MyStoresStatus.loading
                  when state.stores.isEmpty =>
                const _LoadingStoreList(),
              MyStoresStatus.error when state.stores.isEmpty => _ErrorStoreList(
                message:
                    state.errorMessage ?? 'Không thể tải danh sách cửa hàng',
                onRetry: () =>
                    ref.read(myStoresNotifierProvider.notifier).loadStores(),
              ),
              _ => _StoreList(
                stores: state.filteredStores,
                hasStores: state.stores.isNotEmpty,
                activeStoreId: activeStoreId,
              ),
            },
          ),
        ],
      ),
    );
  }
}

class _StoreList extends StatelessWidget {
  final List<Store> stores;
  final bool hasStores;
  final int activeStoreId;

  const _StoreList({
    required this.stores,
    required this.hasStores,
    required this.activeStoreId,
  });

  @override
  Widget build(BuildContext context) {
    if (!hasStores) {
      return const _EmptyStoreList(
        icon: Icons.storefront_outlined,
        title: 'Chưa có cửa hàng',
        message: 'Tài khoản của bạn chưa được liên kết với cửa hàng nào.',
      );
    }

    if (stores.isEmpty) {
      return const _EmptyStoreList(
        icon: Icons.search_off_rounded,
        title: 'Không tìm thấy cửa hàng',
        message: 'Thử tìm theo tên, số điện thoại hoặc địa chỉ khác.',
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(
        AppConstants.spacingLg,
        0,
        AppConstants.spacingLg,
        AppConstants.spacingXl,
      ),
      itemBuilder: (context, index) {
        final store = stores[index];
        final isActiveStore = store.id == activeStoreId;
        final canSelect = store.status.canAccess && !isActiveStore;

        return StoreSwitchListTile(
          store: store,
          isActiveStore: isActiveStore,
          onTap: isActiveStore || canSelect
              ? () => Navigator.of(context).pop(store.id)
              : null,
        );
      },
      separatorBuilder: (context, index) =>
          const SizedBox(height: AppConstants.spacingMd),
      itemCount: stores.length,
    );
  }
}

class _LoadingStoreList extends StatelessWidget {
  const _LoadingStoreList();

  @override
  Widget build(BuildContext context) {
    return const Center(child: CircularProgressIndicator());
  }
}

class _ErrorStoreList extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _ErrorStoreList({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppConstants.spacingLg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.error_outline_rounded,
              color: AppColors.error,
              size: 40,
            ),
            const SizedBox(height: AppConstants.spacingSm),
            Text(
              message,
              style: AppTextStyles.bodySm,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppConstants.spacingMd),
            SizedBox(
              width: 180,
              child: ElevatedButton(
                onPressed: onRetry,
                child: const Text('Thử lại'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyStoreList extends StatelessWidget {
  final IconData icon;
  final String title;
  final String message;

  const _EmptyStoreList({
    required this.icon,
    required this.title,
    required this.message,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppConstants.spacingLg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: AppColors.textMuted, size: 40),
            const SizedBox(height: AppConstants.spacingMd),
            Text(
              title,
              style: AppTextStyles.h4.copyWith(fontWeight: FontWeight.w700),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppConstants.spacingXs),
            Text(
              message,
              style: AppTextStyles.bodySm,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

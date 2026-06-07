import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../config/router_config.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/theme/index.dart';
import '../../../workspace_context/presentation/controllers/store_access_state.dart';
import '../../../workspace_context/presentation/providers/workspace_context_providers.dart';
import '../providers/store_inventory_check_create_mock_provider.dart';
import 'store_inventory_check_draft_page.dart';

class StoreInventoryCheckCreatePage extends ConsumerWidget {
  final int storeId;

  const StoreInventoryCheckCreatePage({super.key, required this.storeId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final accessState = ref.watch(storeAccessNotifierProvider(storeId));

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        bottom: false,
        child: switch (accessState.status) {
          StoreAccessStatus.initial ||
          StoreAccessStatus.loading => const _LoadingView(),
          StoreAccessStatus.forbidden => _BlockedView(
            icon: Icons.lock_outline_rounded,
            title: 'Không có quyền truy cập',
            message:
                accessState.errorMessage ??
                'Tài khoản của bạn không có quyền truy cập cửa hàng này.',
            actionLabel: 'Về danh sách cửa hàng',
            onAction: () => context.goNamed(RouteNames.myStores),
          ),
          StoreAccessStatus.error => _BlockedView(
            icon: Icons.error_outline_rounded,
            title: 'Không thể tải thông tin cửa hàng',
            message: accessState.errorMessage ?? 'Vui lòng thử lại sau.',
            actionLabel: 'Thử lại',
            onAction: () => ref
                .read(storeAccessNotifierProvider(storeId).notifier)
                .loadAccess(),
          ),
          StoreAccessStatus.ready => _ReadyView(storeId: storeId),
        },
      ),
    );
  }
}

class _ReadyView extends ConsumerStatefulWidget {
  final int storeId;

  const _ReadyView({required this.storeId});

  @override
  ConsumerState<_ReadyView> createState() => _ReadyViewState();
}

class _ReadyViewState extends ConsumerState<_ReadyView> {
  _InventoryCheckCreateTab _selectedTab = _InventoryCheckCreateTab.products;

  void _selectTab(_InventoryCheckCreateTab tab) {
    setState(() {
      _selectedTab = tab;
    });
  }

  @override
  Widget build(BuildContext context) {
    // TODO: Gate this page with AppPermissionCodes.inventoryView or a more
    // specific inventory check permission when backend PBAC is available.
    final mockData = ref.watch(storeInventoryCheckCreateMockProvider);
    final isProductTab = _selectedTab == _InventoryCheckCreateTab.products;
    final items = isProductTab ? mockData.products : mockData.ingredients;

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 560),
        child: Column(
          children: [
            _InventoryCheckCreateHeader(storeId: widget.storeId),
            _InventoryCheckCreateTabs(
              selectedTab: _selectedTab,
              onTabSelected: _selectTab,
            ),
            Expanded(
              child: items.isEmpty
                  ? _EmptyCreateListView(isProductTab: isProductTab)
                  : ListView.separated(
                      padding: const EdgeInsets.all(AppConstants.spacingSm),
                      itemBuilder: (context, index) {
                        return _InventoryCheckCreateTile(
                          storeId: widget.storeId,
                          item: items[index],
                          isProduct: isProductTab,
                        );
                      },
                      separatorBuilder: (context, index) =>
                          const SizedBox(height: AppConstants.spacingXs),
                      itemCount: items.length,
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

enum _InventoryCheckCreateTab { products, ingredients }

class _InventoryCheckCreateHeader extends StatelessWidget {
  final int storeId;

  const _InventoryCheckCreateHeader({required this.storeId});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.surface,
      padding: const EdgeInsets.fromLTRB(
        AppConstants.spacingXs,
        AppConstants.spacingXs,
        AppConstants.spacingXs,
        AppConstants.spacingSm,
      ),
      child: Row(
        children: [
          IconButton(
            tooltip: 'Quay lại',
            icon: const Icon(Icons.arrow_back_rounded),
            onPressed: () => context.goNamed(
              RouteNames.storeInventoryCheck,
              pathParameters: {'storeId': storeId.toString()},
            ),
          ),
          Expanded(
            child: Material(
              color: AppColors.inputBackground,
              borderRadius: BorderRadius.circular(AppTheme.radiusMd),
              child: InkWell(
                key: const Key('inventory_check_create_search_action'),
                onTap: () => _showComingSoon(context, 'Tìm kiếm kiểm kho'),
                borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                child: Container(
                  height: 40,
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppConstants.spacingSm,
                  ),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.search_rounded,
                        color: AppColors.textMuted,
                        size: 20,
                      ),
                      const SizedBox(width: AppConstants.spacingXs),
                      Expanded(
                        child: Text(
                          'Tìm/Chọn sản phẩm, SKU...',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTextStyles.bodySm.copyWith(
                            color: AppColors.textMuted,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          IconButton(
            key: const Key('inventory_check_create_scan_action'),
            tooltip: 'Quét mã',
            icon: const Icon(Icons.qr_code_scanner_rounded),
            color: AppColors.textPrimary,
            onPressed: () => _showComingSoon(context, 'Quét mã kiểm kho'),
          ),
        ],
      ),
    );
  }
}

class _InventoryCheckCreateTabs extends StatelessWidget {
  final _InventoryCheckCreateTab selectedTab;
  final ValueChanged<_InventoryCheckCreateTab> onTabSelected;

  const _InventoryCheckCreateTabs({
    required this.selectedTab,
    required this.onTabSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.surface,
      padding: const EdgeInsets.fromLTRB(
        AppConstants.spacingSm,
        0,
        AppConstants.spacingSm,
        AppConstants.spacingSm,
      ),
      child: Container(
        height: 40,
        padding: const EdgeInsets.all(3),
        decoration: BoxDecoration(
          color: AppColors.inputBackground,
          borderRadius: BorderRadius.circular(AppTheme.radiusMd),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          children: [
            _InventoryCheckCreateTabButton(
              key: const Key('inventory_check_create_products_tab'),
              label: 'Sản phẩm',
              isSelected: selectedTab == _InventoryCheckCreateTab.products,
              onTap: () => onTabSelected(_InventoryCheckCreateTab.products),
            ),
            _InventoryCheckCreateTabButton(
              key: const Key('inventory_check_create_ingredients_tab'),
              label: 'Nguyên vật liệu',
              isSelected: selectedTab == _InventoryCheckCreateTab.ingredients,
              onTap: () => onTabSelected(_InventoryCheckCreateTab.ingredients),
            ),
          ],
        ),
      ),
    );
  }
}

class _InventoryCheckCreateTabButton extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _InventoryCheckCreateTabButton({
    super.key,
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Material(
        color: isSelected ? AppColors.surface : Colors.transparent,
        borderRadius: BorderRadius.circular(AppTheme.radiusSm),
        child: InkWell(
          onTap: isSelected ? null : onTap,
          borderRadius: BorderRadius.circular(AppTheme.radiusSm),
          child: Center(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTextStyles.labelXs.copyWith(
                color: isSelected ? AppColors.primary : AppColors.textSecondary,
                fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _InventoryCheckCreateTile extends StatelessWidget {
  final int storeId;
  final StoreInventoryCheckCreateItem item;
  final bool isProduct;

  const _InventoryCheckCreateTile({
    required this.storeId,
    required this.item,
    required this.isProduct,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(AppTheme.radiusMd),
      child: InkWell(
        onTap: () => context.goNamed(
          RouteNames.storeInventoryCheckDraft,
          pathParameters: {'storeId': storeId.toString()},
          extra: StoreInventoryCheckDraftSeedData(
            name: item.name,
            code: item.code,
            stockText: item.stockText,
            isProduct: isProduct,
          ),
        ),
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        child: Container(
          padding: const EdgeInsets.all(AppConstants.spacingSm),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppTheme.radiusMd),
            border: Border.all(color: AppColors.border),
            boxShadow: [
              BoxShadow(
                color: AppColors.textPrimary.withValues(alpha: 0.03),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: [
              _InventoryCheckCreateThumb(isProduct: isProduct),
              const SizedBox(width: AppConstants.spacingSm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.labelSm.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: AppConstants.spacingXs),
                    Text(
                      item.code,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.bodyXs.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppConstants.spacingSm),
              Text(
                'Kho: ${item.stockText}',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTextStyles.labelXs.copyWith(
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _InventoryCheckCreateThumb extends StatelessWidget {
  final bool isProduct;

  const _InventoryCheckCreateThumb({required this.isProduct});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        color: AppColors.inputBackground,
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        border: Border.all(color: AppColors.borderStrong),
      ),
      child: Icon(
        isProduct ? Icons.inventory_2_outlined : Icons.kitchen_outlined,
        color: AppColors.textMuted,
        size: 22,
      ),
    );
  }
}

class _EmptyCreateListView extends StatelessWidget {
  final bool isProductTab;

  const _EmptyCreateListView({required this.isProductTab});

  @override
  Widget build(BuildContext context) {
    final label = isProductTab ? 'sản phẩm' : 'nguyên vật liệu';

    return Container(
      color: AppColors.surface,
      padding: const EdgeInsets.all(AppConstants.spacingLg),
      child: Center(
        child: Text(
          'Chưa có $label kiểm kho',
          style: AppTextStyles.bodySm.copyWith(color: AppColors.textMuted),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}

class _BlockedView extends StatelessWidget {
  final IconData icon;
  final String title;
  final String message;
  final String actionLabel;
  final VoidCallback onAction;

  const _BlockedView({
    required this.icon,
    required this.title,
    required this.message,
    required this.actionLabel,
    required this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.background,
      padding: const EdgeInsets.all(AppConstants.spacingLg),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: AppColors.textMuted, size: 44),
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
            const SizedBox(height: AppConstants.spacingLg),
            SizedBox(
              width: 220,
              child: ElevatedButton(
                onPressed: onAction,
                child: Text(actionLabel),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LoadingView extends StatelessWidget {
  const _LoadingView();

  @override
  Widget build(BuildContext context) {
    return const ColoredBox(
      color: AppColors.background,
      child: Center(child: CircularProgressIndicator()),
    );
  }
}

void _showComingSoon(BuildContext context, String feature) {
  ScaffoldMessenger.of(
    context,
  ).showSnackBar(SnackBar(content: Text('$feature sẽ được triển khai sau')));
}

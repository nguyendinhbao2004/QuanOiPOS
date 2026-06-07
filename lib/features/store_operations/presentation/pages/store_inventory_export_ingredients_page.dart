import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../config/router_config.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/theme/index.dart';
import '../../../workspace_context/presentation/controllers/store_access_state.dart';
import '../../../workspace_context/presentation/providers/workspace_context_providers.dart';
import '../providers/store_inventory_export_ingredients_mock_provider.dart';
import 'store_inventory_export_ingredient_draft_page.dart';

class StoreInventoryExportIngredientsPage extends ConsumerWidget {
  final int storeId;
  final StoreInventoryExportIngredientDraftSeedData? seedData;

  const StoreInventoryExportIngredientsPage({
    super.key,
    required this.storeId,
    this.seedData,
  });

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
          StoreAccessStatus.ready => _ReadyView(
            storeId: storeId,
            seedData: seedData,
          ),
        },
      ),
    );
  }
}

class _ReadyView extends ConsumerStatefulWidget {
  final int storeId;
  final StoreInventoryExportIngredientDraftSeedData? seedData;

  const _ReadyView({required this.storeId, this.seedData});

  @override
  ConsumerState<_ReadyView> createState() => _ReadyViewState();
}

class _ReadyViewState extends ConsumerState<_ReadyView> {
  final Map<String, int> _quantitiesByCode = {};

  @override
  void initState() {
    super.initState();
    final seedData = widget.seedData;
    if (seedData != null) {
      _quantitiesByCode.addAll(seedData.quantitiesByCode);
    }
  }

  int get _totalSelectedQuantity {
    return _quantitiesByCode.values.fold(
      0,
      (total, quantity) => total + quantity,
    );
  }

  void _addIngredient(StoreInventoryExportIngredientMockItem ingredient) {
    setState(() {
      _quantitiesByCode[ingredient.code] = 1;
    });
  }

  void _incrementIngredient(StoreInventoryExportIngredientMockItem ingredient) {
    setState(() {
      _quantitiesByCode[ingredient.code] =
          (_quantitiesByCode[ingredient.code] ?? 0) + 1;
    });
  }

  void _decrementIngredient(StoreInventoryExportIngredientMockItem ingredient) {
    setState(() {
      final currentQuantity = _quantitiesByCode[ingredient.code] ?? 0;
      if (currentQuantity <= 1) {
        _quantitiesByCode.remove(ingredient.code);
        return;
      }

      _quantitiesByCode[ingredient.code] = currentQuantity - 1;
    });
  }

  void _showDraft() {
    context.goNamed(
      RouteNames.storeInventoryExportIngredientDraft,
      pathParameters: {'storeId': widget.storeId.toString()},
      extra: StoreInventoryExportIngredientDraftSeedData(
        quantitiesByCode: Map.unmodifiable(_quantitiesByCode),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // TODO: Gate this page with AppPermissionCodes.inventoryView or a more
    // specific export ingredient permission when backend PBAC is available.
    final ingredients = ref.watch(storeInventoryExportIngredientsMockProvider);
    final totalSelectedQuantity = _totalSelectedQuantity;
    final hasSelection = totalSelectedQuantity > 0;

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 560),
        child: SizedBox.expand(
          child: Stack(
            children: [
              Column(
                children: [
                  _InventoryExportIngredientsHeader(storeId: widget.storeId),
                  const _InventoryExportIngredientFilters(),
                  Expanded(
                    child: ingredients.isEmpty
                        ? const _EmptyIngredientView()
                        : ListView.separated(
                            padding: EdgeInsets.only(
                              bottom: hasSelection
                                  ? AppConstants.spacingXxl * 2
                                  : AppConstants.spacingXxl,
                            ),
                            itemBuilder: (context, index) {
                              final ingredient = ingredients[index];
                              return _InventoryExportIngredientTile(
                                ingredient: ingredient,
                                quantity:
                                    _quantitiesByCode[ingredient.code] ?? 0,
                                onAdd: () => _addIngredient(ingredient),
                                onIncrement: () =>
                                    _incrementIngredient(ingredient),
                                onDecrement: () =>
                                    _decrementIngredient(ingredient),
                              );
                            },
                            separatorBuilder: (context, index) => const Divider(
                              indent: AppConstants.spacingMd,
                              endIndent: AppConstants.spacingMd,
                            ),
                            itemCount: ingredients.length,
                          ),
                  ),
                ],
              ),
              if (hasSelection)
                _ExportIngredientsBottomActionBar(
                  selectedQuantity: totalSelectedQuantity,
                  onContinue: _showDraft,
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _InventoryExportIngredientsHeader extends StatelessWidget {
  final int storeId;

  const _InventoryExportIngredientsHeader({required this.storeId});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.surface,
      padding: const EdgeInsets.fromLTRB(
        AppConstants.spacingXs,
        AppConstants.spacingSm,
        AppConstants.spacingXs,
        AppConstants.spacingXs,
      ),
      child: Row(
        children: [
          IconButton(
            tooltip: 'Quay lại',
            icon: const Icon(Icons.arrow_back_rounded),
            onPressed: () => context.goNamed(
              RouteNames.storeInventoryExport,
              pathParameters: {'storeId': storeId.toString()},
            ),
          ),
          Expanded(
            child: Text(
              'Xuất nguyên liệu',
              style: AppTextStyles.h4.copyWith(fontWeight: FontWeight.w700),
            ),
          ),
          IconButton(
            tooltip: 'Tìm kiếm',
            icon: const Icon(Icons.search_rounded),
            color: AppColors.textPrimary,
            onPressed: () => _showComingSoon(context, 'Tìm kiếm nguyên liệu'),
          ),
          IconButton(
            tooltip: 'Quét mã',
            icon: const Icon(Icons.qr_code_scanner_rounded),
            color: AppColors.textPrimary,
            onPressed: () => _showComingSoon(context, 'Quét mã nguyên liệu'),
          ),
        ],
      ),
    );
  }
}

class _InventoryExportIngredientFilters extends StatelessWidget {
  const _InventoryExportIngredientFilters();

  @override
  Widget build(BuildContext context) {
    return Container(
      alignment: Alignment.centerLeft,
      color: AppColors.surface,
      padding: const EdgeInsets.fromLTRB(
        AppConstants.spacingMd,
        AppConstants.spacingSm,
        AppConstants.spacingMd,
        AppConstants.spacingMd,
      ),
      child: Wrap(
        spacing: AppConstants.spacingSm,
        runSpacing: AppConstants.spacingSm,
        children: const [
          _ExportIngredientFilterChip(label: 'Nguyên liệu'),
          _ExportIngredientFilterChip(label: 'Nhóm nguyên liệu'),
        ],
      ),
    );
  }
}

class _ExportIngredientFilterChip extends StatelessWidget {
  final String label;

  const _ExportIngredientFilterChip({required this.label});

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: () => _showComingSoon(context, label),
      iconAlignment: IconAlignment.end,
      label: Text(label, maxLines: 1, overflow: TextOverflow.ellipsis),
      icon: const Icon(Icons.keyboard_arrow_down_rounded, size: 18),
      style: OutlinedButton.styleFrom(
        minimumSize: const Size(0, 36),
        padding: const EdgeInsets.symmetric(
          horizontal: AppConstants.spacingMd,
          vertical: AppConstants.spacingSm,
        ),
        foregroundColor: AppColors.textPrimary,
        backgroundColor: AppColors.surface,
        side: const BorderSide(color: AppColors.borderStrong),
        textStyle: AppTextStyles.labelXs,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppTheme.radiusXl),
        ),
      ),
    );
  }
}

class _InventoryExportIngredientTile extends StatelessWidget {
  final StoreInventoryExportIngredientMockItem ingredient;
  final int quantity;
  final VoidCallback onAdd;
  final VoidCallback onIncrement;
  final VoidCallback onDecrement;

  const _InventoryExportIngredientTile({
    required this.ingredient,
    required this.quantity,
    required this.onAdd,
    required this.onIncrement,
    required this.onDecrement,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surface,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          AppConstants.spacingMd,
          AppConstants.spacingSm,
          AppConstants.spacingMd,
          AppConstants.spacingSm,
        ),
        child: Row(
          children: [
            const _IngredientThumb(),
            const SizedBox(width: AppConstants.spacingSm),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    ingredient.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.labelSm.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: AppConstants.spacingXs),
                  Text(
                    '${ingredient.code}  |  Còn: ${ingredient.stockQuantity} ${ingredient.unit}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.bodyXs.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: AppConstants.spacingMd),
            quantity > 0
                ? _IngredientQuantityStepper(
                    code: ingredient.code,
                    quantity: quantity,
                    onIncrement: onIncrement,
                    onDecrement: onDecrement,
                  )
                : _AddIngredientButton(code: ingredient.code, onPressed: onAdd),
          ],
        ),
      ),
    );
  }
}

class _IngredientQuantityStepper extends StatelessWidget {
  final String code;
  final int quantity;
  final VoidCallback onIncrement;
  final VoidCallback onDecrement;

  const _IngredientQuantityStepper({
    required this.code,
    required this.quantity,
    required this.onIncrement,
    required this.onDecrement,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      key: Key('inventory_export_ingredient_stepper_$code'),
      height: 36,
      constraints: const BoxConstraints(minWidth: 104),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        border: Border.all(color: AppColors.borderStrong),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _QuantityIconButton(
            key: Key('inventory_export_ingredient_decrement_$code'),
            icon: Icons.remove_rounded,
            onPressed: onDecrement,
          ),
          SizedBox(
            width: 32,
            child: Text(
              quantity.toString(),
              key: Key('inventory_export_ingredient_quantity_$code'),
              textAlign: TextAlign.center,
              style: AppTextStyles.labelSm.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          _QuantityIconButton(
            key: Key('inventory_export_ingredient_increment_$code'),
            icon: Icons.add_rounded,
            onPressed: onIncrement,
            color: AppColors.primary,
          ),
        ],
      ),
    );
  }
}

class _QuantityIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onPressed;
  final Color color;

  const _QuantityIconButton({
    super.key,
    required this.icon,
    required this.onPressed,
    this.color = AppColors.textSecondary,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 34,
      height: 36,
      child: IconButton(
        onPressed: onPressed,
        icon: Icon(icon, size: 18),
        color: color,
        padding: EdgeInsets.zero,
      ),
    );
  }
}

class _IngredientThumb extends StatelessWidget {
  const _IngredientThumb();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: AppColors.inputBackground,
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        border: Border.all(color: AppColors.borderStrong),
      ),
      child: const Icon(
        Icons.kitchen_outlined,
        color: AppColors.textMuted,
        size: 22,
      ),
    );
  }
}

class _AddIngredientButton extends StatelessWidget {
  final String code;
  final VoidCallback onPressed;

  const _AddIngredientButton({required this.code, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 36,
      height: 36,
      child: ElevatedButton(
        key: Key('inventory_export_ingredient_add_$code'),
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: AppColors.surface,
          padding: EdgeInsets.zero,
          minimumSize: const Size.square(36),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppTheme.radiusMd),
          ),
        ),
        child: const Icon(Icons.add_rounded, size: 20),
      ),
    );
  }
}

class _ExportIngredientsBottomActionBar extends StatelessWidget {
  final int selectedQuantity;
  final VoidCallback onContinue;

  const _ExportIngredientsBottomActionBar({
    required this.selectedQuantity,
    required this.onContinue,
  });

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: AppConstants.spacingMd,
      right: AppConstants.spacingMd,
      bottom: MediaQuery.paddingOf(context).bottom + AppConstants.spacingMd,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          key: const Key('inventory_export_ingredients_continue_action'),
          onTap: onContinue,
          borderRadius: BorderRadius.circular(AppTheme.radiusMd),
          child: Container(
            constraints: const BoxConstraints(minHeight: 56),
            padding: const EdgeInsets.symmetric(
              horizontal: AppConstants.spacingMd,
              vertical: AppConstants.spacingSm,
            ),
            decoration: BoxDecoration(
              color: AppColors.primary,
              borderRadius: BorderRadius.circular(AppTheme.radiusMd),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primaryDark.withValues(alpha: 0.24),
                  blurRadius: 18,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Row(
              children: [
                Stack(
                  clipBehavior: Clip.none,
                  children: [
                    const Icon(
                      Icons.shopping_bag_outlined,
                      color: AppColors.surface,
                      size: 24,
                    ),
                    Positioned(
                      right: -7,
                      top: -7,
                      child: Container(
                        constraints: const BoxConstraints(minWidth: 16),
                        height: 16,
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: AppColors.error,
                          borderRadius: BorderRadius.circular(
                            AppTheme.radiusXl,
                          ),
                          border: Border.all(
                            color: AppColors.surface,
                            width: 1.5,
                          ),
                        ),
                        child: Text(
                          selectedQuantity.toString(),
                          style: AppTextStyles.caption.copyWith(
                            color: AppColors.surface,
                            fontWeight: FontWeight.w700,
                            height: 1,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(width: AppConstants.spacingMd),
                Expanded(
                  child: Text(
                    '$selectedQuantity NL',
                    style: AppTextStyles.labelSm.copyWith(
                      color: AppColors.surface,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                Text(
                  'Tiếp tục',
                  style: AppTextStyles.labelSm.copyWith(
                    color: AppColors.surface,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(width: AppConstants.spacingXs),
                const Icon(
                  Icons.chevron_right_rounded,
                  color: AppColors.surface,
                  size: 20,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _EmptyIngredientView extends StatelessWidget {
  const _EmptyIngredientView();

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.surface,
      padding: const EdgeInsets.all(AppConstants.spacingLg),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.kitchen_outlined,
              color: AppColors.textMuted,
              size: 44,
            ),
            const SizedBox(height: AppConstants.spacingMd),
            Text(
              'Chưa có nguyên liệu',
              style: AppTextStyles.h4.copyWith(fontWeight: FontWeight.w700),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppConstants.spacingXs),
            const Text(
              'Danh sách nguyên liệu xuất hàng sẽ hiển thị tại đây.',
              style: AppTextStyles.bodySm,
              textAlign: TextAlign.center,
            ),
          ],
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

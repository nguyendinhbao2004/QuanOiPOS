import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../config/router_config.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/theme/index.dart';
import '../../../workspace_context/presentation/controllers/store_access_state.dart';
import '../../../workspace_context/presentation/providers/workspace_context_providers.dart';

class StoreInventoryCheckDraftSeedData {
  final String name;
  final String code;
  final String stockText;
  final bool isProduct;

  const StoreInventoryCheckDraftSeedData({
    required this.name,
    required this.code,
    required this.stockText,
    required this.isProduct,
  });
}

class StoreInventoryCheckDraftPage extends ConsumerWidget {
  final int storeId;
  final StoreInventoryCheckDraftSeedData? seedData;

  const StoreInventoryCheckDraftPage({
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
          StoreAccessStatus.ready =>
            seedData == null
                ? _MissingDraftSeedView(storeId: storeId)
                : _ReadyView(storeId: storeId, seedData: seedData!),
        },
      ),
    );
  }
}

class _MissingDraftSeedView extends StatelessWidget {
  final int storeId;

  const _MissingDraftSeedView({required this.storeId});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.background,
      padding: const EdgeInsets.all(AppConstants.spacingLg),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 360),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: AppColors.primaryLight,
                  borderRadius: BorderRadius.circular(AppTheme.radiusLg),
                ),
                child: const Icon(
                  Icons.inventory_2_outlined,
                  color: AppColors.primary,
                  size: 32,
                ),
              ),
              const SizedBox(height: AppConstants.spacingMd),
              Text(
                'Chưa chọn hàng kiểm kho',
                style: AppTextStyles.h4.copyWith(fontWeight: FontWeight.w700),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppConstants.spacingXs),
              Text(
                'Vui lòng chọn sản phẩm hoặc nguyên vật liệu trước khi tạo phiếu kiểm kho.',
                style: AppTextStyles.bodySm.copyWith(
                  color: AppColors.textSecondary,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppConstants.spacingLg),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  key: const Key('inventory_check_draft_choose_item_action'),
                  onPressed: () => context.goNamed(
                    RouteNames.storeInventoryCheckCreate,
                    pathParameters: {'storeId': storeId.toString()},
                  ),
                  icon: const Icon(Icons.add_rounded),
                  label: const Text('Chọn hàng kiểm kho'),
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size(0, 48),
                    backgroundColor: AppColors.primary,
                    foregroundColor: AppColors.surface,
                    textStyle: AppTextStyles.buttonSm,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ReadyView extends StatefulWidget {
  final int storeId;
  final StoreInventoryCheckDraftSeedData seedData;

  const _ReadyView({required this.storeId, required this.seedData});

  @override
  State<_ReadyView> createState() => _ReadyViewState();
}

class _ReadyViewState extends State<_ReadyView> {
  int _actualQuantity = 0;

  int get _systemQuantity => _parseMockQuantity(widget.seedData.stockText);
  int get _differenceQuantity => _systemQuantity - _actualQuantity;

  void _incrementQuantity() {
    setState(() {
      _actualQuantity += 1;
    });
  }

  void _decrementQuantity() {
    setState(() {
      if (_actualQuantity > 0) {
        _actualQuantity -= 1;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    // TODO: Replace mock draft state with API-backed inventory check draft data.
    final seedData = widget.seedData;

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 560),
        child: Column(
          children: [
            _InventoryCheckDraftHeader(storeId: widget.storeId),
            const _InventoryCheckDraftSearchBar(),
            const _InventoryCheckDraftFilters(),
            Expanded(
              child: ListView(
                padding: EdgeInsets.zero,
                children: [
                  _InventoryCheckDraftItemCard(
                    seedData: seedData,
                    actualQuantity: _actualQuantity,
                    systemQuantity: _systemQuantity,
                    differenceQuantity: _differenceQuantity,
                    onIncrement: _incrementQuantity,
                    onDecrement: _decrementQuantity,
                  ),
                  _InventoryCheckDraftSummary(
                    actualQuantity: _actualQuantity,
                    systemQuantity: _systemQuantity,
                    differenceQuantity: _differenceQuantity,
                  ),
                  const _InventoryCheckDraftNoteRow(),
                ],
              ),
            ),
            const _InventoryCheckDraftBottomActions(),
          ],
        ),
      ),
    );
  }
}

class _InventoryCheckDraftHeader extends StatelessWidget {
  final int storeId;

  const _InventoryCheckDraftHeader({required this.storeId});

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
              RouteNames.storeInventoryCheckCreate,
              pathParameters: {'storeId': storeId.toString()},
            ),
          ),
          Expanded(
            child: Text(
              'Tạo phiếu kiểm kho',
              textAlign: TextAlign.center,
              style: AppTextStyles.h4.copyWith(fontWeight: FontWeight.w700),
            ),
          ),
          const SizedBox(width: 48),
        ],
      ),
    );
  }
}

class _InventoryCheckDraftSearchBar extends StatelessWidget {
  const _InventoryCheckDraftSearchBar();

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.surface,
      padding: const EdgeInsets.fromLTRB(
        AppConstants.spacingSm,
        AppConstants.spacingXs,
        AppConstants.spacingSm,
        AppConstants.spacingSm,
      ),
      child: Material(
        color: AppColors.inputBackground,
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        child: InkWell(
          key: const Key('inventory_check_draft_search_action'),
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
                IconButton(
                  key: const Key('inventory_check_draft_scan_action'),
                  tooltip: 'Quét mã',
                  icon: const Icon(Icons.qr_code_scanner_rounded, size: 20),
                  color: AppColors.textPrimary,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints.tightFor(
                    width: 34,
                    height: 34,
                  ),
                  onPressed: () => _showComingSoon(context, 'Quét mã kiểm kho'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _InventoryCheckDraftFilters extends StatelessWidget {
  const _InventoryCheckDraftFilters();

  static const _filters = ['Tất cả', 'Đã cân bằng', 'Lệch', 'Trống'];

  @override
  Widget build(BuildContext context) {
    return Container(
      alignment: Alignment.centerLeft,
      color: AppColors.background,
      padding: const EdgeInsets.fromLTRB(
        AppConstants.spacingSm,
        AppConstants.spacingSm,
        AppConstants.spacingSm,
        AppConstants.spacingSm,
      ),
      child: Row(
        children: [
          for (final filter in _filters) ...[
            Expanded(
              child: _InventoryCheckDraftFilterChip(
                label: filter,
                isSelected: filter == 'Tất cả',
              ),
            ),
            if (filter != _filters.last)
              const SizedBox(width: AppConstants.spacingXs),
          ],
        ],
      ),
    );
  }
}

class _InventoryCheckDraftFilterChip extends StatelessWidget {
  final String label;
  final bool isSelected;

  const _InventoryCheckDraftFilterChip({
    required this.label,
    required this.isSelected,
  });

  @override
  Widget build(BuildContext context) {
    return OutlinedButton(
      onPressed: isSelected ? null : () => _showComingSoon(context, label),
      style: OutlinedButton.styleFrom(
        minimumSize: const Size(0, 38),
        padding: const EdgeInsets.symmetric(horizontal: AppConstants.spacingXs),
        foregroundColor: isSelected ? AppColors.primary : AppColors.textPrimary,
        backgroundColor: isSelected
            ? AppColors.primaryLight
            : AppColors.surface,
        disabledForegroundColor: AppColors.primary,
        side: BorderSide(
          color: isSelected ? AppColors.primary : AppColors.borderStrong,
        ),
        textStyle: AppTextStyles.labelXs,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppTheme.radiusSm),
        ),
      ),
      child: Text(label, maxLines: 1, overflow: TextOverflow.ellipsis),
    );
  }
}

class _InventoryCheckDraftItemCard extends StatelessWidget {
  final StoreInventoryCheckDraftSeedData seedData;
  final int actualQuantity;
  final int systemQuantity;
  final int differenceQuantity;
  final VoidCallback onIncrement;
  final VoidCallback onDecrement;

  const _InventoryCheckDraftItemCard({
    required this.seedData,
    required this.actualQuantity,
    required this.systemQuantity,
    required this.differenceQuantity,
    required this.onIncrement,
    required this.onDecrement,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surface,
      child: Padding(
        padding: const EdgeInsets.all(AppConstants.spacingSm),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                _InventoryCheckDraftThumb(isProduct: seedData.isProduct),
                Positioned(
                  left: -6,
                  top: -6,
                  child: Container(
                    width: 16,
                    height: 16,
                    alignment: Alignment.center,
                    decoration: const BoxDecoration(
                      color: AppColors.textMuted,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.close_rounded,
                      color: AppColors.surface,
                      size: 12,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(width: AppConstants.spacingSm),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    seedData.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.labelSm.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: AppConstants.spacingXs),
                  Text(
                    seedData.code,
                    style: AppTextStyles.bodyXs.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: AppConstants.spacingSm),
                  _InventoryCheckDraftQuantityStepper(
                    code: seedData.code,
                    quantity: actualQuantity,
                    onIncrement: onIncrement,
                    onDecrement: onDecrement,
                  ),
                ],
              ),
            ),
            const SizedBox(width: AppConstants.spacingSm),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                const SizedBox(height: AppConstants.spacingXs),
                Text(
                  'Kho hệ thống: ${seedData.stockText}',
                  style: AppTextStyles.bodyXs.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: AppConstants.spacingMd),
                Text(
                  'Lệch: ${_signedDifferenceText(differenceQuantity)}',
                  key: const Key('inventory_check_draft_item_difference'),
                  style: AppTextStyles.labelSm.copyWith(
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _InventoryCheckDraftQuantityStepper extends StatelessWidget {
  final String code;
  final int quantity;
  final VoidCallback onIncrement;
  final VoidCallback onDecrement;

  const _InventoryCheckDraftQuantityStepper({
    required this.code,
    required this.quantity,
    required this.onIncrement,
    required this.onDecrement,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      key: Key('inventory_check_draft_stepper_$code'),
      height: 34,
      constraints: const BoxConstraints(minWidth: 112),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        border: Border.all(color: AppColors.borderStrong),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _QuantityIconButton(
            key: Key('inventory_check_draft_decrement_$code'),
            icon: Icons.remove_rounded,
            onPressed: onDecrement,
          ),
          SizedBox(
            width: 36,
            child: Text(
              quantity.toString(),
              key: Key('inventory_check_draft_quantity_$code'),
              textAlign: TextAlign.center,
              style: AppTextStyles.labelSm.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          _QuantityIconButton(
            key: Key('inventory_check_draft_increment_$code'),
            icon: Icons.add_rounded,
            color: AppColors.primary,
            onPressed: onIncrement,
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
      height: 34,
      child: IconButton(
        onPressed: onPressed,
        icon: Icon(icon, size: 18),
        color: color,
        padding: EdgeInsets.zero,
      ),
    );
  }
}

class _InventoryCheckDraftThumb extends StatelessWidget {
  final bool isProduct;

  const _InventoryCheckDraftThumb({required this.isProduct});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 42,
      height: 42,
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

class _InventoryCheckDraftSummary extends StatelessWidget {
  final int actualQuantity;
  final int systemQuantity;
  final int differenceQuantity;

  const _InventoryCheckDraftSummary({
    required this.actualQuantity,
    required this.systemQuantity,
    required this.differenceQuantity,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.surface,
      margin: const EdgeInsets.only(top: AppConstants.spacingXs),
      padding: const EdgeInsets.symmetric(vertical: AppConstants.spacingXs),
      child: Column(
        children: [
          _InventoryCheckDraftSummaryRow(
            label: 'Số lượng tồn thực tế',
            value: '$actualQuantity',
            valueKey: const Key('inventory_check_draft_actual_quantity'),
          ),
          _InventoryCheckDraftSummaryRow(
            label: 'Số lượng tồn kho hệ thống',
            value: '$systemQuantity',
            valueKey: const Key('inventory_check_draft_system_quantity'),
          ),
          _InventoryCheckDraftSummaryRow(
            label: 'Số lượng chênh lệch',
            value: '$differenceQuantity',
            valueKey: const Key('inventory_check_draft_difference_quantity'),
          ),
        ],
      ),
    );
  }
}

class _InventoryCheckDraftSummaryRow extends StatelessWidget {
  final String label;
  final String value;
  final Key valueKey;

  const _InventoryCheckDraftSummaryRow({
    required this.label,
    required this.value,
    required this.valueKey,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppConstants.spacingSm,
        vertical: AppConstants.spacingXs,
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: AppTextStyles.bodySm.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ),
          Text(
            value,
            key: valueKey,
            style: AppTextStyles.labelSm.copyWith(fontWeight: FontWeight.w800),
          ),
        ],
      ),
    );
  }
}

class _InventoryCheckDraftNoteRow extends StatelessWidget {
  const _InventoryCheckDraftNoteRow();

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(top: AppConstants.spacingXs),
      color: AppColors.surface,
      padding: const EdgeInsets.all(AppConstants.spacingSm),
      child: Row(
        children: [
          Expanded(
            child: InkWell(
              onTap: () => _showComingSoon(context, 'Ghi chú phiếu kiểm kho'),
              child: Text(
                'Ghi chú phiếu kiểm kho',
                style: AppTextStyles.bodySm.copyWith(
                  color: AppColors.textMuted,
                ),
              ),
            ),
          ),
          OutlinedButton(
            onPressed: () => _showComingSoon(context, 'Ảnh phiếu kiểm kho'),
            style: OutlinedButton.styleFrom(
              minimumSize: const Size.square(44),
              padding: EdgeInsets.zero,
              foregroundColor: AppColors.primary,
              side: const BorderSide(color: AppColors.primary),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppTheme.radiusMd),
              ),
            ),
            child: const Icon(Icons.image_outlined, size: 20),
          ),
        ],
      ),
    );
  }
}

class _InventoryCheckDraftBottomActions extends StatelessWidget {
  const _InventoryCheckDraftBottomActions();

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surface,
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.all(AppConstants.spacingSm),
          child: Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  key: const Key('inventory_check_draft_save_action'),
                  onPressed: () =>
                      _showComingSoon(context, 'Lưu phiếu kiểm kho'),
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size(0, 52),
                    foregroundColor: AppColors.primary,
                    side: const BorderSide(color: AppColors.primary),
                    textStyle: AppTextStyles.buttonSm,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                    ),
                  ),
                  child: const Text('Lưu phiếu'),
                ),
              ),
              const SizedBox(width: AppConstants.spacingSm),
              Expanded(
                child: ElevatedButton(
                  key: const Key('inventory_check_draft_complete_action'),
                  onPressed: () =>
                      _showComingSoon(context, 'Hoàn thành phiếu kiểm kho'),
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size(0, 52),
                    backgroundColor: AppColors.primary,
                    foregroundColor: AppColors.surface,
                    textStyle: AppTextStyles.buttonSm,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                    ),
                  ),
                  child: const Text('Hoàn thành'),
                ),
              ),
            ],
          ),
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

int _parseMockQuantity(String value) {
  final match = RegExp(r'\d+').firstMatch(value);
  return int.tryParse(match?.group(0) ?? '') ?? 0;
}

String _signedDifferenceText(int differenceQuantity) {
  if (differenceQuantity == 0) {
    return '0';
  }

  return differenceQuantity > 0
      ? '-$differenceQuantity'
      : '+${differenceQuantity.abs()}';
}

void _showComingSoon(BuildContext context, String feature) {
  ScaffoldMessenger.of(
    context,
  ).showSnackBar(SnackBar(content: Text('$feature sẽ được triển khai sau')));
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../config/router_config.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/theme/index.dart';
import '../../../workspace_context/presentation/controllers/store_access_state.dart';
import '../../../workspace_context/presentation/providers/workspace_context_providers.dart';
import '../providers/store_inventory_export_supplement_materials_mock_provider.dart';

class StoreInventoryExportSupplementMaterialDraftSeedData {
  final Map<String, int> quantitiesByCode;

  const StoreInventoryExportSupplementMaterialDraftSeedData({
    required this.quantitiesByCode,
  });
}

class StoreInventoryExportSupplementMaterialDraftPage extends ConsumerWidget {
  final int storeId;
  final StoreInventoryExportSupplementMaterialDraftSeedData? seedData;

  const StoreInventoryExportSupplementMaterialDraftPage({
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
  final StoreInventoryExportSupplementMaterialDraftSeedData? seedData;

  const _ReadyView({required this.storeId, this.seedData});

  @override
  ConsumerState<_ReadyView> createState() => _ReadyViewState();
}

class _ReadyViewState extends ConsumerState<_ReadyView> {
  late final Map<String, int> _quantitiesByCode;

  @override
  void initState() {
    super.initState();
    _quantitiesByCode = {...?widget.seedData?.quantitiesByCode};
  }

  int get _totalQuantity {
    return _quantitiesByCode.values.fold(0, (total, quantity) {
      return total + quantity;
    });
  }

  void _goToMaterialSelection() {
    context.goNamed(
      RouteNames.storeInventoryExportSupplementMaterials,
      pathParameters: {'storeId': widget.storeId.toString()},
      extra: StoreInventoryExportSupplementMaterialDraftSeedData(
        quantitiesByCode: Map.unmodifiable(_quantitiesByCode),
      ),
    );
  }

  void _incrementMaterial(
    StoreInventoryExportSupplementMaterialMockItem material,
  ) {
    setState(() {
      _quantitiesByCode[material.code] =
          (_quantitiesByCode[material.code] ?? 0) + 1;
    });
  }

  void _decrementMaterial(
    StoreInventoryExportSupplementMaterialMockItem material,
  ) {
    setState(() {
      final currentQuantity = _quantitiesByCode[material.code] ?? 0;
      if (currentQuantity <= 1) {
        _quantitiesByCode.remove(material.code);
        return;
      }

      _quantitiesByCode[material.code] = currentQuantity - 1;
    });
  }

  void _removeMaterial(
    StoreInventoryExportSupplementMaterialMockItem material,
  ) {
    setState(() {
      _quantitiesByCode.remove(material.code);
    });
  }

  @override
  Widget build(BuildContext context) {
    // TODO: Replace mock material selection with API-backed supplement draft data.
    final materials = ref.watch(
      storeInventoryExportSupplementMaterialsMockProvider,
    );
    final selectedMaterials = materials
        .where((material) => (_quantitiesByCode[material.code] ?? 0) > 0)
        .toList(growable: false);

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 560),
        child: Column(
          children: [
            _SupplementMaterialDraftHeader(onBack: _goToMaterialSelection),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.only(bottom: AppConstants.spacingLg),
                children: [
                  _AddMaterialOutlineButton(onPressed: _goToMaterialSelection),
                  if (selectedMaterials.isEmpty)
                    const _EmptyDraftMaterialView()
                  else
                    Material(
                      color: AppColors.surface,
                      child: Column(
                        children: [
                          for (
                            var index = 0;
                            index < selectedMaterials.length;
                            index++
                          ) ...[
                            _DraftMaterialTile(
                              material: selectedMaterials[index],
                              quantity:
                                  _quantitiesByCode[selectedMaterials[index]
                                      .code] ??
                                  0,
                              onIncrement: () =>
                                  _incrementMaterial(selectedMaterials[index]),
                              onDecrement: () =>
                                  _decrementMaterial(selectedMaterials[index]),
                              onRemove: () =>
                                  _removeMaterial(selectedMaterials[index]),
                            ),
                            if (index < selectedMaterials.length - 1)
                              const Divider(
                                height: 1,
                                indent: AppConstants.spacingMd,
                                endIndent: AppConstants.spacingMd,
                              ),
                          ],
                        ],
                      ),
                    ),
                  _DraftSummary(
                    materialCount: selectedMaterials.length,
                    totalQuantity: _totalQuantity,
                  ),
                  const _DraftNoteRow(),
                ],
              ),
            ),
            const _DraftBottomActions(),
          ],
        ),
      ),
    );
  }
}

class _SupplementMaterialDraftHeader extends StatelessWidget {
  final VoidCallback onBack;

  const _SupplementMaterialDraftHeader({required this.onBack});

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
            key: const Key(
              'inventory_export_supplement_material_draft_back_action',
            ),
            tooltip: 'Quay lại',
            icon: const Icon(Icons.arrow_back_rounded),
            onPressed: onBack,
          ),
          Expanded(
            child: Text(
              'Tạo phiếu bổ sung nguyên vật liệu',
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

class _AddMaterialOutlineButton extends StatelessWidget {
  final VoidCallback onPressed;

  const _AddMaterialOutlineButton({required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.background,
      padding: const EdgeInsets.fromLTRB(
        AppConstants.spacingMd,
        AppConstants.spacingMd,
        AppConstants.spacingMd,
        AppConstants.spacingSm,
      ),
      child: OutlinedButton.icon(
        key: const Key('inventory_export_supplement_material_draft_add_action'),
        onPressed: onPressed,
        icon: const Icon(Icons.add_rounded, size: 20),
        label: const Text('Thêm nguyên vật liệu'),
        style: OutlinedButton.styleFrom(
          minimumSize: const Size(0, 44),
          foregroundColor: AppColors.primary,
          side: const BorderSide(color: AppColors.primary),
          textStyle: AppTextStyles.labelSm,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppTheme.radiusMd),
          ),
        ),
      ),
    );
  }
}

class _DraftMaterialTile extends StatelessWidget {
  final StoreInventoryExportSupplementMaterialMockItem material;
  final int quantity;
  final VoidCallback onIncrement;
  final VoidCallback onDecrement;
  final VoidCallback onRemove;

  const _DraftMaterialTile({
    required this.material,
    required this.quantity,
    required this.onIncrement,
    required this.onDecrement,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(AppConstants.spacingMd),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Stack(
            clipBehavior: Clip.none,
            children: [
              const _MaterialThumb(),
              Positioned(
                left: -8,
                top: -8,
                child: InkWell(
                  key: Key(
                    'inventory_export_supplement_material_draft_remove_${material.code}',
                  ),
                  onTap: onRemove,
                  borderRadius: BorderRadius.circular(AppTheme.radiusXl),
                  child: Container(
                    width: 18,
                    height: 18,
                    alignment: Alignment.center,
                    decoration: const BoxDecoration(
                      color: AppColors.textMuted,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.close_rounded,
                      color: AppColors.surface,
                      size: 13,
                    ),
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
                  material.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.labelSm.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(material.code, style: AppTextStyles.bodyXs),
                const SizedBox(height: AppConstants.spacingSm),
                _MaterialQuantityStepper(
                  code: material.code,
                  quantity: quantity,
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
              Text(
                'Giá: 0',
                style: AppTextStyles.bodyXs.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: AppConstants.spacingXs),
              Text(
                '0',
                style: AppTextStyles.h4.copyWith(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _MaterialQuantityStepper extends StatelessWidget {
  final String code;
  final int quantity;
  final VoidCallback onIncrement;
  final VoidCallback onDecrement;

  const _MaterialQuantityStepper({
    required this.code,
    required this.quantity,
    required this.onIncrement,
    required this.onDecrement,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      key: Key('inventory_export_supplement_material_draft_stepper_$code'),
      height: 36,
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
            key: Key(
              'inventory_export_supplement_material_draft_decrement_$code',
            ),
            icon: Icons.remove_rounded,
            onPressed: onDecrement,
          ),
          SizedBox(
            width: 36,
            child: Text(
              quantity.toString(),
              key: Key(
                'inventory_export_supplement_material_draft_quantity_$code',
              ),
              textAlign: TextAlign.center,
              style: AppTextStyles.labelSm.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          _QuantityIconButton(
            key: Key(
              'inventory_export_supplement_material_draft_increment_$code',
            ),
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
      width: 36,
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

class _MaterialThumb extends StatelessWidget {
  const _MaterialThumb();

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
        Icons.inventory_outlined,
        color: AppColors.textMuted,
        size: 22,
      ),
    );
  }
}

class _DraftSummary extends StatelessWidget {
  final int materialCount;
  final int totalQuantity;

  const _DraftSummary({
    required this.materialCount,
    required this.totalQuantity,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(top: AppConstants.spacingSm),
      color: AppColors.surface,
      padding: const EdgeInsets.symmetric(vertical: AppConstants.spacingSm),
      child: Column(
        children: [
          _DraftSummaryRow(
            label: 'Tổng số lượng',
            value: '$totalQuantity',
            valueKey: const Key(
              'inventory_export_supplement_material_draft_total_quantity',
            ),
          ),
          _DraftSummaryRow(
            label: 'Nguyên vật liệu',
            value: '$materialCount',
            isIndented: true,
            valueKey: const Key(
              'inventory_export_supplement_material_draft_material_count',
            ),
          ),
          const _DraftSummaryRow(
            label: 'Tổng cộng',
            value: '0',
            isTotal: true,
            valueColor: AppColors.primary,
            valueKey: Key(
              'inventory_export_supplement_material_draft_total_amount',
            ),
          ),
        ],
      ),
    );
  }
}

class _DraftSummaryRow extends StatelessWidget {
  final String label;
  final String value;
  final bool isTotal;
  final bool isIndented;
  final Color? valueColor;
  final Key? valueKey;

  const _DraftSummaryRow({
    required this.label,
    required this.value,
    this.isTotal = false,
    this.isIndented = false,
    this.valueColor,
    this.valueKey,
  });

  @override
  Widget build(BuildContext context) {
    final labelStyle = isTotal
        ? AppTextStyles.label.copyWith(fontWeight: FontWeight.w800)
        : AppTextStyles.bodySm.copyWith(
            color: isIndented ? AppColors.textMuted : AppColors.textSecondary,
            fontWeight: isIndented ? FontWeight.w500 : FontWeight.w600,
          );
    final valueStyle = (isTotal ? AppTextStyles.h4 : AppTextStyles.labelSm)
        .copyWith(
          color: valueColor ?? AppColors.textPrimary,
          fontWeight: FontWeight.w800,
        );

    return Padding(
      padding: EdgeInsets.fromLTRB(
        isIndented
            ? AppConstants.spacingLg + AppConstants.spacingMd
            : AppConstants.spacingMd,
        AppConstants.spacingXs,
        AppConstants.spacingMd,
        AppConstants.spacingXs,
      ),
      child: Row(
        children: [
          Text(label, style: labelStyle),
          const Spacer(),
          Text(value, key: valueKey, style: valueStyle),
        ],
      ),
    );
  }
}

class _DraftNoteRow extends StatelessWidget {
  const _DraftNoteRow();

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(top: AppConstants.spacingSm),
      color: AppColors.surface,
      padding: const EdgeInsets.all(AppConstants.spacingMd),
      child: Row(
        children: [
          Expanded(
            child: InkWell(
              onTap: () => _showComingSoon(context, 'Ghi chú đơn hàng'),
              child: Text(
                'Ghi chú đơn hàng',
                style: AppTextStyles.bodySm.copyWith(
                  color: AppColors.textMuted,
                ),
              ),
            ),
          ),
          OutlinedButton(
            onPressed: () =>
                _showComingSoon(context, 'Ảnh phiếu bổ sung nguyên vật liệu'),
            style: OutlinedButton.styleFrom(
              minimumSize: const Size.square(48),
              padding: EdgeInsets.zero,
              foregroundColor: AppColors.primary,
              side: const BorderSide(color: AppColors.primary),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppTheme.radiusMd),
              ),
            ),
            child: const Icon(Icons.image_outlined, size: 22),
          ),
        ],
      ),
    );
  }
}

class _DraftBottomActions extends StatelessWidget {
  const _DraftBottomActions();

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surface,
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.all(AppConstants.spacingMd),
          child: ElevatedButton(
            key: const Key(
              'inventory_export_supplement_material_draft_complete_action',
            ),
            onPressed: () => _showComingSoon(
              context,
              'Hoàn thành phiếu bổ sung nguyên vật liệu',
            ),
            style: ElevatedButton.styleFrom(
              minimumSize: const Size(double.infinity, 52),
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
      ),
    );
  }
}

class _EmptyDraftMaterialView extends StatelessWidget {
  const _EmptyDraftMaterialView();

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.surface,
      padding: const EdgeInsets.all(AppConstants.spacingLg),
      child: Text(
        'Chưa có nguyên vật liệu bổ sung',
        textAlign: TextAlign.center,
        style: AppTextStyles.bodySm.copyWith(color: AppColors.textMuted),
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

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../../config/router_config.dart';
import '../../../../../core/constants/app_constants.dart';
import '../../../../../core/constants/app_permission_codes.dart';
import '../../../../../core/theme/index.dart';
import '../../../../workspace_context/presentation/controllers/store_access_state.dart';
import '../../../../workspace_context/presentation/providers/workspace_context_providers.dart';
import '../../../product_management/domain/entities/product.dart';
import '../../../product_management/domain/entities/inventory_deduction_mode.dart';
import '../../../product_management/domain/entities/product_topping.dart';
import '../../../product_management/domain/entities/product_variant_draft.dart';
import '../../../table_management/domain/entities/dining_table.dart';
import '../../domain/entities/voice_order_item.dart';
import '../../domain/entities/voice_order_recognition.dart';
import '../../domain/entities/voice_order_topping.dart';
import '../controllers/voice_order_notifier.dart';
import '../controllers/voice_order_state.dart';
import '../providers/voice_order_providers.dart';

class VoiceOrderPage extends ConsumerWidget {
  final int storeId;

  const VoiceOrderPage({super.key, required this.storeId});

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
          StoreAccessStatus.forbidden => const _BlockedView(
            icon: Icons.lock_outline_rounded,
            title: 'Không có quyền truy cập',
            message: 'Tài khoản của bạn không có quyền truy cập cửa hàng này.',
          ),
          StoreAccessStatus.error => _ErrorView(
            message:
                accessState.errorMessage ??
                'Không thể tải thông tin của cửa hàng',
            onRetry: () => ref
                .read(storeAccessNotifierProvider(storeId).notifier)
                .loadAccess(),
          ),
          StoreAccessStatus.ready =>
            accessState.can(AppPermissionCodes.dashboardView)
                ? _VoiceOrderBody(
                    storeId: storeId,
                    canCreateOrder: accessState.can(
                      AppPermissionCodes.orderCreate,
                    ),
                    canOpenSession: accessState.can(
                      AppPermissionCodes.tableOpenSession,
                    ),
                  )
                : const _BlockedView(
                    icon: Icons.visibility_off_outlined,
                    title: 'Bạn chưa có quyền dùng order giọng nói',
                    message:
                        'Vui lòng liên hệ quản trị viên cửa hàng để được cấp quyền.',
                  ),
        },
      ),
    );
  }
}

class _VoiceOrderBody extends ConsumerWidget {
  final int storeId;
  final bool canCreateOrder;
  final bool canOpenSession;

  const _VoiceOrderBody({
    required this.storeId,
    required this.canCreateOrder,
    required this.canOpenSession,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(voiceOrderNotifierProvider);
    final notifier = ref.read(voiceOrderNotifierProvider.notifier);
    final recognition = state.recognition;
    final productsAsync = ref.watch(voiceOrderProductsProvider(storeId));
    final tablesAsync = ref.watch(voiceOrderTablesProvider(storeId));
    final products = productsAsync.valueOrNull ?? const <Product>[];
    final tables = tablesAsync.valueOrNull ?? const <DiningTable>[];

    return Stack(
      children: [
        const Positioned.fill(child: _VoiceOrderBackground()),
        Column(
          children: [
            _Header(storeId: storeId, recognition: recognition),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(
                  AppConstants.spacingMd,
                  AppConstants.spacingSm,
                  AppConstants.spacingMd,
                  208,
                ),
                children: [
                  if (productsAsync.hasError)
                    const _InlineMessage(
                      icon: Icons.restaurant_menu_outlined,
                      message: 'Không thể tải danh sách món để gợi ý.',
                      tone: _MessageTone.warning,
                    ),
                  if (tablesAsync.hasError) ...[
                    const SizedBox(height: AppConstants.spacingSm),
                    const _InlineMessage(
                      icon: Icons.table_restaurant_outlined,
                      message: 'Không thể tải danh sách bàn để gợi ý.',
                      tone: _MessageTone.warning,
                    ),
                  ],
                  _TableSelector(
                    recognition: recognition,
                    tables: tables,
                    isLoading: tablesAsync.isLoading,
                    onTableChanged: notifier.updateTable,
                  ),
                  const SizedBox(height: AppConstants.spacingMd),
                  if (recognition == null)
                    const _EmptyOrderState()
                  else ...[
                    _TranscriptPanel(recognition: recognition),
                    const SizedBox(height: AppConstants.spacingMd),
                    _OrderItemsList(
                      recognition: recognition,
                      products: products,
                      onIncreaseItem: notifier.increaseItemQuantity,
                      onDecreaseItem: notifier.decreaseItemQuantity,
                      onUpdateItem: notifier.updateItem,
                    ),
                    if (recognition.missingFields.isNotEmpty) ...[
                      const SizedBox(height: AppConstants.spacingMd),
                      _InfoSection(
                        title: 'Thông tin còn thiếu',
                        icon: Icons.rule_folder_outlined,
                        tone: _MessageTone.warning,
                        messages: recognition.missingFields,
                      ),
                    ],
                    if (recognition.errors.isNotEmpty) ...[
                      const SizedBox(height: AppConstants.spacingMd),
                      _InfoSection(
                        title: 'Lỗi xác thực',
                        icon: Icons.error_outline_rounded,
                        tone: _MessageTone.error,
                        messages: recognition.errors,
                      ),
                    ],
                  ],
                  if (state.errorMessage != null &&
                      state.errorMessage!.trim().isNotEmpty) ...[
                    const SizedBox(height: AppConstants.spacingMd),
                    _InlineMessage(
                      icon: state.status == VoiceOrderStatus.permissionDenied
                          ? Icons.mic_off_outlined
                          : Icons.error_outline_rounded,
                      message: state.errorMessage!,
                      tone: _MessageTone.error,
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
        Positioned(
          left: 0,
          right: 0,
          bottom: AppConstants.spacingLg,
          child: SafeArea(
            top: false,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _VoiceStatusPill(state: state),
                const SizedBox(height: AppConstants.spacingSm),
                _HoldMicButton(
                  state: state,
                  onStart: notifier.startRecording,
                  onStop: () => notifier.stopAndRecognize(storeId),
                ),
                const SizedBox(height: AppConstants.spacingMd),
                _VoiceOrderActionBar(
                  state: state,
                  onCancel: notifier.clear,
                  onConfirm: () => _confirmOrder(
                    context,
                    notifier,
                    storeId: storeId,
                    canCreateOrder: canCreateOrder,
                    canOpenSession: canOpenSession,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _VoiceOrderBackground extends StatelessWidget {
  const _VoiceOrderBackground();

  @override
  Widget build(BuildContext context) {
    return const DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.background,
        border: Border(
          top: BorderSide(color: AppColors.primaryLight, width: 6),
        ),
      ),
      child: ColoredBox(color: Colors.transparent),
    );
  }
}

class _VoiceOrderActionBar extends StatelessWidget {
  final VoiceOrderState state;
  final VoidCallback onCancel;
  final VoidCallback onConfirm;

  const _VoiceOrderActionBar({
    required this.state,
    required this.onCancel,
    required this.onConfirm,
  });

  @override
  Widget build(BuildContext context) {
    final canCancel =
        !state.isBusy &&
        (state.recognition != null ||
            state.audioFilePath != null ||
            state.errorMessage != null);
    final canConfirm =
        state.recognition != null &&
        state.status != VoiceOrderStatus.recording &&
        !state.isBusy;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppConstants.spacingMd),
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton.icon(
              onPressed: canCancel ? onCancel : null,
              icon: const Icon(Icons.close_rounded),
              label: const Text('Hủy'),
            ),
          ),
          const SizedBox(width: AppConstants.spacingSm),
          Expanded(
            child: ElevatedButton.icon(
              onPressed: canConfirm ? onConfirm : null,
              icon: state.status == VoiceOrderStatus.submitting
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.check_rounded),
              label: const Text('Xác nhận'),
            ),
          ),
        ],
      ),
    );
  }
}

class _Header extends StatelessWidget {
  final int storeId;
  final VoiceOrderRecognition? recognition;

  const _Header({required this.storeId, required this.recognition});

  @override
  Widget build(BuildContext context) {
    final isValid = recognition?.validationSucceeded == true;
    final hasResult = recognition != null;

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppConstants.spacingMd,
        AppConstants.spacingSm,
        AppConstants.spacingMd,
        AppConstants.spacingSm,
      ),
      child: Row(
        children: [
          _CircleIconButton(
            icon: Icons.chevron_left_rounded,
            onTap: () => context.goNamed(
              RouteNames.storeOverview,
              pathParameters: {'storeId': storeId.toString()},
            ),
          ),
          const SizedBox(width: AppConstants.spacingSm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Order bằng giọng nói',
                  style: AppTextStyles.h4.copyWith(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 2),
                Text(
                  hasResult
                      ? (isValid ? 'Kết quả hợp lệ' : 'Cần kiểm tra lại')
                      : 'Nhấn giữ mic để đọc order',
                  style: AppTextStyles.bodyXs.copyWith(
                    color: isValid ? AppColors.success : AppColors.textMuted,
                  ),
                ),
              ],
            ),
          ),
          TextButton(
            onPressed: () => context.goNamed(
              RouteNames.storeOverview,
              pathParameters: {'storeId': storeId.toString()},
            ),
            child: const Text('Xong'),
          ),
        ],
      ),
    );
  }
}

class _TableSelector extends StatelessWidget {
  final VoiceOrderRecognition? recognition;
  final List<DiningTable> tables;
  final bool isLoading;
  final void Function({int? tableId, String? tableName, String? tableStatus})
  onTableChanged;

  const _TableSelector({
    required this.recognition,
    required this.tables,
    required this.isLoading,
    required this.onTableChanged,
  });

  @override
  Widget build(BuildContext context) {
    return _Panel(
      padding: const EdgeInsets.all(AppConstants.spacingMd),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.table_restaurant_outlined,
                color: AppColors.primary,
              ),
              const SizedBox(width: AppConstants.spacingSm),
              Expanded(
                child: Text(
                  'Bàn',
                  style: AppTextStyles.labelSm.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              if (isLoading)
                const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
            ],
          ),
          const SizedBox(height: AppConstants.spacingSm),
          Autocomplete<DiningTable>(
            key: ValueKey(_tableLabel(recognition)),
            initialValue: TextEditingValue(text: _tableLabel(recognition)),
            displayStringForOption: (table) => table.name,
            optionsBuilder: (value) {
              final query = value.text.trim().toLowerCase();
              if (query.isEmpty) {
                return tables.take(6);
              }

              return tables
                  .where((table) => table.name.toLowerCase().contains(query))
                  .take(8);
            },
            onSelected: (table) => onTableChanged(
              tableId: table.id,
              tableName: table.name,
              tableStatus: table.status.name,
            ),
            fieldViewBuilder:
                (context, controller, focusNode, onFieldSubmitted) {
                  return TextField(
                    controller: controller,
                    focusNode: focusNode,
                    decoration: const InputDecoration(
                      hintText: 'Nhập hoặc chọn bàn',
                      prefixIcon: Icon(Icons.search_rounded),
                    ),
                    onSubmitted: (value) => onTableChanged(
                      tableId: null,
                      tableName: value,
                      tableStatus: null,
                    ),
                  );
                },
          ),
        ],
      ),
    );
  }
}

class _TranscriptPanel extends StatelessWidget {
  final VoiceOrderRecognition recognition;

  const _TranscriptPanel({required this.recognition});

  @override
  Widget build(BuildContext context) {
    final transcript = recognition.transcript.trim();
    if (transcript.isEmpty) {
      return const SizedBox.shrink();
    }

    return _Panel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Nội dung nhận diện',
            style: AppTextStyles.labelSm.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: AppConstants.spacingXs),
          Text(transcript, style: AppTextStyles.bodySm),
        ],
      ),
    );
  }
}

class _EmptyOrderState extends StatelessWidget {
  const _EmptyOrderState();

  @override
  Widget build(BuildContext context) {
    return _Panel(
      padding: const EdgeInsets.symmetric(
        horizontal: AppConstants.spacingMd,
        vertical: AppConstants.spacingXl,
      ),
      child: Column(
        children: [
          const Icon(
            Icons.mic_none_rounded,
            size: 42,
            color: AppColors.textMuted,
          ),
          const SizedBox(height: AppConstants.spacingMd),
          Text(
            'Chưa có order',
            style: AppTextStyles.h4.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: AppConstants.spacingXs),
          const Text(
            'Nhấn giữ mic để đọc order, kết quả sẽ xuất hiện tại đây.',
            style: AppTextStyles.bodySm,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _OrderItemsList extends StatelessWidget {
  final VoiceOrderRecognition recognition;
  final List<Product> products;
  final ValueChanged<VoiceOrderItem> onIncreaseItem;
  final ValueChanged<VoiceOrderItem> onDecreaseItem;
  final void Function(
    VoiceOrderItem original, {
    int? productId,
    required String productName,
    Object? variantId,
    Object? variantName,
    required int quantity,
    String? note,
    List<VoiceOrderTopping>? toppings,
  })
  onUpdateItem;

  const _OrderItemsList({
    required this.recognition,
    required this.products,
    required this.onIncreaseItem,
    required this.onDecreaseItem,
    required this.onUpdateItem,
  });

  @override
  Widget build(BuildContext context) {
    if (recognition.items.isEmpty) {
      return const _Panel(
        child: Text('Chưa có món nào.', style: AppTextStyles.bodySm),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: AppConstants.spacingSm),
          child: Text(
            'Món đã nhận diện',
            style: AppTextStyles.labelSm.copyWith(fontWeight: FontWeight.w700),
          ),
        ),
        for (final item in recognition.items) ...[
          _OrderItemCard(
            item: item,
            products: products,
            onIncrease: () => onIncreaseItem(item),
            onDecrease: () => onDecreaseItem(item),
            onUpdate: onUpdateItem,
          ),
          if (item != recognition.items.last)
            const SizedBox(height: AppConstants.spacingSm),
        ],
      ],
    );
  }
}

class _OrderItemCard extends StatelessWidget {
  final VoiceOrderItem item;
  final List<Product> products;
  final VoidCallback onIncrease;
  final VoidCallback onDecrease;
  final void Function(
    VoiceOrderItem original, {
    int? productId,
    required String productName,
    Object? variantId,
    Object? variantName,
    required int quantity,
    String? note,
    List<VoiceOrderTopping>? toppings,
  })
  onUpdate;

  const _OrderItemCard({
    required this.item,
    required this.products,
    required this.onIncrease,
    required this.onDecrease,
    required this.onUpdate,
  });

  @override
  Widget build(BuildContext context) {
    final note = item.note?.trim();

    return _Panel(
      onTap: () => _showEditSheet(context, item, products, onUpdate),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        item.productName,
                        style: AppTextStyles.label.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    if (!item.available)
                      const Icon(
                        Icons.error_outline_rounded,
                        color: AppColors.error,
                        size: 20,
                      ),
                  ],
                ),
                const SizedBox(height: AppConstants.spacingSm),
                Wrap(
                  spacing: AppConstants.spacingXs,
                  runSpacing: AppConstants.spacingXs,
                  children: [
                    _Tag(text: 'SL ${item.quantity}'),
                    if (item.variantName?.trim().isNotEmpty == true)
                      _Tag(text: 'Size ${item.variantName!.trim()}'),
                    for (final topping in item.toppings)
                      _Tag(
                        text: topping.quantity > 1
                            ? '${topping.name} x${topping.quantity}'
                            : topping.name,
                      ),
                  ],
                ),
                if (note != null && note.isNotEmpty) ...[
                  const SizedBox(height: AppConstants.spacingSm),
                  Text('Ghi chú: $note', style: AppTextStyles.bodySm),
                ],
                if (item.message?.trim().isNotEmpty == true) ...[
                  const SizedBox(height: AppConstants.spacingSm),
                  Text(
                    item.message!.trim(),
                    style: AppTextStyles.bodySm.copyWith(
                      color: AppColors.error,
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: AppConstants.spacingMd),
          _QuantityControl(
            quantity: item.quantity,
            onDecrease: onDecrease,
            onIncrease: onIncrease,
          ),
        ],
      ),
    );
  }
}

class _QuantityControl extends StatelessWidget {
  final int quantity;
  final VoidCallback onDecrease;
  final VoidCallback onIncrease;

  const _QuantityControl({
    required this.quantity,
    required this.onDecrease,
    required this.onIncrease,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _StepperButton(icon: Icons.remove_rounded, onTap: onDecrease),
        const SizedBox(width: AppConstants.spacingSm),
        SizedBox(
          width: 28,
          child: Text(
            '$quantity',
            style: AppTextStyles.h4.copyWith(fontWeight: FontWeight.w700),
            textAlign: TextAlign.center,
          ),
        ),
        const SizedBox(width: AppConstants.spacingSm),
        _StepperButton(icon: Icons.add_rounded, onTap: onIncrease),
      ],
    );
  }
}

class _StepperButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onTap;

  const _StepperButton({required this.icon, this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.primaryLight,
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: SizedBox(
          width: 34,
          height: 34,
          child: Icon(icon, color: AppColors.primary, size: 18),
        ),
      ),
    );
  }
}

class _HoldMicButton extends StatelessWidget {
  final VoiceOrderState state;
  final VoidCallback onStart;
  final VoidCallback onStop;

  const _HoldMicButton({
    required this.state,
    required this.onStart,
    required this.onStop,
  });

  @override
  Widget build(BuildContext context) {
    final isRecording = state.status == VoiceOrderStatus.recording;
    final isProcessing = state.isBusy;
    final color = isRecording ? AppColors.error : AppColors.primary;

    return Center(
      child: Listener(
        behavior: HitTestBehavior.opaque,
        onPointerDown: isProcessing ? null : (_) => onStart(),
        onPointerUp: isProcessing ? null : (_) => onStop(),
        onPointerCancel: isProcessing ? null : (_) => onStop(),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: AppColors.surface,
            shape: BoxShape.circle,
            border: Border.all(color: AppColors.borderStrong),
            boxShadow: [
              BoxShadow(
                color: AppColors.textPrimary.withValues(alpha: 0.08),
                blurRadius: 16,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: SizedBox(
            width: 64,
            height: 64,
            child: Center(
              child: isProcessing
                  ? SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.5,
                        color: color,
                      ),
                    )
                  : Icon(Icons.mic_rounded, color: color, size: 34),
            ),
          ),
        ),
      ),
    );
  }
}

class _VoiceStatusPill extends StatelessWidget {
  final VoiceOrderState state;

  const _VoiceStatusPill({required this.state});

  @override
  Widget build(BuildContext context) {
    if (state.status == VoiceOrderStatus.idle ||
        state.status == VoiceOrderStatus.success) {
      return const SizedBox.shrink();
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: AppConstants.spacingMd),
      padding: const EdgeInsets.symmetric(
        horizontal: AppConstants.spacingMd,
        vertical: AppConstants.spacingSm,
      ),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppTheme.radiusXl),
        border: Border.all(color: AppColors.border),
      ),
      child: Text(
        _statusTitle(state),
        style: AppTextStyles.labelSm,
        textAlign: TextAlign.center,
      ),
    );
  }
}

class _CircleIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _CircleIconButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surface,
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: SizedBox(
          width: 42,
          height: 42,
          child: Icon(icon, color: AppColors.textPrimary),
        ),
      ),
    );
  }
}

class _Panel extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final VoidCallback? onTap;

  const _Panel({
    required this.child,
    this.padding = const EdgeInsets.all(AppConstants.spacingMd),
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(AppTheme.radiusLg),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
        onTap: onTap,
        child: Container(
          width: double.infinity,
          padding: padding,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppTheme.radiusLg),
            border: Border.all(color: AppColors.border),
          ),
          child: child,
        ),
      ),
    );
  }
}

class _Tag extends StatelessWidget {
  final String text;

  const _Tag({required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppConstants.spacingSm,
        vertical: AppConstants.spacingXs,
      ),
      decoration: BoxDecoration(
        color: AppColors.sidebar,
        borderRadius: BorderRadius.circular(AppTheme.radiusSm),
        border: Border.all(color: AppColors.border),
      ),
      child: Text(text, style: AppTextStyles.labelXs),
    );
  }
}

enum _MessageTone { info, warning, error }

class _InlineMessage extends StatelessWidget {
  final IconData icon;
  final String message;
  final _MessageTone tone;

  const _InlineMessage({
    required this.icon,
    required this.message,
    this.tone = _MessageTone.info,
  });

  @override
  Widget build(BuildContext context) {
    final color = _toneColor(tone);

    return Container(
      padding: const EdgeInsets.all(AppConstants.spacingMd),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
        border: Border.all(color: color.withValues(alpha: 0.24)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color),
          const SizedBox(width: AppConstants.spacingSm),
          Expanded(child: Text(message, style: AppTextStyles.bodySm)),
        ],
      ),
    );
  }
}

class _InfoSection extends StatelessWidget {
  final String title;
  final IconData icon;
  final _MessageTone tone;
  final List<String> messages;

  const _InfoSection({
    required this.title,
    required this.icon,
    required this.tone,
    required this.messages,
  });

  @override
  Widget build(BuildContext context) {
    final color = _toneColor(tone);

    return _Panel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color),
              const SizedBox(width: AppConstants.spacingSm),
              Text(
                title,
                style: AppTextStyles.labelSm.copyWith(
                  color: color,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppConstants.spacingSm),
          for (final message in messages)
            Padding(
              padding: const EdgeInsets.only(bottom: AppConstants.spacingXs),
              child: Text('• $message', style: AppTextStyles.bodySm),
            ),
        ],
      ),
    );
  }
}

Color _toneColor(_MessageTone tone) {
  return switch (tone) {
    _MessageTone.info => AppColors.info,
    _MessageTone.warning => AppColors.warning,
    _MessageTone.error => AppColors.error,
  };
}

Future<void> _confirmOrder(
  BuildContext context,
  VoiceOrderNotifier notifier, {
  required int storeId,
  required bool canCreateOrder,
  required bool canOpenSession,
}) async {
  try {
    await notifier.submit(storeId: storeId, canCreateOrder: canCreateOrder);
    if (!context.mounted) {
      return;
    }
    _showSnack(context, 'Tạo đơn hàng thành công!');
  } on VoiceOrderMissingSessionException catch (error) {
    if (!context.mounted) {
      return;
    }
    final shouldOpen = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Mở phiên bàn'),
        content: Text(
          'Bàn ${error.tableName} chưa có phiên mở. Bạn có muốn mở phiên không?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Không'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Có'),
          ),
        ],
      ),
    );

    if (shouldOpen != true || !context.mounted) {
      return;
    }

    try {
      await notifier.openTableSession(
        tableId: error.tableId,
        canOpenSession: canOpenSession,
      );
      if (!context.mounted) {
        return;
      }
      _showSnack(
        context,
        'Mở phiên bàn thành công. Nhấn Xác nhận lại để tạo đơn.',
      );
    } catch (openError) {
      if (!context.mounted) {
        return;
      }
      _showSnack(context, _cleanError(openError));
    }
  } catch (error) {
    if (!context.mounted) {
      return;
    }
    _showSnack(context, _cleanError(error));
  }
}

void _showSnack(BuildContext context, String message) {
  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
}

String _cleanError(Object error) {
  return error.toString().replaceFirst('Exception: ', '').trim();
}

Future<void> _showEditSheet(
  BuildContext context,
  VoiceOrderItem item,
  List<Product> products,
  void Function(
    VoiceOrderItem original, {
    int? productId,
    required String productName,
    Object? variantId,
    Object? variantName,
    required int quantity,
    String? note,
    List<VoiceOrderTopping>? toppings,
  })
  onUpdate,
) async {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (sheetContext) => _EditOrderItemSheet(
      item: item,
      products: products,
      onUpdate: onUpdate,
      onClose: () => Navigator.of(sheetContext).pop(),
    ),
  );
}

class _EditOrderItemSheet extends StatefulWidget {
  final VoiceOrderItem item;
  final List<Product> products;
  final VoidCallback onClose;
  final void Function(
    VoiceOrderItem original, {
    int? productId,
    required String productName,
    Object? variantId,
    Object? variantName,
    required int quantity,
    String? note,
    List<VoiceOrderTopping>? toppings,
  })
  onUpdate;

  const _EditOrderItemSheet({
    required this.item,
    required this.products,
    required this.onClose,
    required this.onUpdate,
  });

  @override
  State<_EditOrderItemSheet> createState() => _EditOrderItemSheetState();
}

class _EditOrderItemSheetState extends State<_EditOrderItemSheet> {
  late final TextEditingController _noteController;
  late String _productText;
  late int _quantity;
  Product? _selectedProduct;
  ProductVariantDraft? _selectedVariant;
  late Map<int, int> _toppingQuantities;

  @override
  void initState() {
    super.initState();
    _productText = widget.item.productName;
    _quantity = widget.item.quantity;
    _noteController = TextEditingController(
      text: widget.item.note?.trim() ?? '',
    );
    _selectedProduct = _findProduct(widget.item, widget.products);
    _selectedVariant = _findVariant(widget.item, _selectedProduct);
    _toppingQuantities = _initialToppingQuantities(widget.item);
    _filterToppingsForSelectedProduct();
  }

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final product = _selectedProduct;

    return Padding(
      padding: EdgeInsets.fromLTRB(
        AppConstants.spacingMd,
        AppConstants.spacingMd,
        AppConstants.spacingMd,
        MediaQuery.viewInsetsOf(context).bottom + AppConstants.spacingMd,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Chỉnh sửa món',
                    style: AppTextStyles.h3.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                IconButton(
                  onPressed: widget.onClose,
                  icon: const Icon(Icons.close_rounded),
                ),
              ],
            ),
            const SizedBox(height: AppConstants.spacingMd),
            Autocomplete<Product>(
              initialValue: TextEditingValue(text: widget.item.productName),
              displayStringForOption: (product) => product.name,
              optionsBuilder: (value) {
                final query = value.text.trim().toLowerCase();
                if (query.isEmpty) {
                  return widget.products.take(8);
                }

                return widget.products
                    .where(
                      (product) => product.name.toLowerCase().contains(query),
                    )
                    .take(8);
              },
              onSelected: _selectProduct,
              fieldViewBuilder:
                  (context, controller, focusNode, onFieldSubmitted) {
                    return TextField(
                      controller: controller,
                      focusNode: focusNode,
                      decoration: const InputDecoration(
                        labelText: 'Tên món',
                        hintText: 'Nhập tên món',
                        prefixIcon: Icon(Icons.search_rounded),
                      ),
                      onChanged: (value) {
                        _productText = value;
                        final selected = _selectedProduct;
                        if (selected != null && selected.name != value) {
                          setState(() {
                            _selectedProduct = null;
                            _selectedVariant = null;
                            _toppingQuantities = {};
                          });
                        }
                      },
                    );
                  },
            ),
            if (product != null && product.variants.isNotEmpty) ...[
              const SizedBox(height: AppConstants.spacingLg),
              Text('Kích cỡ', style: AppTextStyles.labelSm),
              const SizedBox(height: AppConstants.spacingSm),
              Wrap(
                spacing: AppConstants.spacingSm,
                runSpacing: AppConstants.spacingSm,
                children: [
                  if (product.inventoryDeductionMode ==
                      InventoryDeductionMode.productOnly)
                    ChoiceChip(
                      label: const Text('Giá sản phẩm'),
                      selected: _selectedVariant == null,
                      onSelected: (_) {
                        setState(() => _selectedVariant = null);
                      },
                    ),
                  for (final variant in _activeVariants(product))
                    ChoiceChip(
                      label: Text(variant.name),
                      selected: _sameVariant(_selectedVariant, variant),
                      onSelected: (_) {
                        setState(() => _selectedVariant = variant);
                      },
                    ),
                ],
              ),
            ],
            if (product != null && product.toppings.isNotEmpty) ...[
              const SizedBox(height: AppConstants.spacingLg),
              Text('Topping', style: AppTextStyles.labelSm),
              const SizedBox(height: AppConstants.spacingSm),
              for (final topping in product.toppings)
                _ToppingSelector(
                  topping: topping,
                  quantity: _toppingQuantities[topping.id] ?? 0,
                  onChanged: (quantity) => setState(() {
                    if (quantity <= 0) {
                      _toppingQuantities.remove(topping.id);
                    } else {
                      _toppingQuantities[topping.id] = quantity;
                    }
                  }),
                ),
            ],
            const SizedBox(height: AppConstants.spacingLg),
            TextField(
              controller: _noteController,
              decoration: const InputDecoration(
                labelText: 'Ghi chú',
                hintText: 'Ít đá, không cay...',
              ),
              maxLines: 2,
            ),
            const SizedBox(height: AppConstants.spacingLg),
            Center(
              child: _EditableQuantityControl(
                quantity: _quantity,
                onDecrease: () {
                  if (_quantity <= 1) {
                    return;
                  }
                  setState(() => _quantity -= 1);
                },
                onIncrease: () => setState(() => _quantity += 1),
              ),
            ),
            const SizedBox(height: AppConstants.spacingLg),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: widget.onClose,
                    child: const Text('Hủy'),
                  ),
                ),
                const SizedBox(width: AppConstants.spacingSm),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _save,
                    child: const Text('Lưu'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _selectProduct(Product product) {
    setState(() {
      _selectedProduct = product;
      _productText = product.name;
      _selectedVariant = _initialVariant(product);
      _toppingQuantities = {};
    });
  }

  void _save() {
    final exactProduct = _selectedProduct ?? _findProductByName(_productText);
    final selectedProduct = exactProduct;
    final selectedVariant = selectedProduct == null ? null : _selectedVariant;
    if (selectedProduct?.inventoryDeductionMode ==
            InventoryDeductionMode.variantOnly &&
        selectedVariant == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng chọn phiên bản cho món này.')),
      );
      return;
    }
    if (selectedProduct != null &&
        selectedVariant != null &&
        !_isActiveVariant(selectedVariant, _activeVariants(selectedProduct))) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Phiên bản đã ngừng bán.')));
      return;
    }
    final toppings = selectedProduct == null
        ? const <VoiceOrderTopping>[]
        : [
            for (final topping in selectedProduct.toppings)
              if ((_toppingQuantities[topping.id] ?? 0) > 0)
                VoiceOrderTopping(
                  id: topping.id,
                  name: topping.name,
                  quantity: _toppingQuantities[topping.id]!,
                ),
          ];

    widget.onUpdate(
      widget.item,
      productId: selectedProduct?.id,
      productName: selectedProduct?.name ?? _productText,
      variantId: selectedVariant?.id,
      variantName: selectedVariant?.name,
      quantity: _quantity,
      note: _noteController.text,
      toppings: toppings,
    );
    widget.onClose();
  }

  Product? _findProductByName(String value) {
    final normalized = value.trim().toLowerCase();
    if (normalized.isEmpty) {
      return null;
    }

    for (final product in widget.products) {
      if (product.name.trim().toLowerCase() == normalized) {
        return product;
      }
    }

    return null;
  }

  void _filterToppingsForSelectedProduct() {
    final product = _selectedProduct;
    if (product == null) {
      _toppingQuantities = {};
      return;
    }

    final validIds = product.toppings.map((topping) => topping.id).toSet();
    _toppingQuantities.removeWhere((id, _) => !validIds.contains(id));
  }
}

class _ToppingSelector extends StatelessWidget {
  final ProductTopping topping;
  final int quantity;
  final ValueChanged<int> onChanged;

  const _ToppingSelector({
    required this.topping,
    required this.quantity,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      title: Text(topping.name, style: AppTextStyles.bodyBase),
      subtitle: Text(_currency(topping.price), style: AppTextStyles.bodySm),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            onPressed: quantity == 0 ? null : () => onChanged(quantity - 1),
            icon: const Icon(Icons.remove_circle_outline),
          ),
          SizedBox(
            width: 28,
            child: Text(
              '$quantity',
              style: AppTextStyles.labelSm,
              textAlign: TextAlign.center,
            ),
          ),
          IconButton(
            onPressed: () => onChanged(quantity + 1),
            icon: const Icon(Icons.add_circle_outline),
          ),
        ],
      ),
    );
  }
}

class _EditableQuantityControl extends StatelessWidget {
  final int quantity;
  final VoidCallback onDecrease;
  final VoidCallback onIncrease;

  const _EditableQuantityControl({
    required this.quantity,
    required this.onDecrease,
    required this.onIncrease,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _StepperButton(icon: Icons.remove_rounded, onTap: onDecrease),
        const SizedBox(width: AppConstants.spacingLg),
        Text(
          '$quantity',
          style: AppTextStyles.h3.copyWith(fontWeight: FontWeight.w700),
        ),
        const SizedBox(width: AppConstants.spacingLg),
        _StepperButton(icon: Icons.add_rounded, onTap: onIncrease),
      ],
    );
  }
}

Product? _findProduct(VoiceOrderItem item, List<Product> products) {
  for (final product in products) {
    if (item.productId != null && product.id == item.productId) {
      return product;
    }
  }

  final itemName = item.productName.trim().toLowerCase();
  for (final product in products) {
    if (product.name.trim().toLowerCase() == itemName) {
      return product;
    }
  }

  return null;
}

ProductVariantDraft? _findVariant(VoiceOrderItem item, Product? product) {
  if (product == null || product.variants.isEmpty) {
    return null;
  }

  final activeVariants = _activeVariants(product);
  for (final variant in activeVariants) {
    if (item.variantId != null && variant.id == item.variantId) {
      return variant;
    }
  }

  final variantName = item.variantName?.trim().toLowerCase();
  if (variantName != null && variantName.isNotEmpty) {
    for (final variant in activeVariants) {
      if (variant.name.trim().toLowerCase() == variantName) {
        return variant;
      }
    }
  }

  return _initialVariant(product);
}

List<ProductVariantDraft> _activeVariants(Product product) {
  return product.variants
      .where((variant) => variant.isActive && variant.id != null)
      .toList(growable: false);
}

ProductVariantDraft? _initialVariant(Product product) {
  if (product.inventoryDeductionMode == InventoryDeductionMode.productOnly) {
    return null;
  }
  return _defaultVariant(_activeVariants(product));
}

ProductVariantDraft? _defaultVariant(List<ProductVariantDraft> variants) {
  if (variants.isEmpty) {
    return null;
  }

  for (final variant in variants) {
    if (variant.isDefault) {
      return variant;
    }
  }

  return variants.first;
}

bool _sameVariant(ProductVariantDraft? left, ProductVariantDraft right) {
  if (left == null) {
    return false;
  }

  if (left.id != null && right.id != null) {
    return left.id == right.id;
  }

  return left.name == right.name;
}

bool _isActiveVariant(
  ProductVariantDraft variant,
  List<ProductVariantDraft> activeVariants,
) {
  return activeVariants.any((active) => _sameVariant(variant, active));
}

Map<int, int> _initialToppingQuantities(VoiceOrderItem item) {
  return {
    for (final topping in item.toppings)
      if (topping.id != null) topping.id!: topping.quantity,
  };
}

String _statusTitle(VoiceOrderState state) {
  return switch (state.status) {
    VoiceOrderStatus.recording => 'Đang nghe...',
    VoiceOrderStatus.recognizing => 'Đang xử lý...',
    VoiceOrderStatus.submitting => 'Đang xác nhận...',
    VoiceOrderStatus.error ||
    VoiceOrderStatus.permissionDenied => 'Nhấn giữ mic để thử lại',
    _ => 'Nhấn giữ mic để đọc order',
  };
}

String _tableLabel(VoiceOrderRecognition? recognition) {
  final tableName = recognition?.tableName?.trim();
  if (tableName != null && tableName.isNotEmpty) {
    final normalized = tableName.toLowerCase();
    if (normalized.startsWith('phòng') || normalized.startsWith('phong')) {
      return tableName;
    }
    if (normalized.startsWith('bàn') || normalized.startsWith('ban')) {
      return tableName;
    }
    return 'Bàn $tableName';
  }

  final tableId = recognition?.tableId;
  if (tableId != null) {
    return 'Bàn $tableId';
  }

  return '';
}

String _currency(int value) {
  final text = value.toString();
  final buffer = StringBuffer();
  for (var i = 0; i < text.length; i += 1) {
    final remaining = text.length - i;
    buffer.write(text[i]);
    if (remaining > 1 && remaining % 3 == 1) {
      buffer.write('.');
    }
  }
  return '$bufferđ';
}

class _BlockedView extends StatelessWidget {
  final IconData icon;
  final String title;
  final String message;

  const _BlockedView({
    required this.icon,
    required this.title,
    required this.message,
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
              child: OutlinedButton.icon(
                onPressed: () => context.goNamed(RouteNames.myStores),
                icon: const Icon(Icons.arrow_back_rounded),
                label: const Text('Về danh sách cửa hàng'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _ErrorView({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.background,
      padding: const EdgeInsets.all(AppConstants.spacingLg),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.error_outline_rounded,
              color: AppColors.error,
              size: 44,
            ),
            const SizedBox(height: AppConstants.spacingMd),
            Text(message, style: AppTextStyles.bodySm),
            const SizedBox(height: AppConstants.spacingLg),
            ElevatedButton(onPressed: onRetry, child: const Text('Thử lại')),
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

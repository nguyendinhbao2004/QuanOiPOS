import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../../config/router_config.dart';
import '../../../../../core/constants/app_constants.dart';
import '../../../../../core/constants/app_permission_codes.dart';
import '../../../../../core/theme/index.dart';
import '../../../../workspace_context/presentation/controllers/store_access_state.dart';
import '../../../../workspace_context/presentation/providers/workspace_context_providers.dart';
import '../../../presentation/widgets/store_bottom_sheet_panel.dart';
import '../../domain/entities/voice_order_item.dart';
import '../../domain/entities/voice_order_recognition.dart';
import '../controllers/voice_order_state.dart';
import '../providers/voice_order_providers.dart';

class VoiceOrderDemoPage extends ConsumerWidget {
  final int storeId;

  const VoiceOrderDemoPage({super.key, required this.storeId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final accessState = ref.watch(storeAccessNotifierProvider(storeId));

    return Scaffold(
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
                accessState.errorMessage ?? 'Không thể tải thông tin cửa hàng',
            onRetry: () => ref
                .read(storeAccessNotifierProvider(storeId).notifier)
                .loadAccess(),
          ),
          StoreAccessStatus.ready =>
            accessState.can(AppPermissionCodes.dashboardView)
                ? _VoiceOrderDemoBody(storeId: storeId)
                : const _BlockedView(
                    icon: Icons.visibility_off_outlined,
                    title: 'Bạn chưa có quyền dùng demo order giọng nói',
                    message:
                        'Vui lòng liên hệ quản trị viên cửa hàng để được cấp quyền xem tổng quan.',
                  ),
        },
      ),
    );
  }
}

class _VoiceOrderDemoBody extends ConsumerWidget {
  final int storeId;

  const _VoiceOrderDemoBody({required this.storeId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(voiceOrderNotifierProvider);

    return ColoredBox(
      color: AppColors.background,
      child: Column(
        children: [
          _Header(storeId: storeId),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(
                AppConstants.spacingMd,
                AppConstants.spacingXl,
                AppConstants.spacingMd,
                AppConstants.spacingXxl,
              ),
              child: state.recognition == null
                  ? _MicOnlyContent(
                      state: state,
                      onMicTap: () => _openVoiceOrderSheet(context, ref),
                    )
                  : _RecognitionResult(
                      recognition: state.recognition!,
                      onRecordAgain: () => _openVoiceOrderSheet(context, ref),
                      onClear: () =>
                          ref.read(voiceOrderNotifierProvider.notifier).clear(),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _openVoiceOrderSheet(BuildContext context, WidgetRef ref) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => const _VoiceOrderBottomSheet(),
    );

    final status = ref.read(voiceOrderNotifierProvider).status;
    if (status == VoiceOrderStatus.recording ||
        status == VoiceOrderStatus.readyToSend ||
        status == VoiceOrderStatus.recognizing) {
      await ref.read(voiceOrderNotifierProvider.notifier).clear();
    }
  }
}

class _Header extends StatelessWidget {
  final int storeId;

  const _Header({required this.storeId});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppConstants.spacingMd,
        AppConstants.spacingSm,
        AppConstants.spacingMd,
        AppConstants.spacingMd,
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
          Expanded(
            child: Text(
              'Order giọng nói',
              style: AppTextStyles.h3.copyWith(fontWeight: FontWeight.w700),
              textAlign: TextAlign.center,
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

class _MicOnlyContent extends StatelessWidget {
  final VoiceOrderState state;
  final VoidCallback onMicTap;

  const _MicOnlyContent({required this.state, required this.onMicTap});

  @override
  Widget build(BuildContext context) {
    final message = state.errorMessage;

    return Column(
      children: [
        const SizedBox(height: AppConstants.spacingXxl),
        _MicHeroButton(onTap: onMicTap),
        const SizedBox(height: AppConstants.spacingLg),
        Text(
          'Chạm mic để đọc món',
          style: AppTextStyles.h3.copyWith(fontWeight: FontWeight.w700),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: AppConstants.spacingXs),
        Text(
          'Quán Ơi sẽ ghi âm, hiện text bạn đang nói và gửi AI nhận diện món.',
          style: AppTextStyles.bodySm,
          textAlign: TextAlign.center,
        ),
        if (message != null && message.isNotEmpty) ...[
          const SizedBox(height: AppConstants.spacingLg),
          _InlineMessage(
            icon: state.status == VoiceOrderStatus.permissionDenied
                ? Icons.mic_off_outlined
                : Icons.info_outline_rounded,
            message: message,
          ),
        ],
      ],
    );
  }
}

class _MicHeroButton extends StatelessWidget {
  final VoidCallback onTap;

  const _MicHeroButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.primaryLight,
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: Container(
          width: 128,
          height: 128,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
          ),
          child: Container(
            width: 88,
            height: 88,
            alignment: Alignment.center,
            decoration: const BoxDecoration(
              color: AppColors.primary,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.mic_rounded,
              color: AppColors.surface,
              size: 42,
            ),
          ),
        ),
      ),
    );
  }
}

class _VoiceOrderBottomSheet extends ConsumerStatefulWidget {
  const _VoiceOrderBottomSheet();

  @override
  ConsumerState<_VoiceOrderBottomSheet> createState() =>
      _VoiceOrderBottomSheetState();
}

class _VoiceOrderBottomSheetState
    extends ConsumerState<_VoiceOrderBottomSheet> {
  @override
  void initState() {
    super.initState();
    Future<void>.microtask(() {
      ref.read(voiceOrderNotifierProvider.notifier).startRecording();
    });
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<VoiceOrderState>(voiceOrderNotifierProvider, (previous, next) {
      if (next.status == VoiceOrderStatus.success &&
          previous?.status != VoiceOrderStatus.success &&
          Navigator.of(context).canPop()) {
        Navigator.of(context).pop();
      }
    });

    final state = ref.watch(voiceOrderNotifierProvider);
    final notifier = ref.read(voiceOrderNotifierProvider.notifier);
    final isRecording = state.status == VoiceOrderStatus.recording;
    final canSend = state.status == VoiceOrderStatus.readyToSend;
    final isRecognizing = state.status == VoiceOrderStatus.recognizing;

    return SizedBox(
      height: MediaQuery.sizeOf(context).height * 0.72,
      child: StoreBottomSheetPanel(
        title: 'Đọc order bằng giọng nói',
        child: ListView(
          padding: const EdgeInsets.fromLTRB(
            AppConstants.spacingLg,
            0,
            AppConstants.spacingLg,
            AppConstants.spacingLg,
          ),
          children: [
            _RecorderCard(isAnimating: isRecording || isRecognizing),
            const SizedBox(height: AppConstants.spacingMd),
            _LiveTranscriptCard(state: state),
            if (state.errorMessage != null &&
                state.errorMessage!.trim().isNotEmpty) ...[
              const SizedBox(height: AppConstants.spacingMd),
              _InlineMessage(
                icon: state.status == VoiceOrderStatus.permissionDenied
                    ? Icons.mic_off_outlined
                    : Icons.error_outline_rounded,
                message: state.errorMessage!,
              ),
            ],
            const SizedBox(height: AppConstants.spacingLg),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: isRecognizing
                        ? null
                        : () async {
                            await notifier.clear();
                            if (context.mounted) {
                              Navigator.of(context).pop();
                            }
                          },
                    icon: const Icon(Icons.delete_outline_rounded),
                    label: const Text('Xóa'),
                  ),
                ),
                const SizedBox(width: AppConstants.spacingSm),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: isRecognizing
                        ? null
                        : isRecording
                        ? notifier.stopRecording
                        : canSend
                        ? notifier.recognize
                        : notifier.startRecording,
                    icon: Icon(
                      isRecording
                          ? Icons.stop_rounded
                          : canSend
                          ? Icons.send_rounded
                          : Icons.mic_rounded,
                    ),
                    label: Text(
                      isRecording
                          ? 'Dừng'
                          : canSend
                          ? 'Gửi'
                          : 'Nói lại',
                    ),
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

class _LiveTranscriptCard extends StatelessWidget {
  final VoiceOrderState state;

  const _LiveTranscriptCard({required this.state});

  @override
  Widget build(BuildContext context) {
    final transcript = state.liveTranscript.trim();
    final previewMessage = state.speechPreviewMessage?.trim();
    final displayText = transcript.isEmpty ? 'Đang nghe...' : transcript;

    return _SectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.record_voice_over_outlined,
                color: AppColors.primary,
                size: 20,
              ),
              const SizedBox(width: AppConstants.spacingSm),
              Text(
                'Bạn đang nói',
                style: AppTextStyles.labelSm.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppConstants.spacingMd),
          AnimatedSwitcher(
            duration: AppConstants.animNormal,
            child: Text(
              displayText,
              key: ValueKey(displayText),
              style: transcript.isEmpty
                  ? AppTextStyles.placeholder
                  : AppTextStyles.bodyBase.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
            ),
          ),
          if (previewMessage != null &&
              previewMessage.isNotEmpty &&
              transcript.isEmpty) ...[
            const SizedBox(height: AppConstants.spacingSm),
            Text(
              previewMessage,
              style: AppTextStyles.bodyXs.copyWith(color: AppColors.warning),
            ),
          ],
        ],
      ),
    );
  }
}

class _RecognitionResult extends StatelessWidget {
  final VoiceOrderRecognition recognition;
  final VoidCallback onRecordAgain;
  final VoidCallback onClear;

  const _RecognitionResult({
    required this.recognition,
    required this.onRecordAgain,
    required this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                'Kết quả nhận diện',
                style: AppTextStyles.h4.copyWith(fontWeight: FontWeight.w700),
              ),
            ),
            IconButton(
              tooltip: 'Xóa kết quả',
              onPressed: onClear,
              icon: const Icon(Icons.close_rounded),
            ),
          ],
        ),
        const SizedBox(height: AppConstants.spacingSm),
        _SectionCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Nội dung AI nghe được',
                style: AppTextStyles.labelSm.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: AppConstants.spacingSm),
              Text(
                recognition.transcript.isEmpty
                    ? 'Chưa có transcript'
                    : recognition.transcript,
                style: AppTextStyles.bodyBase,
              ),
            ],
          ),
        ),
        const SizedBox(height: AppConstants.spacingMd),
        if (recognition.items.isEmpty)
          const _InlineMessage(
            icon: Icons.search_off_rounded,
            message: 'Chưa tìm thấy sản phẩm khớp trong đơn đọc.',
          )
        else
          _SectionCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Món đã nhận diện',
                  style: AppTextStyles.labelSm.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: AppConstants.spacingSm),
                for (final item in recognition.items) ...[
                  _RecognizedItemRow(item: item),
                  if (item != recognition.items.last)
                    const Divider(height: AppConstants.spacingLg),
                ],
              ],
            ),
          ),
        if (recognition.unmatchedItems.isNotEmpty) ...[
          const SizedBox(height: AppConstants.spacingMd),
          _SectionCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Chưa khớp sản phẩm',
                  style: AppTextStyles.labelSm.copyWith(
                    fontWeight: FontWeight.w700,
                    color: AppColors.warning,
                  ),
                ),
                const SizedBox(height: AppConstants.spacingSm),
                for (final item in recognition.unmatchedItems)
                  Padding(
                    padding: const EdgeInsets.only(
                      bottom: AppConstants.spacingSm,
                    ),
                    child: Text(
                      '${item.quantity} x ${item.rawText} - ${item.reason}',
                      style: AppTextStyles.bodySm,
                    ),
                  ),
              ],
            ),
          ),
        ],
        const SizedBox(height: AppConstants.spacingMd),
        _SectionCard(
          child: Row(
            children: [
              Expanded(
                child: Text(
                  'Tạm tính',
                  style: AppTextStyles.label.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              Text(
                _formatCurrency(recognition.estimatedTotal),
                style: AppTextStyles.h3.copyWith(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppConstants.spacingLg),
        ElevatedButton.icon(
          onPressed: onRecordAgain,
          icon: const Icon(Icons.mic_rounded),
          label: const Text('Đọc đơn mới'),
        ),
      ],
    );
  }
}

class _RecognizedItemRow extends StatelessWidget {
  final VoiceOrderItem item;

  const _RecognizedItemRow({required this.item});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 36,
          height: 36,
          alignment: Alignment.center,
          decoration: const BoxDecoration(
            color: AppColors.primaryLight,
            shape: BoxShape.circle,
          ),
          child: Text(
            '${item.quantity}',
            style: AppTextStyles.labelSm.copyWith(color: AppColors.primary),
          ),
        ),
        const SizedBox(width: AppConstants.spacingSm),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(item.productName, style: AppTextStyles.labelSm),
              const SizedBox(height: AppConstants.spacingXs),
              Text(
                '${_formatCurrency(item.unitPrice)} · Tin cậy ${(item.confidence * 100).round()}%',
                style: AppTextStyles.bodyXs,
              ),
            ],
          ),
        ),
        const SizedBox(width: AppConstants.spacingSm),
        Text(_formatCurrency(item.totalPrice), style: AppTextStyles.labelSm),
      ],
    );
  }
}

class _RecorderCard extends StatefulWidget {
  final bool isAnimating;

  const _RecorderCard({required this.isAnimating});

  @override
  State<_RecorderCard> createState() => _RecorderCardState();
}

class _RecorderCardState extends State<_RecorderCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    if (widget.isAnimating) {
      _controller.repeat(reverse: true);
    }
  }

  @override
  void didUpdateWidget(covariant _RecorderCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isAnimating && !_controller.isAnimating) {
      _controller.repeat(reverse: true);
    } else if (!widget.isAnimating && _controller.isAnimating) {
      _controller.stop();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return _SectionCard(
      child: Column(
        children: [
          AnimatedBuilder(
            animation: _controller,
            builder: (context, child) {
              return Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(27, (index) {
                  final distance = (index - 13).abs();
                  final baseHeight = 8 + (13 - distance).clamp(0, 13) * 2.2;
                  final pulse = widget.isAnimating
                      ? 1 + (_controller.value * (distance.isEven ? 0.45 : 0.2))
                      : 1.0;
                  return Container(
                    width: 4,
                    height: baseHeight * pulse,
                    margin: const EdgeInsets.symmetric(horizontal: 2),
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: BorderRadius.circular(999),
                    ),
                  );
                }),
              );
            },
          ),
          const SizedBox(height: AppConstants.spacingMd),
          Text(
            widget.isAnimating ? 'Đang nghe...' : 'Đọc tên hàng + số lượng',
            style: AppTextStyles.h4.copyWith(fontWeight: FontWeight.w600),
          ),
        ],
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
          width: 48,
          height: 48,
          child: Icon(icon, color: AppColors.textPrimary),
        ),
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  final Widget child;

  const _SectionCard({required this.child});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppConstants.spacingMd),
        child: child,
      ),
    );
  }
}

class _InlineMessage extends StatelessWidget {
  final IconData icon;
  final String message;

  const _InlineMessage({required this.icon, required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppConstants.spacingMd),
      decoration: BoxDecoration(
        color: AppColors.primaryLight,
        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Icon(icon, color: AppColors.primary),
          const SizedBox(width: AppConstants.spacingSm),
          Expanded(child: Text(message, style: AppTextStyles.bodySm)),
        ],
      ),
    );
  }
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

String _formatCurrency(int value) {
  return '${NumberFormat.decimalPattern('vi_VN').format(value)} đ';
}

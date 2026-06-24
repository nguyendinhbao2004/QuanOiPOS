import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/theme/index.dart';
import '../../../store_invitations/domain/entities/received_store_invitation.dart';
import '../../../store_invitations/presentation/providers/store_invitation_providers.dart';
import '../../../store_invitations/presentation/controllers/store_invitations_state.dart';

class StoreInvitationNotificationSheet extends ConsumerWidget {
  const StoreInvitationNotificationSheet({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(storeInvitationsNotifierProvider);

    return SafeArea(
      top: false,
      child: SizedBox(
        height: MediaQuery.sizeOf(context).height * 0.78,
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 720),
            child: Material(
              color: AppColors.surface,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(28),
              ),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppConstants.spacingMd,
                  AppConstants.spacingSm,
                  AppConstants.spacingMd,
                  AppConstants.spacingMd,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Center(
                      child: Container(
                        width: 42,
                        height: 4,
                        decoration: BoxDecoration(
                          color: AppColors.borderStrong,
                          borderRadius: BorderRadius.circular(999),
                        ),
                      ),
                    ),
                    const SizedBox(height: AppConstants.spacingMd),
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Lời mời cửa hàng', style: AppTextStyles.h3),
                              const SizedBox(height: AppConstants.spacingXs),
                              Text(
                                _subtitleText(state),
                                style: AppTextStyles.bodyXs,
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          tooltip: 'Đóng',
                          onPressed: () => Navigator.of(context).pop(),
                          icon: const Icon(Icons.close_rounded),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppConstants.spacingMd),
                    Expanded(child: _SheetBody(state: state)),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  String _subtitleText(StoreInvitationsState state) {
    if (state.pendingCount == 0) {
      return 'Hiện chưa có lời mời nào cần phản hồi';
    }

    return 'Bạn có ${state.pendingCount} lời mời đang chờ phản hồi';
  }
}

class _SheetBody extends ConsumerWidget {
  final StoreInvitationsState state;

  const _SheetBody({required this.state});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (state.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (state.status == StoreInvitationsStatus.error &&
        state.pendingInvitations.isEmpty) {
      return _InvitationFeedbackView(
        icon: Icons.error_outline_rounded,
        title: 'Không thể tải lời mời',
        message: state.errorMessage ?? 'Vui lòng thử lại sau',
        actionLabel: 'Thử lại',
        onAction: () => ref
            .read(storeInvitationsNotifierProvider.notifier)
            .loadInvitations(),
      );
    }

    if (state.pendingInvitations.isEmpty) {
      return const _InvitationFeedbackView(
        icon: Icons.notifications_none_rounded,
        title: 'Chưa có thông báo mới',
        message: 'Khi có lời mời tham gia cửa hàng, bạn sẽ thấy tại đây.',
      );
    }

    return ListView.separated(
      itemCount: state.pendingInvitations.length,
      separatorBuilder: (_, _) =>
          const SizedBox(height: AppConstants.spacingMd),
      itemBuilder: (context, index) {
        final invitation = state.pendingInvitations[index];
        return _InvitationCard(
          invitation: invitation,
          isProcessing: state.isProcessing(invitation.invitationId),
        );
      },
    );
  }
}

class _InvitationCard extends ConsumerWidget {
  final ReceivedStoreInvitation invitation;
  final bool isProcessing;

  const _InvitationCard({required this.invitation, required this.isProcessing});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Card(
      elevation: 0,
      color: AppColors.primaryLight,
      child: Padding(
        padding: const EdgeInsets.all(AppConstants.spacingMd),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Icon(
                    Icons.store_mall_directory_outlined,
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(width: AppConstants.spacingMd),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        invitation.storeName,
                        style: AppTextStyles.label.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: AppConstants.spacingXs),
                      Wrap(
                        spacing: AppConstants.spacingSm,
                        runSpacing: AppConstants.spacingSm,
                        children: [
                          _MetaChip(
                            icon: Icons.badge_outlined,
                            label: invitation.roleName,
                          ),
                          _MetaChip(
                            icon: Icons.schedule_rounded,
                            label: _formatExpiry(invitation.expiresAt),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppConstants.spacingMd),
            Text(
              'Người mời: ${invitation.inviterDisplayName}',
              style: AppTextStyles.bodySm.copyWith(
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: AppConstants.spacingXs),
            Text(
              'Email nhận lời mời: ${invitation.invitedEmail}',
              style: AppTextStyles.bodyXs.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: AppConstants.spacingMd),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    key: Key(
                      'reject_store_invitation_${invitation.invitationId}',
                    ),
                    onPressed: isProcessing
                        ? null
                        : () => _handleAction(
                            context,
                            ref,
                            () => ref
                                .read(storeInvitationsNotifierProvider.notifier)
                                .rejectInvitation(invitation.invitationId),
                          ),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.error,
                    ),
                    child: isProcessing
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text('Từ chối'),
                  ),
                ),
                const SizedBox(width: AppConstants.spacingSm),
                Expanded(
                  child: ElevatedButton(
                    key: Key(
                      'accept_store_invitation_${invitation.invitationId}',
                    ),
                    onPressed: isProcessing
                        ? null
                        : () => _handleAction(
                            context,
                            ref,
                            () => ref
                                .read(storeInvitationsNotifierProvider.notifier)
                                .acceptInvitation(invitation.invitationId),
                          ),
                    child: isProcessing
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: AppColors.surface,
                            ),
                          )
                        : const Text('Chấp nhận'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _handleAction(
    BuildContext context,
    WidgetRef ref,
    Future<String> Function() action,
  ) async {
    try {
      final message = await action();
      if (!context.mounted) {
        return;
      }

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(message)));
    } catch (error) {
      if (!context.mounted) {
        return;
      }

      final message = error.toString().replaceFirst('Exception: ', '');
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(message)));
    }
  }

  String _formatExpiry(DateTime? value) {
    if (value == null) {
      return 'Không rõ hạn';
    }

    return 'Hết hạn ${DateFormat('dd/MM/yyyy HH:mm').format(value.toLocal())}';
  }
}

class _MetaChip extends StatelessWidget {
  final IconData icon;
  final String label;

  const _MetaChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppConstants.spacingSm,
        vertical: AppConstants.spacingXs,
      ),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: AppColors.primary),
          const SizedBox(width: AppConstants.spacingXs),
          Text(
            label,
            style: AppTextStyles.bodyXs.copyWith(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _InvitationFeedbackView extends StatelessWidget {
  final IconData icon;
  final String title;
  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;

  const _InvitationFeedbackView({
    required this.icon,
    required this.title,
    required this.message,
    this.actionLabel,
    this.onAction,
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
            if (actionLabel != null && onAction != null) ...[
              const SizedBox(height: AppConstants.spacingMd),
              SizedBox(
                width: 180,
                child: ElevatedButton(
                  onPressed: onAction,
                  child: Text(actionLabel!),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

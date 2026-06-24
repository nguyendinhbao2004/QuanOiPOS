import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../config/router_config.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/theme/index.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../../store_invitations/presentation/providers/store_invitation_providers.dart';
import '../widgets/account_hub_header.dart';
import '../widgets/account_hub_menu_section.dart';
import '../widgets/logout_action_button.dart';
import '../widgets/store_invitation_notification_sheet.dart';
import '../widgets/system_shell_scaffold.dart';
import '../widgets/user_profile_card.dart';

enum _AccountHubState { loading, ready, error }

class StoreHomePage extends ConsumerStatefulWidget {
  const StoreHomePage({super.key});

  @override
  ConsumerState<StoreHomePage> createState() => _StoreHomePageState();
}

class _StoreHomePageState extends ConsumerState<StoreHomePage> {
  _AccountHubState _state = _AccountHubState.loading;

  @override
  void initState() {
    super.initState();
    _bootstrapAccountHub();
  }

  Future<void> _bootstrapAccountHub() async {
    setState(() => _state = _AccountHubState.loading);
    await Future<void>.delayed(const Duration(milliseconds: 400));
    if (!mounted) {
      return;
    }

    setState(() => _state = _AccountHubState.ready);
  }

  void _onStoreMenuTap(BuildContext context) {
    context.pushNamed(RouteNames.myStores);
  }

  Future<void> _openNotifications(BuildContext context) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const StoreInvitationNotificationSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authNotifierProvider);
    final invitationsState = ref.watch(storeInvitationsNotifierProvider);
    final fullName = authState.fullName ?? 'Store User';
    final email = authState.email ?? '';

    return SystemShellScaffold(
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            AccountHubHeader(
              greeting: 'Xin chào, $fullName',
              notificationCount: invitationsState.pendingCount,
              onNotificationTap: () => _openNotifications(context),
            ),
            Expanded(
              child: Container(
                color: AppColors.background,
                padding: const EdgeInsets.all(AppConstants.spacingMd),
                child: switch (_state) {
                  _AccountHubState.loading => const _LoadingStateView(),
                  _AccountHubState.error => _ErrorStateView(
                    onRetry: _bootstrapAccountHub,
                  ),
                  _AccountHubState.ready => _ReadyStateView(
                    fullName: fullName,
                    email: email,
                    onProfileTap: () => context.pushNamed(RouteNames.profile),
                    onStoreTap: () => _onStoreMenuTap(context),
                    onAppSettingsTap: () =>
                        context.pushNamed(RouteNames.appSettings),
                    onLogout: () =>
                        ref.read(authNotifierProvider.notifier).logout(),
                  ),
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LoadingStateView extends StatelessWidget {
  const _LoadingStateView();

  @override
  Widget build(BuildContext context) {
    return const Center(child: CircularProgressIndicator());
  }
}

class _ErrorStateView extends StatelessWidget {
  final VoidCallback onRetry;

  const _ErrorStateView({required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Không thể tải thông tin tài khoản',
            style: AppTextStyles.bodySm,
          ),
          const SizedBox(height: AppConstants.spacingSm),
          SizedBox(
            width: 180,
            child: ElevatedButton(
              onPressed: onRetry,
              child: const Text('Thử lại'),
            ),
          ),
        ],
      ),
    );
  }
}

class _ReadyStateView extends StatelessWidget {
  final String fullName;
  final String email;
  final VoidCallback onProfileTap;
  final VoidCallback onStoreTap;
  final VoidCallback onAppSettingsTap;
  final VoidCallback onLogout;

  const _ReadyStateView({
    required this.fullName,
    required this.email,
    required this.onProfileTap,
    required this.onStoreTap,
    required this.onAppSettingsTap,
    required this.onLogout,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          UserProfileCard(
            fullName: fullName,
            email: email,
            onTap: onProfileTap,
          ),
          const SizedBox(height: AppConstants.spacingMd),
          AccountHubMenuSection(
            onSubscriptionTap: () =>
                context.pushNamed(RouteNames.storeSubscription),
            onStoresTap: onStoreTap,
            onChangePasswordTap: () =>
                context.pushNamed(RouteNames.changePassword),
            onAppSettingsTap: onAppSettingsTap,
          ),
          const SizedBox(height: AppConstants.spacingMd),
          LogoutActionButton(onPressed: onLogout),
        ],
      ),
    );
  }
}

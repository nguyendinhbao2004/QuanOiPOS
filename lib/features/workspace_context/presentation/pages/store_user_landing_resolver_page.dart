import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../config/router_config.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/constants/app_permission_codes.dart';
import '../../../../core/theme/index.dart';
import '../controllers/last_active_store_state.dart';
import '../controllers/store_access_state.dart';
import '../providers/workspace_context_providers.dart';

class StoreUserLandingResolverPage extends ConsumerWidget {
  const StoreUserLandingResolverPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lastActiveStoreState = ref.watch(lastActiveStoreNotifierProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: switch (lastActiveStoreState.status) {
          LastActiveStoreStatus.bootstrapping => const _LoadingView(),
          LastActiveStoreStatus.error => _ResolverMessageView(
            icon: Icons.error_outline_rounded,
            title: 'Không thể mở cửa hàng gần nhất',
            message:
                lastActiveStoreState.errorMessage ??
                'Vui lòng thử lại hoặc chọn cửa hàng từ danh sách.',
            primaryLabel: 'Thử lại',
            onPrimary: () =>
                ref.read(lastActiveStoreNotifierProvider.notifier).load(),
            secondaryLabel: 'Về danh sách cửa hàng',
            onSecondary: () => context.goNamed(RouteNames.myStores),
          ),
          LastActiveStoreStatus.ready =>
            lastActiveStoreState.lastStoreId == null
                ? _RouteEffect(
                    onRoute: () => context.goNamed(RouteNames.storeHome),
                  )
                : _StoreAccessResolver(
                    storeId: lastActiveStoreState.lastStoreId!,
                  ),
        },
      ),
    );
  }
}

class _StoreAccessResolver extends ConsumerWidget {
  final int storeId;

  const _StoreAccessResolver({required this.storeId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final accessState = ref.watch(storeAccessNotifierProvider(storeId));

    return switch (accessState.status) {
      StoreAccessStatus.initial ||
      StoreAccessStatus.loading => const _LoadingView(),
      StoreAccessStatus.ready => _RouteEffect(
        onRoute: () => context.goNamed(
          accessState.can(AppPermissionCodes.kitchenAll)
              ? RouteNames.storeKitchen
              : RouteNames.storeOverview,
          pathParameters: {'storeId': storeId.toString()},
        ),
      ),
      StoreAccessStatus.forbidden => _ResolverMessageView(
        icon: Icons.lock_outline_rounded,
        title: 'Không có quyền truy cập',
        message:
            accessState.errorMessage ??
            'Tài khoản của bạn không có quyền truy cập cửa hàng này.',
        primaryLabel: 'Thử lại',
        onPrimary: () => ref
            .read(storeAccessNotifierProvider(storeId).notifier)
            .loadAccess(),
        secondaryLabel: 'Về danh sách cửa hàng',
        onSecondary: () => context.goNamed(RouteNames.myStores),
      ),
      StoreAccessStatus.error => _ResolverMessageView(
        icon: Icons.error_outline_rounded,
        title: 'Không thể mở cửa hàng',
        message:
            accessState.errorMessage ??
            'Không thể tải quyền truy cập của cửa hàng.',
        primaryLabel: 'Thử lại',
        onPrimary: () => ref
            .read(storeAccessNotifierProvider(storeId).notifier)
            .loadAccess(),
        secondaryLabel: 'Về danh sách cửa hàng',
        onSecondary: () => context.goNamed(RouteNames.myStores),
      ),
    };
  }
}

class _RouteEffect extends StatefulWidget {
  final VoidCallback onRoute;

  const _RouteEffect({required this.onRoute});

  @override
  State<_RouteEffect> createState() => _RouteEffectState();
}

class _RouteEffectState extends State<_RouteEffect> {
  bool _scheduled = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _scheduleRoute();
  }

  @override
  void didUpdateWidget(covariant _RouteEffect oldWidget) {
    super.didUpdateWidget(oldWidget);
    _scheduleRoute();
  }

  void _scheduleRoute() {
    if (_scheduled) return;

    _scheduled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      widget.onRoute();
    });
  }

  @override
  Widget build(BuildContext context) {
    return const _LoadingView();
  }
}

class _ResolverMessageView extends StatelessWidget {
  final IconData icon;
  final String title;
  final String message;
  final String primaryLabel;
  final VoidCallback onPrimary;
  final String secondaryLabel;
  final VoidCallback onSecondary;

  const _ResolverMessageView({
    required this.icon,
    required this.title,
    required this.message,
    required this.primaryLabel,
    required this.onPrimary,
    required this.secondaryLabel,
    required this.onSecondary,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppConstants.spacingLg),
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
              width: 180,
              child: ElevatedButton(
                onPressed: onPrimary,
                child: Text(primaryLabel),
              ),
            ),
            const SizedBox(height: AppConstants.spacingSm),
            SizedBox(
              width: 220,
              child: OutlinedButton.icon(
                onPressed: onSecondary,
                icon: const Icon(Icons.arrow_back_rounded),
                label: Text(secondaryLabel),
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
    return const Center(child: CircularProgressIndicator());
  }
}

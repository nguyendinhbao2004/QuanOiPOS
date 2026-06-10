import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../config/router_config.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/theme/index.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../../workspace_context/domain/entities/store.dart';
import '../../../workspace_context/presentation/controllers/my_stores_state.dart';
import '../../../workspace_context/presentation/providers/workspace_context_providers.dart';
import 'account_hub_menu_section.dart';
import 'logout_action_button.dart';

class StoreWorkspaceDrawer extends ConsumerWidget {
  final int activeStoreId;

  const StoreWorkspaceDrawer({super.key, required this.activeStoreId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final drawerWidth = math.min(
      MediaQuery.sizeOf(context).width * 0.92,
      430.0,
    );
    final authState = ref.watch(authNotifierProvider);
    final storesState = ref.watch(myStoresNotifierProvider);
    final fullName = authState.fullName?.trim().isNotEmpty == true
        ? authState.fullName!.trim()
        : 'Store User';
    final contact = authState.phone?.trim().isNotEmpty == true
        ? authState.phone!.trim()
        : (authState.email?.trim() ?? '');

    return Drawer(
      key: const Key('store_workspace_drawer'),
      width: drawerWidth,
      backgroundColor: AppColors.surface,
      child: SafeArea(
        child: Row(
          children: [
            _StoreRail(
              state: storesState,
              activeStoreId: activeStoreId,
              onSelectStore: (store) => _selectStore(context, ref, store),
              onAddStore: () => _closeAndPush(context, RouteNames.myStores),
            ),
            const VerticalDivider(width: 1, color: AppColors.border),
            Expanded(
              child: _DrawerMenuPanel(
                fullName: fullName,
                contact: contact,
                onSubscriptionTap: () =>
                    _closeAndPush(context, RouteNames.storeSubscription),
                onStoresTap: () => _closeAndPush(context, RouteNames.myStores),
                onChangePasswordTap: () =>
                    _closeAndPush(context, RouteNames.changePassword),
                onAppSettingsTap: () =>
                    _closeAndPush(context, RouteNames.appSettings),
                onLogout: () => _logout(context, ref),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _selectStore(
    BuildContext context,
    WidgetRef ref,
    Store store,
  ) async {
    final navigator = Navigator.of(context);
    final router = GoRouter.maybeOf(context);

    navigator.pop();
    if (store.id == activeStoreId || !store.status.canAccess) {
      return;
    }

    try {
      await ref.read(lastActiveStoreNotifierProvider.notifier).save(store.id);
    } catch (_) {
      // Last-store persistence should not block switching stores.
    }

    router?.goNamed(
      RouteNames.storeOverview,
      pathParameters: {'storeId': store.id.toString()},
    );
  }

  void _closeAndPush(BuildContext context, String routeName) {
    final navigator = Navigator.of(context);
    final router = GoRouter.maybeOf(context);

    navigator.pop();
    router?.pushNamed(routeName);
  }

  void _logout(BuildContext context, WidgetRef ref) {
    Navigator.of(context).pop();
    ref.read(authNotifierProvider.notifier).logout();
  }
}

class _StoreRail extends StatelessWidget {
  final MyStoresState state;
  final int activeStoreId;
  final ValueChanged<Store> onSelectStore;
  final VoidCallback onAddStore;

  const _StoreRail({
    required this.state,
    required this.activeStoreId,
    required this.onSelectStore,
    required this.onAddStore,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 96,
      child: Column(
        children: [
          const SizedBox(height: AppConstants.spacingMd),
          Expanded(
            child: switch (state.status) {
              MyStoresStatus.initial || MyStoresStatus.loading
                  when state.stores.isEmpty =>
                const Center(child: CircularProgressIndicator(strokeWidth: 2)),
              MyStoresStatus.error when state.stores.isEmpty => IconButton(
                tooltip: 'Tải lại cửa hàng',
                onPressed: null,
                icon: const Icon(
                  Icons.error_outline_rounded,
                  color: AppColors.error,
                ),
              ),
              _ => ListView.separated(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppConstants.spacingSm,
                ),
                itemBuilder: (context, index) {
                  final store = state.stores[index];
                  return _StoreRailItem(
                    store: store,
                    isActive: store.id == activeStoreId,
                    onTap: store.status.canAccess
                        ? () => onSelectStore(store)
                        : null,
                  );
                },
                separatorBuilder: (context, index) =>
                    const SizedBox(height: AppConstants.spacingMd),
                itemCount: state.stores.length,
              ),
            },
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppConstants.spacingSm,
              AppConstants.spacingSm,
              AppConstants.spacingSm,
              AppConstants.spacingMd,
            ),
            child: _AddStoreButton(onTap: onAddStore),
          ),
        ],
      ),
    );
  }
}

class _StoreRailItem extends StatelessWidget {
  final Store store;
  final bool isActive;
  final VoidCallback? onTap;

  const _StoreRailItem({
    required this.store,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isEnabled = onTap != null;
    final foregroundColor = isActive ? AppColors.primary : AppColors.textMuted;

    return Opacity(
      opacity: isEnabled ? 1 : 0.52,
      child: InkWell(
        key: Key('switch_store_${store.id}'),
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppTheme.radiusXl),
        child: Column(
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: isActive ? AppColors.primaryLight : AppColors.muted,
                shape: BoxShape.circle,
                border: Border.all(
                  color: isActive ? AppColors.primary : AppColors.border,
                  width: isActive ? 2 : 1,
                ),
              ),
              child: Icon(
                Icons.storefront_rounded,
                color: foregroundColor,
                size: 30,
              ),
            ),
            const SizedBox(height: AppConstants.spacingXs),
            Text(
              store.storeName.isEmpty ? 'Cửa hàng' : store.storeName,
              style: AppTextStyles.bodyXs.copyWith(
                color: foregroundColor,
                fontWeight: isActive ? FontWeight.w700 : FontWeight.w600,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _AddStoreButton extends StatelessWidget {
  final VoidCallback onTap;

  const _AddStoreButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      key: const Key('store_workspace_drawer_add_store_button'),
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppTheme.radiusXl),
      child: Column(
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: AppColors.surface,
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.primary, width: 2),
            ),
            child: const Icon(
              Icons.add_rounded,
              color: AppColors.primary,
              size: 32,
            ),
          ),
          const SizedBox(height: AppConstants.spacingXs),
          Text(
            'Thêm',
            style: AppTextStyles.bodyXs.copyWith(
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _DrawerMenuPanel extends StatelessWidget {
  final String fullName;
  final String contact;
  final VoidCallback onSubscriptionTap;
  final VoidCallback onStoresTap;
  final VoidCallback onChangePasswordTap;
  final VoidCallback onAppSettingsTap;
  final VoidCallback onLogout;

  const _DrawerMenuPanel({
    required this.fullName,
    required this.contact,
    required this.onSubscriptionTap,
    required this.onStoresTap,
    required this.onChangePasswordTap,
    required this.onAppSettingsTap,
    required this.onLogout,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          padding: const EdgeInsets.all(AppConstants.spacingLg),
          decoration: const BoxDecoration(
            color: AppColors.primaryLight,
            border: Border(bottom: BorderSide(color: AppColors.border)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Image.asset(
                AppConstants.logoAsset,
                width: 48,
                height: 48,
                fit: BoxFit.contain,
              ),
              const SizedBox(height: AppConstants.spacingMd),
              Text(
                fullName,
                style: AppTextStyles.h3.copyWith(fontWeight: FontWeight.w700),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              if (contact.isNotEmpty)
                Text(
                  contact,
                  style: AppTextStyles.bodySm,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
            ],
          ),
        ),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(AppConstants.spacingMd),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                AccountHubMenuSection(
                  onSubscriptionTap: onSubscriptionTap,
                  onStoresTap: onStoresTap,
                  onChangePasswordTap: onChangePasswordTap,
                  onAppSettingsTap: onAppSettingsTap,
                ),
                const SizedBox(height: AppConstants.spacingMd),
                LogoutActionButton(onPressed: onLogout),
              ],
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(AppConstants.spacingMd),
          child: Text(
            'Phiên bản hiện tại: ${AppConstants.appVersion}',
            style: AppTextStyles.bodySm.copyWith(color: AppColors.textMuted),
            textAlign: TextAlign.center,
          ),
        ),
      ],
    );
  }
}

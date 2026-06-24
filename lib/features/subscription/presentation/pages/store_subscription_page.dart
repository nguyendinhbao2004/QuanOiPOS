import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/theme/index.dart';
import '../../domain/entities/active_subscription.dart';
import '../../domain/entities/pending_subscription_purchase.dart';
import '../../domain/entities/service_package.dart';
import '../controllers/subscription_state.dart';
import '../providers/subscription_providers.dart';

class StoreSubscriptionPage extends ConsumerStatefulWidget {
  const StoreSubscriptionPage({super.key});

  @override
  ConsumerState<StoreSubscriptionPage> createState() =>
      _StoreSubscriptionPageState();
}

class _StoreSubscriptionPageState extends ConsumerState<StoreSubscriptionPage>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      final subscriptionState = ref.read(subscriptionNotifierProvider);
      if (subscriptionState.pendingPurchase != null) {
        unawaited(
          ref
              .read(subscriptionNotifierProvider.notifier)
              .refreshAfterPaymentReturn(),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(subscriptionNotifierProvider);

    ref.listen(subscriptionNotifierProvider, (previous, next) {
      final checkoutUrl = next.checkoutUrl;
      if (checkoutUrl != null && checkoutUrl != previous?.checkoutUrl) {
        unawaited(context.push('/subscription-checkout', extra: checkoutUrl));
        ref.read(subscriptionNotifierProvider.notifier).markCheckoutOpened();
      }

      final errorMessage = next.errorMessage;
      if (errorMessage != null && errorMessage != previous?.errorMessage) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(errorMessage)));
      }
    });

    return Scaffold(
      appBar: AppBar(title: const Text('Gói dịch vụ của tôi')),
      body: SafeArea(
        child: Container(
          color: AppColors.background,
          child: switch (state.status) {
            SubscriptionStatus.initial || SubscriptionStatus.loading
                when state.plans.isEmpty =>
              const _LoadingView(),
            SubscriptionStatus.error when state.plans.isEmpty => _ErrorView(
              message: state.errorMessage ?? 'Không thể tải gói dịch vụ',
              onRetry: () =>
                  ref.read(subscriptionNotifierProvider.notifier).loadPlans(),
            ),
            _ => _SubscriptionContent(
              state: state,
              onRetry: () =>
                  ref.read(subscriptionNotifierProvider.notifier).loadPlans(),
              onPurchase: (plan) => ref
                  .read(subscriptionNotifierProvider.notifier)
                  .purchasePlan(plan),
              onContinuePayment: () => ref
                  .read(subscriptionNotifierProvider.notifier)
                  .continuePendingPayment(),
              onCancelPendingPayment: () => ref
                  .read(subscriptionNotifierProvider.notifier)
                  .cancelPendingPayment(),
            ),
          },
        ),
      ),
    );
  }
}

class _SubscriptionContent extends StatelessWidget {
  static const double _desktopBreakpoint = 900;
  static const double _largeDesktopBreakpoint = 1400;
  static const double _mobileCarouselHeight = 560;
  static const double _desktopPageMaxWidth = 1480;

  final SubscriptionState state;
  final Future<void> Function() onRetry;
  final Future<void> Function(ServicePackage plan) onPurchase;
  final VoidCallback onContinuePayment;
  final Future<void> Function() onCancelPendingPayment;

  const _SubscriptionContent({
    required this.state,
    required this.onRetry,
    required this.onPurchase,
    required this.onContinuePayment,
    required this.onCancelPendingPayment,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isDesktop = constraints.maxWidth >= _desktopBreakpoint;

        return ListView(
          padding: EdgeInsets.all(
            isDesktop ? AppConstants.spacingLg : AppConstants.spacingMd,
          ),
          children: [
            Center(
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  maxWidth: isDesktop ? _desktopPageMaxWidth : double.infinity,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (state.pendingPurchase != null) ...[
                      _PendingPaymentCard(
                        pendingPurchase: state.pendingPurchase!,
                        onContinuePayment: onContinuePayment,
                        onCancelPendingPayment: onCancelPendingPayment,
                      ),
                      const SizedBox(height: AppConstants.spacingLg),
                    ],
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            'Gói dịch vụ hệ thống',
                            style: AppTextStyles.h3,
                          ),
                        ),
                        IconButton(
                          tooltip: 'Tải lại',
                          onPressed: onRetry,
                          icon: const Icon(Icons.refresh_outlined),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppConstants.spacingMd),
                    if (state.plans.isEmpty)
                      const SizedBox(
                        height: 260,
                        child: Center(child: _EmptyPackagesView()),
                      )
                    else
                      _ResponsiveSubscriptionPlans(
                        maxWidth: constraints.maxWidth,
                        desktopBreakpoint: _desktopBreakpoint,
                        largeDesktopBreakpoint: _largeDesktopBreakpoint,
                        mobileCarouselHeight: _mobileCarouselHeight,
                        plans: state.plans,
                        activeSubscription: state.activeSubscription,
                        status: state.status,
                        purchasingPlanId: state.purchasingPlanId,
                        onPurchase: onPurchase,
                      ),
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _ResponsiveSubscriptionPlans extends StatelessWidget {
  final double maxWidth;
  final double desktopBreakpoint;
  final double largeDesktopBreakpoint;
  final double mobileCarouselHeight;
  final List<ServicePackage> plans;
  final ActiveSubscription? activeSubscription;
  final SubscriptionStatus status;
  final String? purchasingPlanId;
  final Future<void> Function(ServicePackage plan) onPurchase;

  const _ResponsiveSubscriptionPlans({
    required this.maxWidth,
    required this.desktopBreakpoint,
    required this.largeDesktopBreakpoint,
    required this.mobileCarouselHeight,
    required this.plans,
    required this.activeSubscription,
    required this.status,
    required this.purchasingPlanId,
    required this.onPurchase,
  });

  @override
  Widget build(BuildContext context) {
    if (maxWidth < desktopBreakpoint) {
      return SizedBox(
        height: mobileCarouselHeight,
        child: _SubscriptionPlanCarousel(
          plans: plans,
          activeSubscription: activeSubscription,
          status: status,
          purchasingPlanId: purchasingPlanId,
          onPurchase: onPurchase,
        ),
      );
    }

    final columns = maxWidth >= largeDesktopBreakpoint ? 3 : 2;
    return _SubscriptionPlanGrid(
      columns: columns,
      plans: plans,
      activeSubscription: activeSubscription,
      status: status,
      purchasingPlanId: purchasingPlanId,
      onPurchase: onPurchase,
    );
  }
}

class _SubscriptionPlanCarousel extends StatefulWidget {
  final List<ServicePackage> plans;
  final ActiveSubscription? activeSubscription;
  final SubscriptionStatus status;
  final String? purchasingPlanId;
  final Future<void> Function(ServicePackage plan) onPurchase;

  const _SubscriptionPlanCarousel({
    required this.plans,
    required this.activeSubscription,
    required this.status,
    required this.purchasingPlanId,
    required this.onPurchase,
  });

  @override
  State<_SubscriptionPlanCarousel> createState() =>
      _SubscriptionPlanCarouselState();
}

class _SubscriptionPlanCarouselState extends State<_SubscriptionPlanCarousel> {
  late final PageController _pageController;
  int _currentPage = 0;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(viewportFraction: 0.9);
  }

  @override
  void didUpdateWidget(covariant _SubscriptionPlanCarousel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (_currentPage >= widget.plans.length) {
      _currentPage = 0;
      if (_pageController.hasClients) {
        _pageController.jumpToPage(0);
      }
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: PageView.builder(
            key: const Key('subscription_plan_page_view'),
            controller: _pageController,
            itemCount: widget.plans.length,
            onPageChanged: (index) => setState(() => _currentPage = index),
            itemBuilder: (context, index) {
              return Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppConstants.spacingXs,
                ),
                child: _ServicePackageCard(
                  package: widget.plans[index],
                  activeSubscription: widget.activeSubscription,
                  status: widget.status,
                  purchasingPlanId: widget.purchasingPlanId,
                  onPurchase: widget.onPurchase,
                ),
              );
            },
          ),
        ),
        const SizedBox(height: AppConstants.spacingMd),
        _CarouselIndicator(
          itemCount: widget.plans.length,
          currentIndex: _currentPage,
        ),
      ],
    );
  }
}

class _SubscriptionPlanGrid extends StatelessWidget {
  final int columns;
  final List<ServicePackage> plans;
  final ActiveSubscription? activeSubscription;
  final SubscriptionStatus status;
  final String? purchasingPlanId;
  final Future<void> Function(ServicePackage plan) onPurchase;

  const _SubscriptionPlanGrid({
    required this.columns,
    required this.plans,
    required this.activeSubscription,
    required this.status,
    required this.purchasingPlanId,
    required this.onPurchase,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final spacing = AppConstants.spacingMd;
        final itemWidth =
            (constraints.maxWidth - spacing * (columns - 1)) / columns;

        return Wrap(
          key: const Key('subscription_plan_grid'),
          spacing: spacing,
          runSpacing: spacing,
          children: [
            for (final plan in plans)
              SizedBox(
                width: itemWidth,
                child: _ServicePackageCard(
                  package: plan,
                  activeSubscription: activeSubscription,
                  status: status,
                  purchasingPlanId: purchasingPlanId,
                  onPurchase: onPurchase,
                ),
              ),
          ],
        );
      },
    );
  }
}

class _CarouselIndicator extends StatelessWidget {
  final int itemCount;
  final int currentIndex;

  const _CarouselIndicator({
    required this.itemCount,
    required this.currentIndex,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(itemCount, (index) {
        final isActive = index == currentIndex;

        return AnimatedContainer(
          duration: AppConstants.animFast,
          width: isActive ? 22 : 8,
          height: 8,
          margin: const EdgeInsets.symmetric(
            horizontal: AppConstants.spacingXs,
          ),
          decoration: BoxDecoration(
            color: isActive ? AppColors.primary : AppColors.borderStrong,
            borderRadius: BorderRadius.circular(AppConstants.spacingSm),
          ),
        );
      }),
    );
  }
}

class _ServicePackageCard extends StatefulWidget {
  final ServicePackage package;
  final ActiveSubscription? activeSubscription;
  final SubscriptionStatus status;
  final String? purchasingPlanId;
  final Future<void> Function(ServicePackage plan) onPurchase;

  const _ServicePackageCard({
    required this.package,
    required this.activeSubscription,
    required this.status,
    required this.purchasingPlanId,
    required this.onPurchase,
  });

  @override
  State<_ServicePackageCard> createState() => _ServicePackageCardState();
}

class _ServicePackageCardState extends State<_ServicePackageCard> {
  static const _collapsedFeatureCount = 4;

  bool _showAllFeatures = false;

  ServicePackage get package => widget.package;

  bool get isCurrentPlan {
    return widget.activeSubscription?.planId.toString() == package.id;
  }

  bool get isCurrentActivePlan {
    final subscription = widget.activeSubscription;
    return subscription != null &&
        subscription.planId.toString() == package.id &&
        subscription.isActive &&
        !subscription.isExpired &&
        subscription.status == 'Active';
  }

  bool get hasDifferentActivePlan {
    final subscription = widget.activeSubscription;
    return subscription != null &&
        subscription.isActive &&
        !subscription.isExpired &&
        !subscription.isTrial &&
        !isCurrentPlan;
  }

  bool get isPurchasing {
    return widget.status == SubscriptionStatus.purchasing &&
        widget.purchasingPlanId == package.id;
  }

  @override
  Widget build(BuildContext context) {
    final visibleFeatures =
        _showAllFeatures || package.features.length <= _collapsedFeatureCount
        ? package.features
        : package.features.take(_collapsedFeatureCount).toList();
    final canToggleFeatures = package.features.length > _collapsedFeatureCount;

    return Card(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(AppConstants.spacingLg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Text(
                    package.name,
                    style: AppTextStyles.h1.copyWith(
                      fontWeight: FontWeight.w700,
                      height: 1.2,
                    ),
                  ),
                ),
                const SizedBox(width: AppConstants.spacingSm),
                _PlanBadge(
                  package: package,
                  isCurrentActivePlan: isCurrentActivePlan,
                ),
              ],
            ),
            const SizedBox(height: AppConstants.spacingLg),
            Center(
              child: Text.rich(
                TextSpan(
                  text: _priceLabel(package),
                  style: AppTextStyles.h1.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w700,
                    height: 1.2,
                  ),
                  children: [
                    TextSpan(
                      text: _periodLabel(package),
                      style: AppTextStyles.bodySm.copyWith(
                        color: AppColors.textMuted,
                      ),
                    ),
                  ],
                ),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: AppConstants.spacingLg),
            const Divider(height: 1),
            const SizedBox(height: AppConstants.spacingLg),
            Row(
              children: [
                Expanded(
                  child: _PlanLimitTile(
                    icon: Icons.storefront_outlined,
                    label: _limitLabel(package.maxStores, 'cửa hàng'),
                    helper: 'Cửa hàng',
                  ),
                ),
                const SizedBox(width: AppConstants.spacingMd),
                Expanded(
                  child: _PlanLimitTile(
                    icon: Icons.groups_outlined,
                    label: _limitLabel(package.maxUsers, 'người dùng'),
                    helper: 'Người dùng',
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppConstants.spacingLg),
            const Divider(height: 1),
            if (package.features.isNotEmpty) ...[
              const SizedBox(height: AppConstants.spacingLg),
              ...visibleFeatures.map(
                (feature) => Padding(
                  padding: const EdgeInsets.only(
                    bottom: AppConstants.spacingMd,
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 22,
                        height: 22,
                        margin: const EdgeInsets.only(top: 1),
                        decoration: const BoxDecoration(
                          color: AppColors.primary,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.check,
                          size: 15,
                          color: AppColors.surface,
                        ),
                      ),
                      const SizedBox(width: AppConstants.spacingSm),
                      Expanded(
                        child: Text(
                          feature,
                          style: AppTextStyles.bodyBase.copyWith(
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              if (canToggleFeatures)
                Align(
                  alignment: Alignment.centerLeft,
                  child: TextButton(
                    onPressed: () =>
                        setState(() => _showAllFeatures = !_showAllFeatures),
                    child: Text(_showAllFeatures ? 'Thu gọn' : 'Xem thêm'),
                  ),
                ),
            ],
            const SizedBox(height: AppConstants.spacingLg),
            if (isCurrentPlan)
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: null,
                  icon: const Icon(Icons.check_circle_outline),
                  label: const Text('Gói hiện tại'),
                ),
              )
            else
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed:
                      package.isActive &&
                          !hasDifferentActivePlan &&
                          !isPurchasing
                      ? () => widget.onPurchase(package)
                      : null,
                  child: isPurchasing
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Text(
                          hasDifferentActivePlan
                              ? 'ĐANG CÓ GÓI KHÁC'
                              : 'MUA GÓI',
                        ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  static String _priceLabel(ServicePackage package) {
    if (package.priceAmount <= 0) {
      return 'Miễn phí';
    }

    return NumberFormat.currency(
      locale: 'vi_VN',
      symbol: 'đ',
      decimalDigits: 0,
    ).format(package.priceAmount);
  }

  static String _periodLabel(ServicePackage package) {
    if (package.priceAmount <= 0) {
      return '';
    }

    if (package.durationDays == 30) {
      return '/tháng';
    }

    return '/${package.durationDays} ngày';
  }

  static String _limitLabel(int value, String unit) {
    if (value >= 999) {
      return 'Không giới hạn $unit';
    }

    return '$value $unit';
  }
}

class _PendingPaymentCard extends StatelessWidget {
  final PendingSubscriptionPurchase pendingPurchase;
  final VoidCallback onContinuePayment;
  final Future<void> Function() onCancelPendingPayment;

  const _PendingPaymentCard({
    required this.pendingPurchase,
    required this.onContinuePayment,
    required this.onCancelPendingPayment,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppConstants.spacingLg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _StatusChip(label: 'ĐANG CHỜ THANH TOÁN', color: AppColors.warning),
            const SizedBox(height: AppConstants.spacingMd),
            Text(
              pendingPurchase.planName,
              style: AppTextStyles.h3.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: AppConstants.spacingSm),
            _InlineInfo(
              icon: Icons.receipt_long_outlined,
              text: 'Mã đơn: ${pendingPurchase.orderCode}',
            ),
            const SizedBox(height: AppConstants.spacingXs),
            _InlineInfo(
              icon: Icons.payments_outlined,
              text: _priceLabel(pendingPurchase.amount),
            ),
            if (pendingPurchase.paymentExpiresAt != null) ...[
              const SizedBox(height: AppConstants.spacingXs),
              _InlineInfo(
                icon: Icons.timer_outlined,
                text:
                    'Link thanh toán hết hạn: ${DateFormat('dd/MM/yyyy HH:mm').format(pendingPurchase.paymentExpiresAt!.toLocal())}',
              ),
            ],
            const SizedBox(height: AppConstants.spacingLg),
            if (!pendingPurchase.canResumePayment)
              Padding(
                padding: const EdgeInsets.only(bottom: AppConstants.spacingMd),
                child: Text(
                  'Link thanh toán không còn khả dụng. Hãy hủy giao dịch rồi mua lại.',
                  style: AppTextStyles.bodySm.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed:
                    pendingPurchase.paymentLink.isEmpty ||
                        !pendingPurchase.canResumePayment
                    ? null
                    : onContinuePayment,
                icon: const Icon(Icons.payment_outlined),
                label: const Text('Tiếp tục'),
              ),
            ),
            if (pendingPurchase.canCancel) ...[
              const SizedBox(height: AppConstants.spacingSm),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: onCancelPendingPayment,
                  icon: const Icon(Icons.cancel_outlined),
                  label: const Text('Hủy giao dịch'),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  static String _priceLabel(double price) {
    return NumberFormat.currency(
      locale: 'vi_VN',
      symbol: 'đ',
      decimalDigits: 0,
    ).format(price);
  }
}

class _PlanLimitTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String helper;

  const _PlanLimitTile({
    required this.icon,
    required this.label,
    required this.helper,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppConstants.spacingMd),
      decoration: BoxDecoration(
        color: AppColors.primaryLight,
        borderRadius: BorderRadius.circular(AppConstants.spacingSm),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 30, color: AppColors.textPrimary),
          const SizedBox(height: AppConstants.spacingSm),
          Text(
            label,
            style: AppTextStyles.labelSm,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppConstants.spacingXs),
          Text(
            helper,
            style: AppTextStyles.bodyXs,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  final String label;
  final Color color;

  const _StatusChip({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppConstants.spacingSm,
        vertical: AppConstants.spacingXs,
      ),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(AppConstants.spacingSm),
      ),
      child: Text(
        label,
        style: AppTextStyles.labelXs.copyWith(color: AppColors.surface),
      ),
    );
  }
}

class _InlineInfo extends StatelessWidget {
  final IconData icon;
  final String text;

  const _InlineInfo({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 17, color: AppColors.textSecondary),
        const SizedBox(width: AppConstants.spacingXs),
        Expanded(child: Text(text, style: AppTextStyles.bodySm)),
      ],
    );
  }
}

class _PlanBadge extends StatelessWidget {
  final ServicePackage package;
  final bool isCurrentActivePlan;

  const _PlanBadge({required this.package, required this.isCurrentActivePlan});

  @override
  Widget build(BuildContext context) {
    final isRecommended = package.name.toLowerCase() == 'pro';
    final label = isCurrentActivePlan
        ? 'Đang sử dụng'
        : isRecommended
        ? 'Khuyên dùng'
        : (package.isActive ? 'Đang mở bán' : 'Tạm dừng');
    final backgroundColor = isCurrentActivePlan
        ? AppColors.success
        : isRecommended || package.isActive
        ? AppColors.primary
        : AppColors.muted;
    final foregroundColor =
        isCurrentActivePlan || isRecommended || package.isActive
        ? AppColors.surface
        : AppColors.textSecondary;

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppConstants.spacingSm,
        vertical: AppConstants.spacingXs,
      ),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(AppConstants.spacingSm),
      ),
      child: Text(
        label,
        style: AppTextStyles.labelXs.copyWith(color: foregroundColor),
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

class _ErrorView extends StatelessWidget {
  final String message;
  final Future<void> Function() onRetry;

  const _ErrorView({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppConstants.spacingLg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, size: 40, color: AppColors.error),
            const SizedBox(height: AppConstants.spacingMd),
            Text(
              message,
              style: AppTextStyles.bodySm,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppConstants.spacingMd),
            SizedBox(
              width: 180,
              child: ElevatedButton(
                onPressed: onRetry,
                child: const Text('Thử lại'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyPackagesView extends StatelessWidget {
  const _EmptyPackagesView();

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppConstants.spacingLg),
        child: Column(
          children: [
            const Icon(Icons.inventory_2_outlined, size: 40),
            const SizedBox(height: AppConstants.spacingMd),
            Text(
              'Chưa có gói dịch vụ khả dụng',
              style: AppTextStyles.labelSm,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppConstants.spacingXs),
            Text(
              'Vui lòng quay lại sau hoặc liên hệ quản trị hệ thống.',
              style: AppTextStyles.bodySm,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

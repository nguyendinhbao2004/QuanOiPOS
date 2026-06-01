import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:in_app_review/in_app_review.dart';

import '../../../../config/router_config.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/theme/index.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../widgets/account_menu_section.dart';

class AppSettingsPage extends ConsumerWidget {
  static const _promoBannerUrls = [
    'https://lh3.googleusercontent.com/aida-public/AB6AXuDQVRdryTbDxULmythha6z7XW_4gm1aZbzDjCiPwFWotmUJTwWDeiyMD7kARvUUnhN87498fSO2x-0oV0N7P_Uulx24Ednbk0ok27H-kv_-6G0MzYwtK3DpjMhvwpC0rZZQ-YZjYoQJbnE8eQRZETt74mIHuIa1YA2XUDOthrOG0Lm8ONnJQoDZOUO6IXVaUMYiL-EqDd0SRGpM9XlGD501RJl2O21_EIBX3X5dC0q_30W_LWS8DyyR89bTD53OS602JUwH_bkLJtcv',
    'https://lh3.googleusercontent.com/aida-public/AB6AXuDQVRdryTbDxULmythha6z7XW_4gm1aZbzDjCiPwFWotmUJTwWDeiyMD7kARvUUnhN87498fSO2x-0oV0N7P_Uulx24Ednbk0ok27H-kv_-6G0MzYwtK3DpjMhvwpC0rZZQ-YZjYoQJbnE8eQRZETt74mIHuIa1YA2XUDOthrOG0Lm8ONnJQoDZOUO6IXVaUMYiL-EqDd0SRGpM9XlGD501RJl2O21_EIBX3X5dC0q_30W_LWS8DyyR89bTD53OS602JUwH_bkLJtcv',
    'https://lh3.googleusercontent.com/aida-public/AB6AXuDQVRdryTbDxULmythha6z7XW_4gm1aZbzDjCiPwFWotmUJTwWDeiyMD7kARvUUnhN87498fSO2x-0oV0N7P_Uulx24Ednbk0ok27H-kv_-6G0MzYwtK3DpjMhvwpC0rZZQ-YZjYoQJbnE8eQRZETt74mIHuIa1YA2XUDOthrOG0Lm8ONnJQoDZOUO6IXVaUMYiL-EqDd0SRGpM9XlGD501RJl2O21_EIBX3X5dC0q_30W_LWS8DyyR89bTD53OS602JUwH_bkLJtcv',
  ];

  const AppSettingsPage({super.key});

  Future<void> _openStoreReview(BuildContext context) async {
    final messenger = ScaffoldMessenger.of(context);

    if (kIsWeb) {
      messenger.showSnackBar(
        const SnackBar(
          content: Text('Tính năng đánh giá chưa hỗ trợ trên web'),
        ),
      );
      return;
    }

    if (defaultTargetPlatform == TargetPlatform.iOS ||
        defaultTargetPlatform == TargetPlatform.macOS) {
      messenger.showSnackBar(
        const SnackBar(content: Text('Chưa cấu hình App Store ID')),
      );
      return;
    }

    if (defaultTargetPlatform != TargetPlatform.android) {
      messenger.showSnackBar(
        const SnackBar(
          content: Text('Tính năng đánh giá chưa hỗ trợ trên nền tảng này'),
        ),
      );
      return;
    }

    try {
      await InAppReview.instance.openStoreListing();
    } catch (_) {
      if (!context.mounted) return;
      messenger.showSnackBar(
        const SnackBar(content: Text('Không thể mở trang đánh giá ứng dụng')),
      );
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authNotifierProvider);
    final fullName = authState.fullName?.trim().isNotEmpty == true
        ? authState.fullName!.trim()
        : 'Your name';
    final contact = authState.phone?.trim().isNotEmpty == true
        ? authState.phone!.trim()
        : (authState.email?.trim() ?? '');

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          const _AppSettingsHeader(),
          Expanded(
            child: SafeArea(
              top: false,
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(
                  AppConstants.spacingMd,
                  AppConstants.spacingLg,
                  AppConstants.spacingMd,
                  AppConstants.spacingLg,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _AppSettingsProfileCard(
                      fullName: fullName,
                      contact: contact,
                      onEditProfile: () =>
                          context.pushNamed(RouteNames.profile),
                    ),
                    const SizedBox(height: AppConstants.spacingMd),
                    const _AppSettingsPromoBanner(urls: _promoBannerUrls),
                    const SizedBox(height: AppConstants.spacingMd),
                    AccountMenuSection(
                      key: const Key('app_settings_menu_section'),
                      items: [
                        AccountMenuItemData(
                          title: 'Đóng góp ý kiến',
                          leadingIcon: Icons.chat_bubble_outline_rounded,
                          trailingMeta: 'Đánh giá app',
                          onTap: () => _openStoreReview(context),
                        ),
                        AccountMenuItemData(
                          title: 'Về ứng dụng',
                          leadingIcon: Icons.info_outline_rounded,
                          onTap: () => context.pushNamed(RouteNames.aboutApp),
                        ),
                        AccountMenuItemData(
                          title: 'Quy chế hoạt động',
                          leadingIcon: Icons.verified_user_outlined,
                          onTap: () => context.pushNamed(
                            RouteNames.operationRegulations,
                          ),
                        ),
                        AccountMenuItemData(
                          title: 'Chính sách bảo mật',
                          leadingIcon: Icons.privacy_tip_outlined,
                          onTap: () =>
                              context.pushNamed(RouteNames.privacyPolicy),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppConstants.spacingXl),
                    const _AppSettingsSecureFooter(),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AppSettingsHeader extends StatelessWidget {
  const _AppSettingsHeader();

  @override
  Widget build(BuildContext context) {
    return Container(
      key: const Key('app_settings_header'),
      decoration: const BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.vertical(
          bottom: Radius.circular(AppTheme.radiusXl),
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            AppConstants.spacingXs,
            AppConstants.spacingSm,
            AppConstants.spacingXs,
            AppConstants.spacingLg,
          ),
          child: Row(
            children: [
              SizedBox(
                width: 48,
                child: IconButton(
                  onPressed: () {
                    if (context.canPop()) {
                      context.pop();
                      return;
                    }
                    context.goNamed(RouteNames.storeHome);
                  },
                  icon: const Icon(Icons.arrow_back_rounded),
                  color: AppColors.surface,
                  tooltip: 'Quay lại',
                ),
              ),
              Expanded(
                child: Text(
                  'Cài đặt ứng dụng',
                  style: AppTextStyles.h4.copyWith(
                    color: AppColors.surface,
                    fontWeight: FontWeight.w700,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(width: 48),
            ],
          ),
        ),
      ),
    );
  }
}

class _AppSettingsProfileCard extends StatelessWidget {
  final String fullName;
  final String contact;
  final VoidCallback onEditProfile;

  const _AppSettingsProfileCard({
    required this.fullName,
    required this.contact,
    required this.onEditProfile,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      key: const Key('app_settings_profile_card'),
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(AppTheme.radiusXl),
      child: Padding(
        padding: const EdgeInsets.all(AppConstants.spacingMd),
        child: Row(
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                Container(
                  width: AppConstants.avatarSizeMd,
                  height: AppConstants.avatarSizeMd,
                  decoration: const BoxDecoration(
                    color: AppColors.primaryLight,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.person,
                    color: AppColors.primary,
                    size: 40,
                  ),
                ),
                Positioned(
                  right: 0,
                  bottom: 0,
                  child: Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      color: AppColors.textSecondary,
                      shape: BoxShape.circle,
                      border: Border.all(color: AppColors.surface, width: 2),
                    ),
                    child: const Icon(
                      Icons.photo_camera,
                      color: AppColors.surface,
                      size: 15,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(width: AppConstants.spacingMd),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    fullName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.h3.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  if (contact.isNotEmpty) ...[
                    const SizedBox(height: AppConstants.spacingXs),
                    Text(
                      contact,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.bodySm,
                    ),
                  ],
                  const SizedBox(height: AppConstants.spacingXs),
                  InkWell(
                    onTap: onEditProfile,
                    borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        vertical: AppConstants.spacingXs,
                      ),
                      child: Text(
                        'Chỉnh sửa thông tin',
                        style: AppTextStyles.labelSm.copyWith(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AppSettingsPromoBanner extends StatefulWidget {
  final List<String> urls;

  const _AppSettingsPromoBanner({required this.urls});

  @override
  State<_AppSettingsPromoBanner> createState() =>
      _AppSettingsPromoBannerState();
}

class _AppSettingsPromoBannerState extends State<_AppSettingsPromoBanner> {
  late final PageController _controller;
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    _controller = PageController();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      key: const Key('app_settings_promo_banner'),
      borderRadius: BorderRadius.circular(AppTheme.radiusXl),
      child: AspectRatio(
        aspectRatio: 710 / 220,
        child: Stack(
          fit: StackFit.expand,
          children: [
            PageView.builder(
              key: const Key('app_settings_promo_page_view'),
              controller: _controller,
              hitTestBehavior: HitTestBehavior.opaque,
              itemCount: widget.urls.length,
              onPageChanged: (index) {
                setState(() => _currentIndex = index);
              },
              itemBuilder: (context, index) {
                return ColoredBox(
                  color: AppColors.surface,
                  child: Image.network(
                    widget.urls[index],
                    fit: BoxFit.cover,
                    loadingBuilder: (context, child, loadingProgress) {
                      if (loadingProgress == null) return child;
                      return const Center(
                        child: CircularProgressIndicator(strokeWidth: 2),
                      );
                    },
                    errorBuilder: (context, error, stackTrace) {
                      return Center(
                        child: Text(
                          'Không thể tải banner',
                          style: AppTextStyles.bodySm,
                        ),
                      );
                    },
                  ),
                );
              },
            ),
            Positioned(
              left: 0,
              right: 0,
              bottom: AppConstants.spacingSm,
              child: _AppSettingsBannerDots(
                count: widget.urls.length,
                currentIndex: _currentIndex,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AppSettingsBannerDots extends StatelessWidget {
  final int count;
  final int currentIndex;

  const _AppSettingsBannerDots({
    required this.count,
    required this.currentIndex,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        for (var i = 0; i < count; i++) ...[
          Container(
            key: Key('app_settings_banner_dot_$i'),
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              color: i == currentIndex ? AppColors.primary : AppColors.surface,
              shape: BoxShape.circle,
            ),
          ),
          if (i < count - 1) const SizedBox(width: AppConstants.spacingXs),
        ],
      ],
    );
  }
}

class _AppSettingsSecureFooter extends StatelessWidget {
  const _AppSettingsSecureFooter();

  @override
  Widget build(BuildContext context) {
    return Column(
      key: const Key('app_settings_secure_footer'),
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: AppColors.background,
            shape: BoxShape.circle,
            border: Border.all(color: AppColors.primary),
          ),
          child: const Icon(
            Icons.check_circle_outline_rounded,
            color: AppColors.primary,
          ),
        ),
        const SizedBox(height: AppConstants.spacingSm),
        Text(
          'An toàn & bảo mật 100%',
          style: AppTextStyles.labelXs.copyWith(color: AppColors.textMuted),
        ),
      ],
    );
  }
}

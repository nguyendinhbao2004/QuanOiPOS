import 'package:flutter/material.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/theme/index.dart';

enum AccountTab {
  ads,
  news,
  staff,
  account,
}

class SystemShellScaffold extends StatelessWidget {
  final AccountTab currentTab;
  final ValueChanged<AccountTab> onTabSelected;
  final Widget body;

  const SystemShellScaffold({
    super.key,
    required this.currentTab,
    required this.onTabSelected,
    required this.body,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: body,
      bottomNavigationBar: SafeArea(
        top: false,
        child: Container(
          padding: const EdgeInsets.fromLTRB(
            AppConstants.spacingSm,
            AppConstants.spacingSm,
            AppConstants.spacingSm,
            AppConstants.spacingSm,
          ),
          decoration: const BoxDecoration(
            color: AppColors.surface,
            border: Border(
              top: BorderSide(color: AppColors.border),
            ),
          ),
          child: Row(
            children: [
              Expanded(
                child: BottomNavStubItem(
                  title: 'Quảng cáo',
                  icon: Icons.campaign_outlined,
                  isActive: currentTab == AccountTab.ads,
                  onTap: () => onTabSelected(AccountTab.ads),
                ),
              ),
              Expanded(
                child: BottomNavStubItem(
                  title: 'Tin tức',
                  icon: Icons.newspaper_outlined,
                  isActive: currentTab == AccountTab.news,
                  onTap: () => onTabSelected(AccountTab.news),
                ),
              ),
              Expanded(
                child: BottomNavStubItem(
                  title: 'Nhân sự',
                  icon: Icons.groups_outlined,
                  isActive: currentTab == AccountTab.staff,
                  onTap: () => onTabSelected(AccountTab.staff),
                ),
              ),
              Expanded(
                child: BottomNavStubItem(
                  title: 'Tài khoản',
                  icon: Icons.person_outline,
                  isActive: currentTab == AccountTab.account,
                  onTap: () => onTabSelected(AccountTab.account),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class BottomNavStubItem extends StatelessWidget {
  final String title;
  final IconData icon;
  final bool isActive;
  final VoidCallback onTap;
  final bool isEnabled;

  const BottomNavStubItem({
    super.key,
    required this.title,
    required this.icon,
    required this.isActive,
    required this.onTap,
    this.isEnabled = true,
  });

  @override
  Widget build(BuildContext context) {
    final foregroundColor = isActive ? AppColors.primary : AppColors.textMuted;

    return InkWell(
      onTap: isEnabled ? onTap : null,
      borderRadius: BorderRadius.circular(14),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          vertical: AppConstants.spacingXs,
          horizontal: AppConstants.spacingSm,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppConstants.spacingSm,
                vertical: AppConstants.spacingXs,
              ),
              decoration: BoxDecoration(
                color: isActive ? AppColors.primaryLight : Colors.transparent,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(icon, color: foregroundColor),
            ),
            const SizedBox(height: AppConstants.spacingXs),
            Text(
              title,
              style: AppTextStyles.bodyXs.copyWith(
                color: foregroundColor,
                fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

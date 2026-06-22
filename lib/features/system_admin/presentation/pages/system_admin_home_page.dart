import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/theme/index.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../account_management/presentation/widgets/system_admin_account_management.dart';
import '../../package_management/presentation/widgets/system_admin_package_management.dart';
import '../widgets/system_admin_dashboard.dart';

enum _SystemAdminSection { dashboard, packages, accounts }

class SystemAdminHomePage extends ConsumerStatefulWidget {
  const SystemAdminHomePage({super.key});

  @override
  ConsumerState<SystemAdminHomePage> createState() =>
      _SystemAdminHomePageState();
}

class _SystemAdminHomePageState extends ConsumerState<SystemAdminHomePage> {
  static const double _desktopBreakpoint = 840;
  static const double _sidebarWidth = 280;

  _SystemAdminSection _selectedSection = _SystemAdminSection.dashboard;

  void _selectSection(_SystemAdminSection section) {
    setState(() => _selectedSection = section);
  }

  void _selectMobileSection(BuildContext context, _SystemAdminSection section) {
    _selectSection(section);
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authNotifierProvider);
    final fullName = authState.fullName?.trim();
    final email = authState.email?.trim();
    final adminName = fullName == null || fullName.isEmpty
        ? 'System Admin'
        : fullName;
    final adminEmail = email == null || email.isEmpty ? '' : email;
    final isDesktop = MediaQuery.sizeOf(context).width >= _desktopBreakpoint;

    final content = _SystemAdminContent(section: _selectedSection);
    final navigation = _SystemAdminNavigation(
      selectedSection: _selectedSection,
      adminName: adminName,
      adminEmail: adminEmail,
      onSectionSelected: isDesktop
          ? _selectSection
          : (section) => _selectMobileSection(context, section),
      onLogout: () => ref.read(authNotifierProvider.notifier).logout(),
    );

    if (isDesktop) {
      return Scaffold(
        backgroundColor: AppColors.background,
        body: Row(
          children: [
            SizedBox(width: _sidebarWidth, child: navigation),
            const VerticalDivider(width: 1),
            Expanded(
              child: _SystemAdminMainPane(
                section: _selectedSection,
                child: content,
              ),
            ),
          ],
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: Text(_sectionTitle(_selectedSection))),
      drawer: Drawer(
        width: _sidebarWidth,
        child: SafeArea(child: navigation),
      ),
      body: _SystemAdminMainPane(
        section: _selectedSection,
        showHeader: false,
        child: content,
      ),
    );
  }
}

class _SystemAdminNavigation extends StatelessWidget {
  final _SystemAdminSection selectedSection;
  final String adminName;
  final String adminEmail;
  final ValueChanged<_SystemAdminSection> onSectionSelected;
  final VoidCallback onLogout;

  const _SystemAdminNavigation({
    required this.selectedSection,
    required this.adminName,
    required this.adminEmail,
    required this.onSectionSelected,
    required this.onLogout,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.sidebar,
      padding: const EdgeInsets.all(AppConstants.spacingMd),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _AdminIdentityCard(
            logoAsset: AppConstants.logoAsset,
            adminName: adminName,
            adminEmail: adminEmail,
          ),
          const SizedBox(height: AppConstants.spacingLg),
          _NavigationItem(
            title: 'Dashboard',
            icon: Icons.dashboard_outlined,
            isSelected: selectedSection == _SystemAdminSection.dashboard,
            onTap: () => onSectionSelected(_SystemAdminSection.dashboard),
          ),
          const SizedBox(height: AppConstants.spacingSm),
          _NavigationItem(
            title: 'Quản lý gói',
            icon: Icons.inventory_2_outlined,
            isSelected: selectedSection == _SystemAdminSection.packages,
            onTap: () => onSectionSelected(_SystemAdminSection.packages),
          ),
          const SizedBox(height: AppConstants.spacingSm),
          _NavigationItem(
            title: 'Quản lý account',
            icon: Icons.manage_accounts_outlined,
            isSelected: selectedSection == _SystemAdminSection.accounts,
            onTap: () => onSectionSelected(_SystemAdminSection.accounts),
          ),
          const Spacer(),
          OutlinedButton.icon(
            onPressed: onLogout,
            icon: const Icon(Icons.logout),
            label: const Text('Đăng xuất'),
          ),
        ],
      ),
    );
  }
}

class _AdminIdentityCard extends StatelessWidget {
  final String logoAsset;
  final String adminName;
  final String adminEmail;

  const _AdminIdentityCard({
    required this.logoAsset,
    required this.adminName,
    required this.adminEmail,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 56,
          height: 56,
          padding: const EdgeInsets.all(AppConstants.spacingXs),
          decoration: BoxDecoration(
            color: Colors.transparent,
            border: Border.all(color: AppColors.border),
            borderRadius: BorderRadius.circular(AppTheme.radiusSm),
          ),
          child: Image(image: AssetImage(logoAsset), fit: BoxFit.contain),
        ),
        const SizedBox(width: AppConstants.spacingSm),
        Flexible(
          fit: FlexFit.loose,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                adminName,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTextStyles.labelSm,
              ),
              Text(
                adminEmail,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTextStyles.bodyXs,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _NavigationItem extends StatelessWidget {
  final String title;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;

  const _NavigationItem({
    required this.title,
    required this.icon,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final foregroundColor = isSelected
        ? AppColors.primary
        : AppColors.textPrimary;

    return Material(
      color: isSelected ? AppColors.primaryLight : Colors.transparent,
      borderRadius: BorderRadius.circular(AppTheme.radiusMd),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppConstants.spacingMd,
            vertical: AppConstants.spacingSm,
          ),
          child: Row(
            children: [
              Icon(icon, color: foregroundColor),
              const SizedBox(width: AppConstants.spacingSm),
              Expanded(
                child: Text(
                  title,
                  style: AppTextStyles.labelSm.copyWith(color: foregroundColor),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SystemAdminMainPane extends StatelessWidget {
  final _SystemAdminSection section;
  final Widget child;
  final bool showHeader;

  const _SystemAdminMainPane({
    required this.section,
    required this.child,
    this.showHeader = true,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (showHeader)
            Container(
              padding: const EdgeInsets.fromLTRB(
                AppConstants.spacingLg,
                AppConstants.spacingLg,
                AppConstants.spacingLg,
                AppConstants.spacingMd,
              ),
              decoration: const BoxDecoration(
                color: AppColors.background,
                border: Border(bottom: BorderSide(color: AppColors.border)),
              ),
              child: _WorkspaceHeader(
                title: _sectionTitle(section),
                subtitle: _sectionSubtitle(section),
              ),
            ),
          Expanded(
            child: SingleChildScrollView(
              padding: EdgeInsets.fromLTRB(
                AppConstants.spacingLg,
                showHeader ? AppConstants.spacingLg : AppConstants.spacingMd,
                AppConstants.spacingLg,
                AppConstants.spacingLg,
              ),
              child: child,
            ),
          ),
        ],
      ),
    );
  }
}

class _WorkspaceHeader extends StatelessWidget {
  final String title;
  final String subtitle;

  const _WorkspaceHeader({required this.title, required this.subtitle});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: AppTextStyles.h2),
        const SizedBox(height: AppConstants.spacingXs),
        Text(subtitle, style: AppTextStyles.bodySm),
      ],
    );
  }
}

class _SystemAdminContent extends StatelessWidget {
  final _SystemAdminSection section;

  const _SystemAdminContent({required this.section});

  @override
  Widget build(BuildContext context) {
    return switch (section) {
      _SystemAdminSection.dashboard => const SystemAdminDashboard(),
      _SystemAdminSection.packages => const SystemAdminPackageManagement(),
      _SystemAdminSection.accounts => const SystemAdminAccountManagement(),
    };
  }
}

String _sectionTitle(_SystemAdminSection section) {
  return switch (section) {
    _SystemAdminSection.dashboard => 'Dashboard',
    _SystemAdminSection.packages => 'Quản lý gói',
    _SystemAdminSection.accounts => 'Quản lý account',
  };
}

String _sectionSubtitle(_SystemAdminSection section) {
  return switch (section) {
    _SystemAdminSection.dashboard =>
      'Tổng quan nền tảng, doanh thu và trạng thái vận hành.',
    _SystemAdminSection.packages =>
      'Theo dõi các gói dịch vụ đang bán và hiệu quả doanh thu.',
    _SystemAdminSection.accounts =>
      'Tổng quan account SystemAdmin và StoreUser trên toàn hệ thống.',
  };
}

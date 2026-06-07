import 'package:flutter/material.dart';

import 'account_menu_section.dart';

class AccountHubMenuSection extends StatelessWidget {
  final VoidCallback onSubscriptionTap;
  final VoidCallback onStoresTap;
  final VoidCallback onChangePasswordTap;
  final VoidCallback onAppSettingsTap;

  const AccountHubMenuSection({
    super.key,
    required this.onSubscriptionTap,
    required this.onStoresTap,
    required this.onChangePasswordTap,
    required this.onAppSettingsTap,
  });

  @override
  Widget build(BuildContext context) {
    return AccountMenuSection(
      items: [
        AccountMenuItemData(
          title: 'Gói dịch vụ của tôi',
          leadingIcon: Icons.inventory_2_outlined,
          trailingMeta: 'Xem chi tiết',
          onTap: onSubscriptionTap,
        ),
        AccountMenuItemData(
          title: 'Cửa hàng',
          leadingIcon: Icons.storefront_outlined,
          trailingMeta: 'Chọn cửa hàng',
          onTap: onStoresTap,
        ),
        AccountMenuItemData(
          title: 'Đổi mật khẩu',
          leadingIcon: Icons.lock_reset_outlined,
          onTap: onChangePasswordTap,
        ),
        AccountMenuItemData(
          title: 'Cài đặt ứng dụng',
          leadingIcon: Icons.settings_outlined,
          onTap: onAppSettingsTap,
        ),
      ],
    );
  }
}

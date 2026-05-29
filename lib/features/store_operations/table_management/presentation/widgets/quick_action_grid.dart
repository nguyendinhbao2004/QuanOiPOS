import 'package:flutter/material.dart';

import '../../../../../core/constants/app_constants.dart';
import '../../../../../core/theme/index.dart';

class QuickActionGrid extends StatelessWidget {
  final VoidCallback onTakeAwayTap;
  final VoidCallback onDeliveryTap;

  const QuickActionGrid({
    super.key,
    required this.onTakeAwayTap,
    required this.onDeliveryTap,
  });

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      mainAxisSpacing: AppConstants.spacingMd,
      crossAxisSpacing: AppConstants.spacingMd,
      childAspectRatio: 1.75,
      children: [
        _QuickActionCard(
          icon: Icons.shopping_cart_rounded,
          label: 'Mang về',
          onTap: onTakeAwayTap,
        ),
        _QuickActionCard(
          icon: Icons.local_shipping_rounded,
          label: 'Giao hàng',
          onTap: onDeliveryTap,
        ),
      ],
    );
  }
}

class _QuickActionCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _QuickActionCard({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: AppColors.primaryLight,
                borderRadius: BorderRadius.circular(AppTheme.radiusXl),
              ),
              child: Icon(icon, color: AppColors.primary, size: 30),
            ),
            const SizedBox(height: AppConstants.spacingSm),
            Text(
              label,
              style: AppTextStyles.labelSm.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

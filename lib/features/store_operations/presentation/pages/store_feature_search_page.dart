import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../config/router_config.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/constants/app_permission_codes.dart';
import '../../../../core/theme/index.dart';
import '../../../workspace_context/presentation/controllers/store_access_state.dart';
import '../../../workspace_context/presentation/providers/workspace_context_providers.dart';

class StoreFeatureSearchPage extends ConsumerStatefulWidget {
  final int storeId;

  const StoreFeatureSearchPage({super.key, required this.storeId});

  @override
  ConsumerState<StoreFeatureSearchPage> createState() =>
      _StoreFeatureSearchPageState();
}

class _StoreFeatureSearchPageState
    extends ConsumerState<StoreFeatureSearchPage> {
  late final TextEditingController _searchController;
  String _query = '';

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(storeAccessNotifierProvider(widget.storeId));

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            _SearchHeader(
              controller: _searchController,
              onBack: () {
                if (context.canPop()) {
                  context.pop();
                  return;
                }
                context.goNamed(
                  RouteNames.storeOverview,
                  pathParameters: {'storeId': widget.storeId.toString()},
                );
              },
              onChanged: (value) => setState(() => _query = value),
              onScan: () => _showComingSoon(context, 'Quét mã'),
            ),
            Expanded(
              child: switch (state.status) {
                StoreAccessStatus.initial ||
                StoreAccessStatus.loading => const _LoadingView(),
                StoreAccessStatus.forbidden => _BlockedView(
                  icon: Icons.lock_outline_rounded,
                  title: 'Không có quyền truy cập',
                  message:
                      state.errorMessage ??
                      'Tài khoản của bạn không có quyền truy cập cửa hàng này.',
                ),
                StoreAccessStatus.error => _ErrorView(
                  message:
                      state.errorMessage ?? 'Không thể tải thông tin cửa hàng',
                  onRetry: () => ref
                      .read(
                        storeAccessNotifierProvider(widget.storeId).notifier,
                      )
                      .loadAccess(),
                ),
                StoreAccessStatus.ready => _ReadyFeatureSearchView(
                  storeId: widget.storeId,
                  state: state,
                  query: _query,
                ),
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _SearchHeader extends StatelessWidget {
  final TextEditingController controller;
  final VoidCallback onBack;
  final ValueChanged<String> onChanged;
  final VoidCallback onScan;

  const _SearchHeader({
    required this.controller,
    required this.onBack,
    required this.onChanged,
    required this.onScan,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(
        AppConstants.spacingXs,
        AppConstants.spacingSm,
        AppConstants.spacingXs,
        AppConstants.spacingSm,
      ),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(bottom: BorderSide(color: AppColors.border)),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 48,
            child: IconButton(
              key: const Key('store_feature_search_back_button'),
              tooltip: 'Quay lại',
              onPressed: onBack,
              icon: const Icon(Icons.arrow_back_rounded),
            ),
          ),
          Expanded(
            child: TextField(
              key: const Key('store_feature_search_field'),
              controller: controller,
              autofocus: true,
              onChanged: onChanged,
              textInputAction: TextInputAction.search,
              decoration: const InputDecoration(
                hintText: 'Tìm tính năng',
                prefixIcon: Icon(Icons.search_rounded),
              ),
            ),
          ),
          SizedBox(
            width: 56,
            child: IconButton(
              key: const Key('store_feature_search_scan_button'),
              tooltip: 'Quét mã',
              onPressed: onScan,
              icon: const Icon(Icons.qr_code_scanner_rounded),
            ),
          ),
        ],
      ),
    );
  }
}

class _ReadyFeatureSearchView extends StatelessWidget {
  final int storeId;
  final StoreAccessState state;
  final String query;

  const _ReadyFeatureSearchView({
    required this.storeId,
    required this.state,
    required this.query,
  });

  @override
  Widget build(BuildContext context) {
    final items = _visibleItems(_featureCatalog(context, storeId, state));
    final isSearching = query.trim().isNotEmpty;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppConstants.spacingMd),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            isSearching ? 'Kết quả phù hợp' : 'Gợi ý tính năng',
            style: AppTextStyles.h3.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: AppConstants.spacingMd),
          if (items.isEmpty)
            const _EmptySearchResult()
          else
            LayoutBuilder(
              builder: (context, constraints) {
                final crossAxisCount = constraints.maxWidth >= 640 ? 4 : 2;

                return GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: crossAxisCount,
                    mainAxisSpacing: AppConstants.spacingMd,
                    crossAxisSpacing: AppConstants.spacingMd,
                    childAspectRatio: 1.18,
                  ),
                  itemCount: items.length,
                  itemBuilder: (context, index) =>
                      _FeatureSearchCard(item: items[index]),
                );
              },
            ),
        ],
      ),
    );
  }

  List<_FeatureSearchItem> _visibleItems(List<_FeatureSearchItem> catalog) {
    final normalizedQuery = _normalize(query);
    if (normalizedQuery.isEmpty) {
      return catalog.where((item) => item.isSuggested).toList();
    }

    return catalog.where((item) {
      final values = [item.title, ...item.keywords].map(_normalize);
      return values.any((value) => value.contains(normalizedQuery));
    }).toList();
  }
}

class _FeatureSearchCard extends StatelessWidget {
  final _FeatureSearchItem item;

  const _FeatureSearchCard({required this.item});

  @override
  Widget build(BuildContext context) {
    final foregroundColor = item.isEnabled
        ? AppColors.textPrimary
        : AppColors.textDisabled;
    final iconColor = item.isEnabled ? item.iconColor : AppColors.textMuted;

    return Opacity(
      opacity: item.isEnabled ? 1 : 0.58,
      child: Card(
        child: InkWell(
          key: Key('store_feature_search_item_${item.id}'),
          onTap: item.isEnabled ? item.onTap : null,
          borderRadius: BorderRadius.circular(AppTheme.radiusLg),
          child: Padding(
            padding: const EdgeInsets.all(AppConstants.spacingMd),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(item.icon, color: iconColor, size: 42),
                const SizedBox(height: AppConstants.spacingMd),
                Text(
                  item.title,
                  style: AppTextStyles.label.copyWith(color: foregroundColor),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _EmptySearchResult extends StatelessWidget {
  const _EmptySearchResult();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppConstants.spacingXxl),
      child: Column(
        children: [
          const Icon(
            Icons.search_off_rounded,
            color: AppColors.textMuted,
            size: 48,
          ),
          const SizedBox(height: AppConstants.spacingMd),
          Text(
            'Không tìm thấy tính năng',
            style: AppTextStyles.h4.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: AppConstants.spacingXs),
          Text(
            'Thử tìm bằng tên module hoặc thao tác khác.',
            style: AppTextStyles.bodySm,
            textAlign: TextAlign.center,
          ),
        ],
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

class _BlockedView extends StatelessWidget {
  final IconData icon;
  final String title;
  final String message;

  const _BlockedView({
    required this.icon,
    required this.title,
    required this.message,
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
          ],
        ),
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _ErrorView({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppConstants.spacingLg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.error_outline_rounded,
              color: AppColors.error,
              size: 44,
            ),
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

class _FeatureSearchItem {
  final String id;
  final String title;
  final IconData icon;
  final Color iconColor;
  final List<String> keywords;
  final bool isSuggested;
  final bool isEnabled;
  final VoidCallback onTap;

  const _FeatureSearchItem({
    required this.id,
    required this.title,
    required this.icon,
    required this.iconColor,
    required this.keywords,
    required this.onTap,
    this.isSuggested = false,
    this.isEnabled = true,
  });
}

List<_FeatureSearchItem> _featureCatalog(
  BuildContext context,
  int storeId,
  StoreAccessState state,
) {
  return [
    _FeatureSearchItem(
      id: 'sales',
      title: 'Bán hàng',
      icon: Icons.storefront_rounded,
      iconColor: AppColors.primary,
      keywords: const ['ban hang', 'pos', 'order', 'don hang'],
      isSuggested: true,
      onTap: () => _showComingSoon(context, 'Bán hàng'),
    ),
    _FeatureSearchItem(
      id: 'products',
      title: 'Sản phẩm',
      icon: Icons.inventory_2_rounded,
      iconColor: AppColors.warning,
      keywords: const ['san pham', 'menu', 'hang hoa', 'product'],
      isSuggested: true,
      isEnabled: state.can(AppPermissionCodes.productView),
      onTap: () => context.goNamed(
        RouteNames.storeProductManagement,
        pathParameters: {'storeId': storeId.toString()},
      ),
    ),
    _FeatureSearchItem(
      id: 'kitchen',
      title: 'Khu bếp',
      icon: Icons.kitchen_outlined,
      iconColor: AppColors.info,
      keywords: const ['bep', 'kitchen', 'kds', 'che bien'],
      isSuggested: true,
      isEnabled: state.can(AppPermissionCodes.kitchenAll),
      onTap: () => context.goNamed(
        RouteNames.storeKitchen,
        pathParameters: {'storeId': storeId.toString()},
      ),
    ),
    _FeatureSearchItem(
      id: 'reports',
      title: 'Báo cáo',
      icon: Icons.bar_chart_rounded,
      iconColor: AppColors.success,
      keywords: const ['bao cao', 'thong ke', 'doanh thu', 'report'],
      isSuggested: true,
      isEnabled: state.can(AppPermissionCodes.dashboardView),
      onTap: () => context.goNamed(
        RouteNames.storeBusinessReport,
        pathParameters: {'storeId': storeId.toString()},
      ),
    ),
    _FeatureSearchItem(
      id: 'inventory',
      title: 'Quản lý kho',
      icon: Icons.apps_rounded,
      iconColor: AppColors.chart2,
      keywords: const ['kho', 'ton kho', 'nhap kho', 'xuat kho', 'inventory'],
      onTap: () => context.goNamed(
        RouteNames.storeInventoryManagement,
        pathParameters: {'storeId': storeId.toString()},
      ),
    ),
    _FeatureSearchItem(
      id: 'tables',
      title: 'Quản lý bàn',
      icon: Icons.table_restaurant_rounded,
      iconColor: AppColors.chart3,
      keywords: const ['ban', 'khu vuc', 'phong ban', 'table', 'area'],
      isEnabled: state.can(AppPermissionCodes.areaView),
      onTap: () => context.goNamed(
        RouteNames.storeTableManagement,
        pathParameters: {'storeId': storeId.toString()},
      ),
    ),
    _FeatureSearchItem(
      id: 'staff',
      title: 'Nhân viên',
      icon: Icons.groups_rounded,
      iconColor: AppColors.chart4,
      keywords: const ['nhan vien', 'staff', 'phan quyen', 'vai tro'],
      isEnabled:
          state.can(AppPermissionCodes.staffView) ||
          state.can(AppPermissionCodes.staffInvite) ||
          state.can(AppPermissionCodes.staffUpdate) ||
          state.can(AppPermissionCodes.staffRemove),
      onTap: () => context.goNamed(
        RouteNames.storeStaffManagement,
        pathParameters: {'storeId': storeId.toString()},
      ),
    ),
    _FeatureSearchItem(
      id: 'settings',
      title: 'Cài đặt',
      icon: Icons.settings_rounded,
      iconColor: AppColors.chart5,
      keywords: const ['cai dat', 'store', 'setting', 'cua hang'],
      isEnabled: state.can(AppPermissionCodes.storeUpdate),
      onTap: () => _showComingSoon(context, 'Cài đặt'),
    ),
    _FeatureSearchItem(
      id: 'promotions',
      title: 'Khuyến mãi',
      icon: Icons.local_offer_rounded,
      iconColor: AppColors.error,
      keywords: const ['khuyen mai', 'voucher', 'discount', 'promotion'],
      onTap: () => _showComingSoon(context, 'Khuyến mãi'),
    ),
  ];
}

String _normalize(String value) {
  const replacements = {
    'à': 'a',
    'á': 'a',
    'ạ': 'a',
    'ả': 'a',
    'ã': 'a',
    'â': 'a',
    'ầ': 'a',
    'ấ': 'a',
    'ậ': 'a',
    'ẩ': 'a',
    'ẫ': 'a',
    'ă': 'a',
    'ằ': 'a',
    'ắ': 'a',
    'ặ': 'a',
    'ẳ': 'a',
    'ẵ': 'a',
    'è': 'e',
    'é': 'e',
    'ẹ': 'e',
    'ẻ': 'e',
    'ẽ': 'e',
    'ê': 'e',
    'ề': 'e',
    'ế': 'e',
    'ệ': 'e',
    'ể': 'e',
    'ễ': 'e',
    'ì': 'i',
    'í': 'i',
    'ị': 'i',
    'ỉ': 'i',
    'ĩ': 'i',
    'ò': 'o',
    'ó': 'o',
    'ọ': 'o',
    'ỏ': 'o',
    'õ': 'o',
    'ô': 'o',
    'ồ': 'o',
    'ố': 'o',
    'ộ': 'o',
    'ổ': 'o',
    'ỗ': 'o',
    'ơ': 'o',
    'ờ': 'o',
    'ớ': 'o',
    'ợ': 'o',
    'ở': 'o',
    'ỡ': 'o',
    'ù': 'u',
    'ú': 'u',
    'ụ': 'u',
    'ủ': 'u',
    'ũ': 'u',
    'ư': 'u',
    'ừ': 'u',
    'ứ': 'u',
    'ự': 'u',
    'ử': 'u',
    'ữ': 'u',
    'ỳ': 'y',
    'ý': 'y',
    'ỵ': 'y',
    'ỷ': 'y',
    'ỹ': 'y',
    'đ': 'd',
  };

  final buffer = StringBuffer();
  for (final codePoint in value.toLowerCase().runes) {
    final character = String.fromCharCode(codePoint);
    buffer.write(replacements[character] ?? character);
  }
  return buffer.toString().trim();
}

void _showComingSoon(BuildContext context, String feature) {
  ScaffoldMessenger.of(
    context,
  ).showSnackBar(SnackBar(content: Text('$feature sẽ được triển khai sau')));
}

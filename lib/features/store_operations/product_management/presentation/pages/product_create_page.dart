import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../../config/router_config.dart';
import '../../../../../core/constants/app_constants.dart';
import '../../../../../core/constants/app_permission_codes.dart';
import '../../../../../core/theme/index.dart';
import '../../../../workspace_context/presentation/controllers/store_access_state.dart';
import '../../../../workspace_context/presentation/providers/workspace_context_providers.dart';
import '../../domain/entities/product_topping.dart';
import '../../domain/entities/product_type.dart';
import '../../domain/entities/product_variant_draft.dart';
import '../controllers/product_create_notifier.dart';
import '../controllers/product_create_state.dart';
import '../providers/product_management_providers.dart';

class ProductCreatePage extends ConsumerStatefulWidget {
  final int storeId;

  const ProductCreatePage({super.key, required this.storeId});

  @override
  ConsumerState<ProductCreatePage> createState() => _ProductCreatePageState();
}

class _ProductCreatePageState extends ConsumerState<ProductCreatePage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _preparationTimeController = TextEditingController(text: '0');
  final _basePriceController = TextEditingController();
  final _sizeSPriceController = TextEditingController();
  final _sizeMPriceController = TextEditingController();
  final _sizeLPriceController = TextEditingController();
  int? _categoryId;
  ProductType _type = ProductType.drink;
  bool _hasMultipleSizes = false;
  String _defaultSize = 'M';
  final Set<int> _selectedToppingIds = {};

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _preparationTimeController.dispose();
    _basePriceController.dispose();
    _sizeSPriceController.dispose();
    _sizeMPriceController.dispose();
    _sizeLPriceController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final accessState = ref.watch(storeAccessNotifierProvider(widget.storeId));

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        bottom: false,
        child: switch (accessState.status) {
          StoreAccessStatus.initial ||
          StoreAccessStatus.loading => const _LoadingView(),
          StoreAccessStatus.forbidden => _BlockedView(
            icon: Icons.lock_outline_rounded,
            title: 'Không có quyền truy cập',
            message:
                accessState.errorMessage ??
                'Tài khoản của bạn không có quyền truy cập cửa hàng này.',
            actionLabel: 'Về danh sách cửa hàng',
            onAction: () => context.goNamed(RouteNames.myStores),
          ),
          StoreAccessStatus.error => _BlockedView(
            icon: Icons.error_outline_rounded,
            title: 'Không thể tải thông tin cửa hàng',
            message: accessState.errorMessage ?? 'Vui lòng thử lại sau.',
            actionLabel: 'Thử lại',
            onAction: () => ref
                .read(storeAccessNotifierProvider(widget.storeId).notifier)
                .loadAccess(),
          ),
          StoreAccessStatus.ready => _AccessReadyContent(
            storeId: widget.storeId,
            accessState: accessState,
            formKey: _formKey,
            nameController: _nameController,
            descriptionController: _descriptionController,
            preparationTimeController: _preparationTimeController,
            basePriceController: _basePriceController,
            sizeSPriceController: _sizeSPriceController,
            sizeMPriceController: _sizeMPriceController,
            sizeLPriceController: _sizeLPriceController,
            categoryId: _categoryId,
            type: _type,
            hasMultipleSizes: _hasMultipleSizes,
            defaultSize: _defaultSize,
            selectedToppingIds: _selectedToppingIds,
            onCategoryChanged: (value) => setState(() => _categoryId = value),
            onTypeChanged: (value) => setState(() => _type = value),
            onMultipleSizesChanged: (value) {
              setState(() {
                _hasMultipleSizes = value;
                if (value && _basePriceController.text.trim().isEmpty) {
                  _basePriceController.text = _sizeMPriceController.text;
                }
              });
            },
            onDefaultSizeChanged: (value) =>
                setState(() => _defaultSize = value),
            onToppingChanged: (toppingId, isSelected) {
              setState(() {
                if (isSelected) {
                  _selectedToppingIds.add(toppingId);
                } else {
                  _selectedToppingIds.remove(toppingId);
                }
              });
            },
          ),
        },
      ),
    );
  }
}

class _AccessReadyContent extends ConsumerWidget {
  final int storeId;
  final StoreAccessState accessState;
  final GlobalKey<FormState> formKey;
  final TextEditingController nameController;
  final TextEditingController descriptionController;
  final TextEditingController preparationTimeController;
  final TextEditingController basePriceController;
  final TextEditingController sizeSPriceController;
  final TextEditingController sizeMPriceController;
  final TextEditingController sizeLPriceController;
  final int? categoryId;
  final ProductType type;
  final bool hasMultipleSizes;
  final String defaultSize;
  final Set<int> selectedToppingIds;
  final ValueChanged<int?> onCategoryChanged;
  final ValueChanged<ProductType> onTypeChanged;
  final ValueChanged<bool> onMultipleSizesChanged;
  final ValueChanged<String> onDefaultSizeChanged;
  final void Function(int toppingId, bool isSelected) onToppingChanged;

  const _AccessReadyContent({
    required this.storeId,
    required this.accessState,
    required this.formKey,
    required this.nameController,
    required this.descriptionController,
    required this.preparationTimeController,
    required this.basePriceController,
    required this.sizeSPriceController,
    required this.sizeMPriceController,
    required this.sizeLPriceController,
    required this.categoryId,
    required this.type,
    required this.hasMultipleSizes,
    required this.defaultSize,
    required this.selectedToppingIds,
    required this.onCategoryChanged,
    required this.onTypeChanged,
    required this.onMultipleSizesChanged,
    required this.onDefaultSizeChanged,
    required this.onToppingChanged,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (!accessState.can(AppPermissionCodes.productCreate)) {
      return _BlockedView(
        icon: Icons.visibility_off_outlined,
        title: 'Bạn chưa có quyền thêm sản phẩm',
        message: 'Vui lòng liên hệ quản trị viên cửa hàng để được cấp quyền.',
        actionLabel: 'Về quản lý sản phẩm',
        onAction: () => context.goNamed(
          RouteNames.storeProductManagement,
          pathParameters: {'storeId': storeId.toString()},
        ),
      );
    }

    final access = ProductCreateAccess(
      storeId: storeId,
      canCreateProduct: accessState.can(AppPermissionCodes.productCreate),
    );
    final state = ref.watch(productCreateNotifierProvider(access));
    final notifier = ref.read(productCreateNotifierProvider(access).notifier);

    return Column(
      children: [
        _CreateHeader(storeId: storeId),
        Expanded(
          child: switch (state.status) {
            ProductCreateStatus.initial ||
            ProductCreateStatus.loading => const _LoadingView(),
            ProductCreateStatus.forbidden => _BlockedView(
              icon: Icons.visibility_off_outlined,
              title: 'Bạn chưa có quyền thêm sản phẩm',
              message:
                  state.errorMessage ??
                  'Vui lòng liên hệ quản trị viên cửa hàng để được cấp quyền.',
              actionLabel: 'Về quản lý sản phẩm',
              onAction: () => context.goNamed(
                RouteNames.storeProductManagement,
                pathParameters: {'storeId': storeId.toString()},
              ),
            ),
            ProductCreateStatus.error => _BlockedView(
              icon: Icons.error_outline_rounded,
              title: 'Không thể tải dữ liệu tạo sản phẩm',
              message: state.errorMessage ?? 'Vui lòng thử lại sau.',
              actionLabel: 'Thử lại',
              onAction: notifier.load,
            ),
            ProductCreateStatus.ready ||
            ProductCreateStatus.submitting ||
            ProductCreateStatus.success => _ReadyCreateForm(
              state: state,
              formKey: formKey,
              nameController: nameController,
              descriptionController: descriptionController,
              preparationTimeController: preparationTimeController,
              basePriceController: basePriceController,
              sizeSPriceController: sizeSPriceController,
              sizeMPriceController: sizeMPriceController,
              sizeLPriceController: sizeLPriceController,
              categoryId: categoryId,
              type: type,
              hasMultipleSizes: hasMultipleSizes,
              defaultSize: defaultSize,
              selectedToppingIds: selectedToppingIds,
              onCategoryChanged: onCategoryChanged,
              onTypeChanged: onTypeChanged,
              onMultipleSizesChanged: onMultipleSizesChanged,
              onDefaultSizeChanged: onDefaultSizeChanged,
              onToppingChanged: onToppingChanged,
              onSubmit: () => _submit(context, state, notifier),
            ),
          },
        ),
      ],
    );
  }

  Future<void> _submit(
    BuildContext context,
    ProductCreateState state,
    ProductCreateNotifier notifier,
  ) async {
    if (!(formKey.currentState?.validate() ?? false)) {
      return;
    }

    final selectedCategoryId = categoryId ?? stateCategoryFallback(state);
    if (selectedCategoryId == null) {
      _showMessage(context, 'Vui lòng tạo danh mục trước khi thêm sản phẩm');
      return;
    }

    try {
      await notifier.submit(
        ProductCreateInput(
          name: nameController.text,
          categoryId: selectedCategoryId,
          type: type,
          description: descriptionController.text,
          preparationTime:
              int.tryParse(preparationTimeController.text.trim()) ?? 0,
          basePrice: int.tryParse(basePriceController.text.trim()),
          hasMultipleSizes: hasMultipleSizes,
          variants: _buildVariants(),
          toppingIds: selectedToppingIds.toList(),
        ),
      );

      if (context.mounted) {
        context.pop(true);
      }
    } catch (error) {
      if (context.mounted) {
        _showMessage(context, _cleanError(error));
      }
    }
  }

  int? stateCategoryFallback(ProductCreateState state) {
    return state.categories.isEmpty ? null : state.categories.first.id;
  }

  List<ProductVariantDraft> _buildVariants() {
    if (!hasMultipleSizes) {
      return const [];
    }

    return [
      _variant('Size S', 'S', sizeSPriceController),
      _variant('Size M', 'M', sizeMPriceController),
      _variant('Size L', 'L', sizeLPriceController),
    ];
  }

  ProductVariantDraft _variant(
    String name,
    String size,
    TextEditingController controller,
  ) {
    return ProductVariantDraft(
      name: name,
      price: int.tryParse(controller.text.trim()) ?? 0,
      isDefault: defaultSize == size,
    );
  }
}

class _ReadyCreateForm extends StatelessWidget {
  final ProductCreateState state;
  final GlobalKey<FormState> formKey;
  final TextEditingController nameController;
  final TextEditingController descriptionController;
  final TextEditingController preparationTimeController;
  final TextEditingController basePriceController;
  final TextEditingController sizeSPriceController;
  final TextEditingController sizeMPriceController;
  final TextEditingController sizeLPriceController;
  final int? categoryId;
  final ProductType type;
  final bool hasMultipleSizes;
  final String defaultSize;
  final Set<int> selectedToppingIds;
  final ValueChanged<int?> onCategoryChanged;
  final ValueChanged<ProductType> onTypeChanged;
  final ValueChanged<bool> onMultipleSizesChanged;
  final ValueChanged<String> onDefaultSizeChanged;
  final void Function(int toppingId, bool isSelected) onToppingChanged;
  final VoidCallback onSubmit;

  const _ReadyCreateForm({
    required this.state,
    required this.formKey,
    required this.nameController,
    required this.descriptionController,
    required this.preparationTimeController,
    required this.basePriceController,
    required this.sizeSPriceController,
    required this.sizeMPriceController,
    required this.sizeLPriceController,
    required this.categoryId,
    required this.type,
    required this.hasMultipleSizes,
    required this.defaultSize,
    required this.selectedToppingIds,
    required this.onCategoryChanged,
    required this.onTypeChanged,
    required this.onMultipleSizesChanged,
    required this.onDefaultSizeChanged,
    required this.onToppingChanged,
    required this.onSubmit,
  });

  @override
  Widget build(BuildContext context) {
    final isSubmitting = state.status == ProductCreateStatus.submitting;
    final selectedCategoryId =
        categoryId ??
        (state.categories.isEmpty ? null : state.categories.first.id);

    return Column(
      children: [
        Expanded(
          child: Form(
            key: formKey,
            child: ListView(
              padding: const EdgeInsets.fromLTRB(
                AppConstants.spacingMd,
                AppConstants.spacingMd,
                AppConstants.spacingMd,
                AppConstants.spacingXxl,
              ),
              children: [
                const _ImagePlaceholderSection(),
                const SizedBox(height: AppConstants.spacingLg),
                _SectionTitle('1. Thông tin món'),
                const SizedBox(height: AppConstants.spacingMd),
                TextFormField(
                  key: const Key('product_create_name_field'),
                  controller: nameController,
                  decoration: const InputDecoration(
                    labelText: 'Tên món',
                    suffixText: '*',
                  ),
                  textInputAction: TextInputAction.next,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Vui lòng nhập tên món';
                    }

                    return null;
                  },
                ),
                const SizedBox(height: AppConstants.spacingMd),
                DropdownButtonFormField<int>(
                  key: const Key('product_create_category_field'),
                  initialValue: selectedCategoryId,
                  decoration: const InputDecoration(labelText: 'Danh mục'),
                  items: [
                    for (final category in state.categories)
                      DropdownMenuItem<int>(
                        value: category.id,
                        child: Text(category.name),
                      ),
                  ],
                  validator: (value) {
                    if (value == null) {
                      return 'Vui lòng chọn danh mục';
                    }

                    return null;
                  },
                  onChanged: isSubmitting ? null : onCategoryChanged,
                ),
                const SizedBox(height: AppConstants.spacingMd),
                DropdownButtonFormField<ProductType>(
                  key: const Key('product_create_type_field'),
                  initialValue: type,
                  decoration: const InputDecoration(labelText: 'Loại món'),
                  items: [
                    for (final type in ProductType.values)
                      DropdownMenuItem<ProductType>(
                        value: type,
                        child: Text(type.label),
                      ),
                  ],
                  onChanged: isSubmitting || state.categories.isEmpty
                      ? null
                      : (value) {
                          if (value != null) {
                            onTypeChanged(value);
                          }
                        },
                ),
                const SizedBox(height: AppConstants.spacingMd),
                TextFormField(
                  key: const Key('product_create_description_field'),
                  controller: descriptionController,
                  decoration: const InputDecoration(labelText: 'Mô tả'),
                  minLines: 2,
                  maxLines: 3,
                ),
                const SizedBox(height: AppConstants.spacingMd),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        key: const Key('product_create_preparation_time_field'),
                        controller: preparationTimeController,
                        decoration: const InputDecoration(
                          labelText: 'Thời gian chuẩn bị',
                          suffixText: 'phút',
                        ),
                        keyboardType: TextInputType.number,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                        ],
                      ),
                    ),
                    const SizedBox(width: AppConstants.spacingMd),
                    Expanded(
                      child: TextFormField(
                        key: const Key('product_create_base_price_field'),
                        controller: basePriceController,
                        decoration: const InputDecoration(
                          labelText: 'Giá cơ bản',
                        ),
                        keyboardType: TextInputType.number,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                        ],
                        validator: (value) {
                          if (hasMultipleSizes) {
                            return null;
                          }

                          final price = int.tryParse(value ?? '');
                          if (price == null || price <= 0) {
                            return 'Nhập giá hợp lệ';
                          }

                          return null;
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppConstants.spacingXl),
                _SectionTitle('2. Biến thể / Size'),
                CheckboxListTile(
                  key: const Key('product_create_multi_size_switch'),
                  value: hasMultipleSizes,
                  onChanged: isSubmitting
                      ? null
                      : (value) => onMultipleSizesChanged(value ?? false),
                  title: const Text('Món này có nhiều size'),
                  controlAffinity: ListTileControlAffinity.leading,
                  contentPadding: EdgeInsets.zero,
                ),
                if (hasMultipleSizes) ...[
                  const SizedBox(height: AppConstants.spacingSm),
                  _SizePriceRow(
                    size: 'S',
                    controller: sizeSPriceController,
                    defaultSize: defaultSize,
                    onDefaultSizeChanged: onDefaultSizeChanged,
                  ),
                  const SizedBox(height: AppConstants.spacingSm),
                  _SizePriceRow(
                    size: 'M',
                    controller: sizeMPriceController,
                    defaultSize: defaultSize,
                    onDefaultSizeChanged: onDefaultSizeChanged,
                  ),
                  const SizedBox(height: AppConstants.spacingSm),
                  _SizePriceRow(
                    size: 'L',
                    controller: sizeLPriceController,
                    defaultSize: defaultSize,
                    onDefaultSizeChanged: onDefaultSizeChanged,
                  ),
                ],
                const SizedBox(height: AppConstants.spacingXl),
                _SectionTitle('3. Topping áp dụng'),
                const SizedBox(height: AppConstants.spacingSm),
                if (state.toppings.isEmpty)
                  const _InlineEmptyState(
                    icon: Icons.add_circle_outline,
                    message: 'Chưa có topping để chọn.',
                  )
                else
                  for (final topping in state.toppings)
                    _ToppingCheckbox(
                      topping: topping,
                      isSelected: selectedToppingIds.contains(topping.id),
                      onChanged: (value) => onToppingChanged(topping.id, value),
                    ),
              ],
            ),
          ),
        ),
        _FooterSubmitButton(isSubmitting: isSubmitting, onSubmit: onSubmit),
      ],
    );
  }
}

class _CreateHeader extends StatelessWidget {
  final int storeId;

  const _CreateHeader({required this.storeId});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.surface,
      padding: const EdgeInsets.symmetric(
        horizontal: AppConstants.spacingSm,
        vertical: AppConstants.spacingSm,
      ),
      child: Row(
        children: [
          IconButton(
            tooltip: 'Quay lại',
            icon: const Icon(Icons.arrow_back_rounded),
            onPressed: () => context.goNamed(
              RouteNames.storeProductManagement,
              pathParameters: {'storeId': storeId.toString()},
            ),
          ),
          Expanded(
            child: Text(
              'Tạo sản phẩm',
              style: AppTextStyles.h3.copyWith(fontWeight: FontWeight.w700),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(width: 48),
        ],
      ),
    );
  }
}

class _ImagePlaceholderSection extends StatelessWidget {
  const _ImagePlaceholderSection();

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.surface,
      child: Row(
        children: const [
          _ImageActionPlaceholder(
            icon: Icons.image_outlined,
            label: 'Thêm ảnh',
          ),
          SizedBox(width: AppConstants.spacingMd),
          _ImageActionPlaceholder(icon: Icons.camera_alt, label: 'Chụp ảnh'),
        ],
      ),
    );
  }
}

class _ImageActionPlaceholder extends StatelessWidget {
  final IconData icon;
  final String label;

  const _ImageActionPlaceholder({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 116,
      height: 116,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        border: Border.all(
          color: AppColors.borderDashed,
          style: BorderStyle.solid,
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: AppColors.info),
          const SizedBox(height: AppConstants.spacingSm),
          Text(label, style: AppTextStyles.labelSm),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String text;

  const _SectionTitle(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: AppTextStyles.label.copyWith(fontWeight: FontWeight.w800),
    );
  }
}

class _SizePriceRow extends StatelessWidget {
  final String size;
  final TextEditingController controller;
  final String defaultSize;
  final ValueChanged<String> onDefaultSizeChanged;

  const _SizePriceRow({
    required this.size,
    required this.controller,
    required this.defaultSize,
    required this.onDefaultSizeChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        SizedBox(
          width: 88,
          child: Text('Size $size', style: AppTextStyles.labelSm),
        ),
        Expanded(
          child: TextFormField(
            key: Key('product_create_size_${size.toLowerCase()}_price_field'),
            controller: controller,
            decoration: const InputDecoration(labelText: 'Giá'),
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          ),
        ),
        const SizedBox(width: AppConstants.spacingSm),
        IconButton(
          tooltip: 'Chọn size $size làm mặc định',
          onPressed: () => onDefaultSizeChanged(size),
          icon: Icon(
            defaultSize == size
                ? Icons.radio_button_checked
                : Icons.radio_button_unchecked,
            color: defaultSize == size
                ? AppColors.primary
                : AppColors.textMuted,
          ),
        ),
      ],
    );
  }
}

class _ToppingCheckbox extends StatelessWidget {
  final ProductTopping topping;
  final bool isSelected;
  final ValueChanged<bool> onChanged;

  const _ToppingCheckbox({
    required this.topping,
    required this.isSelected,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return CheckboxListTile(
      key: Key('product_create_topping_${topping.id}'),
      value: isSelected,
      onChanged: (value) => onChanged(value ?? false),
      title: Text(topping.name),
      subtitle: topping.price > 0 ? Text(_formatCurrency(topping.price)) : null,
      contentPadding: EdgeInsets.zero,
      controlAffinity: ListTileControlAffinity.leading,
    );
  }
}

class _InlineEmptyState extends StatelessWidget {
  final IconData icon;
  final String message;

  const _InlineEmptyState({required this.icon, required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppConstants.spacingMd),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Icon(icon, color: AppColors.textMuted),
          const SizedBox(width: AppConstants.spacingSm),
          Expanded(child: Text(message, style: AppTextStyles.bodySm)),
        ],
      ),
    );
  }
}

class _FooterSubmitButton extends StatelessWidget {
  final bool isSubmitting;
  final VoidCallback onSubmit;

  const _FooterSubmitButton({
    required this.isSubmitting,
    required this.onSubmit,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Container(
        color: AppColors.surface,
        padding: const EdgeInsets.all(AppConstants.spacingMd),
        child: SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            key: const Key('product_create_submit_button'),
            onPressed: isSubmitting ? null : onSubmit,
            child: isSubmitting
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Thêm mới'),
          ),
        ),
      ),
    );
  }
}

class _BlockedView extends StatelessWidget {
  final IconData icon;
  final String title;
  final String message;
  final String actionLabel;
  final VoidCallback onAction;

  const _BlockedView({
    required this.icon,
    required this.title,
    required this.message,
    required this.actionLabel,
    required this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.background,
      padding: const EdgeInsets.all(AppConstants.spacingLg),
      child: Center(
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
              width: 220,
              child: ElevatedButton(
                onPressed: onAction,
                child: Text(actionLabel),
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
    return const ColoredBox(
      color: AppColors.background,
      child: Center(child: CircularProgressIndicator()),
    );
  }
}

String _formatCurrency(int value) {
  return '${NumberFormat.decimalPattern('vi_VN').format(value)} đ';
}

String _cleanError(Object error) {
  return error.toString().replaceFirst('Exception: ', '');
}

void _showMessage(BuildContext context, String message) {
  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
}

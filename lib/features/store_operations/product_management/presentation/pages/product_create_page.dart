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
import '../../domain/entities/product.dart';
import '../../domain/entities/product_category.dart';
import '../../domain/entities/product_topping.dart';
import '../../domain/entities/product_type.dart';
import '../../domain/entities/product_variant_draft.dart';
import '../controllers/product_create_notifier.dart';
import '../controllers/product_create_state.dart';
import '../providers/product_management_providers.dart';

class ProductCreatePage extends ConsumerStatefulWidget {
  final int storeId;
  final ProductCreateSeedData? seedData;

  const ProductCreatePage({super.key, required this.storeId, this.seedData});

  @override
  ConsumerState<ProductCreatePage> createState() => _ProductCreatePageState();
}

class _ProductCreatePageState extends ConsumerState<ProductCreatePage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _preparationTimeController = TextEditingController(text: '0');
  final _basePriceController = TextEditingController();
  final List<_VariantOptionRowState> _variantOptions = [];
  int? _categoryId;
  ProductType _type = ProductType.drink;
  bool _hasMultipleSizes = false;
  int? _defaultVariantOptionId;
  int _nextVariantOptionId = 1;
  final Set<int> _selectedToppingIds = {};
  bool _didPrefillProduct = false;

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _preparationTimeController.dispose();
    _basePriceController.dispose();
    for (final option in _variantOptions) {
      option.dispose();
    }
    super.dispose();
  }

  void _ensureVariantOption() {
    if (_variantOptions.isEmpty) {
      _variantOptions.add(_VariantOptionRowState(id: _nextVariantOptionId++));
    }
  }

  void _addVariantOption() {
    setState(() {
      _variantOptions.add(_VariantOptionRowState(id: _nextVariantOptionId++));
    });
  }

  void _removeVariantOption(int id) {
    setState(() {
      final index = _variantOptions.indexWhere((option) => option.id == id);
      if (index == -1) {
        return;
      }

      final option = _variantOptions.removeAt(index);
      option.dispose();
      if (_defaultVariantOptionId == id) {
        _defaultVariantOptionId = null;
      }
    });
  }

  void _toggleDefaultVariantOption(int id) {
    setState(() {
      _defaultVariantOptionId = _defaultVariantOptionId == id ? null : id;
    });
  }

  void _setSelectedToppingIds(Set<int> toppingIds) {
    setState(() {
      _selectedToppingIds
        ..clear()
        ..addAll(toppingIds);
    });
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
            seedData: widget.seedData,
            accessState: accessState,
            formKey: _formKey,
            nameController: _nameController,
            descriptionController: _descriptionController,
            preparationTimeController: _preparationTimeController,
            basePriceController: _basePriceController,
            categoryId: _categoryId,
            type: _type,
            hasMultipleSizes: _hasMultipleSizes,
            variantOptions: _variantOptions,
            defaultVariantOptionId: _defaultVariantOptionId,
            selectedToppingIds: _selectedToppingIds,
            didPrefillProduct: _didPrefillProduct,
            onEditProductLoaded: _prefillProduct,
            onCategoryChanged: (value) => setState(() => _categoryId = value),
            onTypeChanged: (value) => setState(() => _type = value),
            onMultipleSizesChanged: (value) {
              setState(() {
                _hasMultipleSizes = value;
                if (value) {
                  _ensureVariantOption();
                }
              });
            },
            onAddVariantOption: _addVariantOption,
            onRemoveVariantOption: _removeVariantOption,
            onDefaultVariantOptionToggled: _toggleDefaultVariantOption,
            onToppingChanged: (toppingId, isSelected) {
              setState(() {
                if (isSelected) {
                  _selectedToppingIds.add(toppingId);
                } else {
                  _selectedToppingIds.remove(toppingId);
                }
              });
            },
            onToppingSelectionChanged: _setSelectedToppingIds,
          ),
        },
      ),
    );
  }

  void _prefillProduct(Product product) {
    setState(() {
      _didPrefillProduct = true;
      _nameController.text = product.name;
      _descriptionController.text = product.description;
      _preparationTimeController.text = product.preparationTime.toString();
      _basePriceController.text = product.price > 0
          ? product.price.toString()
          : '';
      _categoryId = product.categoryId;
      _type = product.type;
      _selectedToppingIds
        ..clear()
        ..addAll(product.toppings.map((topping) => topping.id));

      for (final option in _variantOptions) {
        option.dispose();
      }
      _variantOptions.clear();
      _defaultVariantOptionId = null;
      _nextVariantOptionId = 1;

      final hasExplicitVariants =
          product.variants.length > 1 ||
          (product.variants.length == 1 &&
              product.variants.first.name.trim().toLowerCase() != 'mặc định');
      _hasMultipleSizes = hasExplicitVariants;
      if (hasExplicitVariants) {
        for (final variant in product.variants) {
          final id = _nextVariantOptionId++;
          final option = _VariantOptionRowState(id: id);
          option.nameController.text = variant.name;
          option.priceController.text = variant.price.toString();
          _variantOptions.add(option);
          if (variant.isDefault) {
            _defaultVariantOptionId = id;
          }
        }
      }
    });
  }
}

class _AccessReadyContent extends ConsumerWidget {
  final int storeId;
  final ProductCreateSeedData? seedData;
  final StoreAccessState accessState;
  final GlobalKey<FormState> formKey;
  final TextEditingController nameController;
  final TextEditingController descriptionController;
  final TextEditingController preparationTimeController;
  final TextEditingController basePriceController;
  final int? categoryId;
  final ProductType type;
  final bool hasMultipleSizes;
  final List<_VariantOptionRowState> variantOptions;
  final int? defaultVariantOptionId;
  final Set<int> selectedToppingIds;
  final bool didPrefillProduct;
  final ValueChanged<Product> onEditProductLoaded;
  final ValueChanged<int?> onCategoryChanged;
  final ValueChanged<ProductType> onTypeChanged;
  final ValueChanged<bool> onMultipleSizesChanged;
  final VoidCallback onAddVariantOption;
  final ValueChanged<int> onRemoveVariantOption;
  final ValueChanged<int> onDefaultVariantOptionToggled;
  final void Function(int toppingId, bool isSelected) onToppingChanged;
  final ValueChanged<Set<int>> onToppingSelectionChanged;

  const _AccessReadyContent({
    required this.storeId,
    required this.seedData,
    required this.accessState,
    required this.formKey,
    required this.nameController,
    required this.descriptionController,
    required this.preparationTimeController,
    required this.basePriceController,
    required this.categoryId,
    required this.type,
    required this.hasMultipleSizes,
    required this.variantOptions,
    required this.defaultVariantOptionId,
    required this.selectedToppingIds,
    required this.didPrefillProduct,
    required this.onEditProductLoaded,
    required this.onCategoryChanged,
    required this.onTypeChanged,
    required this.onMultipleSizesChanged,
    required this.onAddVariantOption,
    required this.onRemoveVariantOption,
    required this.onDefaultVariantOptionToggled,
    required this.onToppingChanged,
    required this.onToppingSelectionChanged,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isEditing = seedData?.isEditing ?? false;
    final canUsePage = isEditing
        ? accessState.can(AppPermissionCodes.productUpdate)
        : accessState.can(AppPermissionCodes.productCreate);
    if (!canUsePage) {
      return _BlockedView(
        icon: Icons.visibility_off_outlined,
        title: isEditing
            ? 'Bạn chưa có quyền cập nhật sản phẩm'
            : 'Bạn chưa có quyền thêm sản phẩm',
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
      canUpdateProduct: accessState.can(AppPermissionCodes.productUpdate),
      canDeleteProduct: accessState.can(AppPermissionCodes.productDelete),
      seedData: seedData,
    );
    final state = ref.watch(productCreateNotifierProvider(access));
    final notifier = ref.read(productCreateNotifierProvider(access).notifier);
    final editingProduct = state.editingProduct;
    if (isEditing && editingProduct != null && !didPrefillProduct) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        onEditProductLoaded(editingProduct);
      });
    }

    return Column(
      children: [
        _CreateHeader(storeId: storeId, isEditing: isEditing),
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
              categoryId: categoryId,
              type: type,
              hasMultipleSizes: hasMultipleSizes,
              variantOptions: variantOptions,
              defaultVariantOptionId: defaultVariantOptionId,
              selectedToppingIds: selectedToppingIds,
              access: access,
              notifier: notifier,
              onCategoryChanged: onCategoryChanged,
              onTypeChanged: onTypeChanged,
              onMultipleSizesChanged: onMultipleSizesChanged,
              onAddVariantOption: onAddVariantOption,
              onRemoveVariantOption: onRemoveVariantOption,
              onDefaultVariantOptionToggled: onDefaultVariantOptionToggled,
              onToppingChanged: onToppingChanged,
              onToppingSelectionChanged: onToppingSelectionChanged,
              onSubmit: () => _submit(context, state, notifier, isEditing),
              onDelete: isEditing
                  ? () => _confirmDelete(context, state, notifier)
                  : null,
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
    bool isEditing,
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
      final input = ProductCreateInput(
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
      );
      if (isEditing) {
        await notifier.update(input);
      } else {
        await notifier.submit(input);
      }

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
      for (final option in variantOptions)
        ProductVariantDraft(
          name: option.nameController.text.trim(),
          price: int.tryParse(option.priceController.text.trim()) ?? 0,
          isDefault: defaultVariantOptionId == option.id,
        ),
    ];
  }

  Future<void> _confirmDelete(
    BuildContext context,
    ProductCreateState state,
    ProductCreateNotifier notifier,
  ) async {
    final productName = state.editingProduct?.name ?? nameController.text;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Xóa sản phẩm?'),
          content: Text('Sản phẩm "$productName" sẽ bị xóa khỏi cửa hàng.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Hủy'),
            ),
            TextButton(
              key: const Key('confirm_delete_product_button'),
              onPressed: () => Navigator.of(context).pop(true),
              style: TextButton.styleFrom(foregroundColor: AppColors.error),
              child: const Text('Xóa'),
            ),
          ],
        );
      },
    );

    if (confirmed != true) {
      return;
    }

    try {
      await notifier.deleteProduct();
      if (context.mounted) {
        context.pop(true);
      }
    } catch (error) {
      if (context.mounted) {
        _showMessage(context, _cleanError(error));
      }
    }
  }
}

class _ReadyCreateForm extends StatelessWidget {
  final ProductCreateState state;
  final GlobalKey<FormState> formKey;
  final TextEditingController nameController;
  final TextEditingController descriptionController;
  final TextEditingController preparationTimeController;
  final TextEditingController basePriceController;
  final int? categoryId;
  final ProductType type;
  final bool hasMultipleSizes;
  final List<_VariantOptionRowState> variantOptions;
  final int? defaultVariantOptionId;
  final Set<int> selectedToppingIds;
  final ProductCreateAccess access;
  final ProductCreateNotifier notifier;
  final ValueChanged<int?> onCategoryChanged;
  final ValueChanged<ProductType> onTypeChanged;
  final ValueChanged<bool> onMultipleSizesChanged;
  final VoidCallback onAddVariantOption;
  final ValueChanged<int> onRemoveVariantOption;
  final ValueChanged<int> onDefaultVariantOptionToggled;
  final void Function(int toppingId, bool isSelected) onToppingChanged;
  final ValueChanged<Set<int>> onToppingSelectionChanged;
  final VoidCallback onSubmit;
  final VoidCallback? onDelete;

  const _ReadyCreateForm({
    required this.state,
    required this.formKey,
    required this.nameController,
    required this.descriptionController,
    required this.preparationTimeController,
    required this.basePriceController,
    required this.categoryId,
    required this.type,
    required this.hasMultipleSizes,
    required this.variantOptions,
    required this.defaultVariantOptionId,
    required this.selectedToppingIds,
    required this.access,
    required this.notifier,
    required this.onCategoryChanged,
    required this.onTypeChanged,
    required this.onMultipleSizesChanged,
    required this.onAddVariantOption,
    required this.onRemoveVariantOption,
    required this.onDefaultVariantOptionToggled,
    required this.onToppingChanged,
    required this.onToppingSelectionChanged,
    required this.onSubmit,
    this.onDelete,
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
                _SelectionField(
                  key: const Key('product_create_category_field'),
                  label: 'Danh mục',
                  value: _categoryLabel(state.categories, selectedCategoryId),
                  hint: 'Chọn danh mục',
                  icon: Icons.category_outlined,
                  onTap: isSubmitting
                      ? null
                      : () => _showCategoryPicker(context, selectedCategoryId),
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
                  _VariantOptionsSection(
                    options: variantOptions,
                    defaultOptionId: defaultVariantOptionId,
                    onAddOption: onAddVariantOption,
                    onRemoveOption: onRemoveVariantOption,
                    onDefaultOptionToggled: onDefaultVariantOptionToggled,
                  ),
                ],
                const SizedBox(height: AppConstants.spacingXl),
                _SectionTitle('3. Topping áp dụng'),
                const SizedBox(height: AppConstants.spacingSm),
                _SelectionField(
                  key: const Key('product_create_topping_field'),
                  label: 'Topping',
                  value: _toppingSummary(state.toppings, selectedToppingIds),
                  hint: 'Chọn topping áp dụng',
                  icon: Icons.add_circle_outline,
                  onTap: isSubmitting
                      ? null
                      : () => _showToppingPicker(context),
                ),
              ],
            ),
          ),
        ),
        _FooterSubmitButton(
          isSubmitting: isSubmitting,
          isEditing: state.editingProduct != null,
          canDelete: access.canDeleteProduct,
          onSubmit: onSubmit,
          onDelete: onDelete,
        ),
      ],
    );
  }

  String? _categoryLabel(
    List<ProductCategory> categories,
    int? selectedCategoryId,
  ) {
    if (selectedCategoryId == null) {
      return null;
    }

    for (final category in categories) {
      if (category.id == selectedCategoryId) {
        return category.name;
      }
    }

    return null;
  }

  String? _toppingSummary(List<ProductTopping> toppings, Set<int> selectedIds) {
    final selectedToppings = toppings
        .where((topping) => selectedIds.contains(topping.id))
        .toList();
    if (selectedToppings.isEmpty) {
      return null;
    }

    if (selectedToppings.length <= 2) {
      return selectedToppings.map((topping) => topping.name).join(', ');
    }

    return '${selectedToppings.length} topping đã chọn';
  }

  Future<void> _showCategoryPicker(
    BuildContext context,
    int? selectedCategoryId,
  ) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return FractionallySizedBox(
          heightFactor: 0.86,
          child: _CategoryPickerBottomSheet(
            categories: state.categories,
            selectedCategoryId: selectedCategoryId,
            onCreateCategory: notifier.createCategory,
            onCategorySelected: onCategoryChanged,
          ),
        );
      },
    );
  }

  Future<void> _showToppingPicker(BuildContext context) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return FractionallySizedBox(
          heightFactor: 0.86,
          child: _ToppingPickerBottomSheet(
            access: access,
            toppings: state.toppings,
            selectedToppingIds: selectedToppingIds,
            onCreateTopping: notifier.createTopping,
            onUpdateTopping: notifier.updateTopping,
            onDeleteTopping: notifier.deleteTopping,
            onSelectionChanged: onToppingSelectionChanged,
          ),
        );
      },
    );
  }
}

class _CreateHeader extends StatelessWidget {
  final int storeId;
  final bool isEditing;

  const _CreateHeader({required this.storeId, required this.isEditing});

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
              isEditing ? 'Chi tiết sản phẩm' : 'Tạo sản phẩm',
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

class _VariantOptionRowState {
  final int id;
  final TextEditingController nameController;
  final TextEditingController priceController;

  _VariantOptionRowState({required this.id})
    : nameController = TextEditingController(),
      priceController = TextEditingController();

  void dispose() {
    nameController.dispose();
    priceController.dispose();
  }
}

class _VariantOptionsSection extends StatelessWidget {
  final List<_VariantOptionRowState> options;
  final int? defaultOptionId;
  final VoidCallback onAddOption;
  final ValueChanged<int> onRemoveOption;
  final ValueChanged<int> onDefaultOptionToggled;

  const _VariantOptionsSection({
    required this.options,
    required this.defaultOptionId,
    required this.onAddOption,
    required this.onRemoveOption,
    required this.onDefaultOptionToggled,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Danh sách tùy chọn',
          style: AppTextStyles.labelSm.copyWith(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: AppConstants.spacingSm),
        for (final option in options) ...[
          _VariantOptionRow(
            option: option,
            isDefault: defaultOptionId == option.id,
            onRemove: () => onRemoveOption(option.id),
            onDefaultToggled: () => onDefaultOptionToggled(option.id),
          ),
          const SizedBox(height: AppConstants.spacingSm),
        ],
        TextButton.icon(
          key: const Key('product_create_add_variant_button'),
          onPressed: onAddOption,
          icon: const Icon(Icons.add_rounded),
          label: const Text('Thêm tùy chọn'),
        ),
      ],
    );
  }
}

class _VariantOptionRow extends StatelessWidget {
  final _VariantOptionRowState option;
  final bool isDefault;
  final VoidCallback onRemove;
  final VoidCallback onDefaultToggled;

  const _VariantOptionRow({
    required this.option,
    required this.isDefault,
    required this.onRemove,
    required this.onDefaultToggled,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          flex: 5,
          child: TextFormField(
            key: Key('product_create_variant_${option.id}_name_field'),
            controller: option.nameController,
            decoration: const InputDecoration(labelText: 'Tên tùy chọn'),
            textInputAction: TextInputAction.next,
          ),
        ),
        const SizedBox(width: AppConstants.spacingSm),
        Expanded(
          flex: 4,
          child: TextFormField(
            key: Key('product_create_variant_${option.id}_price_field'),
            controller: option.priceController,
            decoration: const InputDecoration(
              labelText: 'Giá',
              suffixText: 'đ',
            ),
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          ),
        ),
        IconButton(
          key: Key('product_create_variant_${option.id}_default_button'),
          tooltip: isDefault ? 'Bỏ chọn mặc định' : 'Chọn mặc định',
          onPressed: onDefaultToggled,
          icon: Icon(
            isDefault
                ? Icons.radio_button_checked
                : Icons.radio_button_unchecked,
            color: isDefault ? AppColors.primary : AppColors.textMuted,
          ),
        ),
        IconButton(
          key: Key('product_create_variant_${option.id}_delete_button'),
          tooltip: 'Xóa tùy chọn',
          onPressed: onRemove,
          icon: const Icon(Icons.close_rounded),
          color: AppColors.textMuted,
        ),
      ],
    );
  }
}

class _SelectionField extends StatelessWidget {
  final String label;
  final String? value;
  final String hint;
  final IconData icon;
  final VoidCallback? onTap;

  const _SelectionField({
    super.key,
    required this.label,
    required this.value,
    required this.hint,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppTheme.radiusMd),
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon),
          suffixIcon: const Icon(Icons.keyboard_arrow_down_rounded),
          enabled: onTap != null,
        ),
        child: Text(
          value ?? hint,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: AppTextStyles.bodyBase.copyWith(
            color: value == null ? AppColors.textMuted : AppColors.textPrimary,
          ),
        ),
      ),
    );
  }
}

class _CategoryPickerBottomSheet extends StatefulWidget {
  final List<ProductCategory> categories;
  final int? selectedCategoryId;
  final Future<ProductCategory> Function({required String name})
  onCreateCategory;
  final ValueChanged<int> onCategorySelected;

  const _CategoryPickerBottomSheet({
    required this.categories,
    required this.selectedCategoryId,
    required this.onCreateCategory,
    required this.onCategorySelected,
  });

  @override
  State<_CategoryPickerBottomSheet> createState() =>
      _CategoryPickerBottomSheetState();
}

class _CategoryPickerBottomSheetState
    extends State<_CategoryPickerBottomSheet> {
  final _searchController = TextEditingController();
  late List<ProductCategory> _categories;
  late int? _selectedCategoryId;
  String _query = '';

  @override
  void initState() {
    super.initState();
    _categories = [...widget.categories];
    _selectedCategoryId = widget.selectedCategoryId;
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final categories = _filteredCategories();

    return _PickerSheetFrame(
      key: const Key('product_create_category_picker_sheet'),
      title: 'Danh mục',
      searchController: _searchController,
      searchHint: 'Tìm tên danh mục',
      addTooltip: 'Thêm danh mục',
      onSearchChanged: (value) => setState(() => _query = value.trim()),
      onAdd: _showCategoryForm,
      footer: _PickerFooter(
        updateKey: const Key('product_create_category_picker_update_button'),
        onCancel: () => Navigator.of(context).pop(),
        onUpdate: () => Navigator.of(context).pop(),
      ),
      child: categories.isEmpty
          ? const _InlineEmptyState(
              icon: Icons.category_outlined,
              message: 'Chưa có danh mục phù hợp.',
            )
          : GridView.builder(
              padding: const EdgeInsets.fromLTRB(
                AppConstants.spacingLg,
                0,
                AppConstants.spacingLg,
                AppConstants.spacingXl,
              ),
              gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                maxCrossAxisExtent: 132,
                mainAxisSpacing: AppConstants.spacingLg,
                crossAxisSpacing: AppConstants.spacingLg,
                childAspectRatio: 0.86,
              ),
              itemCount: categories.length,
              itemBuilder: (context, index) {
                final category = categories[index];
                return _PickerGridItem(
                  key: Key(
                    'product_create_category_picker_item_${category.id}',
                  ),
                  title: category.name,
                  icon: Icons.takeout_dining_outlined,
                  isSelected: _selectedCategoryId == category.id,
                  onTap: () => _selectCategory(category.id),
                );
              },
            ),
    );
  }

  void _selectCategory(int categoryId) {
    setState(() => _selectedCategoryId = categoryId);
    widget.onCategorySelected(categoryId);
  }

  List<ProductCategory> _filteredCategories() {
    if (_query.isEmpty) {
      return _categories;
    }

    final query = _query.toLowerCase();
    return _categories
        .where((category) => category.name.toLowerCase().contains(query))
        .toList();
  }

  Future<void> _showCategoryForm() async {
    final category = await showModalBottomSheet<ProductCategory>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return _CategoryCreateFormBottomSheet(
          onSubmit: widget.onCreateCategory,
        );
      },
    );

    if (category == null || !mounted) {
      return;
    }

    setState(() {
      _categories = [..._categories, category];
      _selectedCategoryId = category.id;
    });
    widget.onCategorySelected(category.id);
  }
}

class _ToppingPickerBottomSheet extends StatefulWidget {
  final ProductCreateAccess access;
  final List<ProductTopping> toppings;
  final Set<int> selectedToppingIds;
  final Future<ProductTopping> Function({
    required String name,
    required int price,
  })
  onCreateTopping;
  final Future<ProductTopping> Function({
    required int toppingId,
    required String name,
    required int price,
  })
  onUpdateTopping;
  final Future<void> Function(int toppingId) onDeleteTopping;
  final ValueChanged<Set<int>> onSelectionChanged;

  const _ToppingPickerBottomSheet({
    required this.access,
    required this.toppings,
    required this.selectedToppingIds,
    required this.onCreateTopping,
    required this.onUpdateTopping,
    required this.onDeleteTopping,
    required this.onSelectionChanged,
  });

  @override
  State<_ToppingPickerBottomSheet> createState() =>
      _ToppingPickerBottomSheetState();
}

class _ToppingPickerBottomSheetState extends State<_ToppingPickerBottomSheet> {
  final _searchController = TextEditingController();
  late List<ProductTopping> _toppings;
  late Set<int> _selectedToppingIds;
  String _query = '';
  bool _isEditing = false;

  @override
  void initState() {
    super.initState();
    _toppings = [...widget.toppings];
    _selectedToppingIds = {...widget.selectedToppingIds};
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final toppings = _filteredToppings();
    final canEditList =
        widget.access.canUpdateProduct || widget.access.canDeleteProduct;

    return _PickerSheetFrame(
      key: const Key('product_create_topping_picker_sheet'),
      title: 'Topping',
      leadingAction: canEditList
          ? TextButton.icon(
              key: const Key('edit_product_toppings_button'),
              onPressed: () => setState(() => _isEditing = !_isEditing),
              icon: Icon(
                _isEditing ? Icons.check_rounded : Icons.edit_outlined,
                size: 20,
              ),
              label: Text(_isEditing ? 'Xong' : 'Chỉnh sửa'),
            )
          : null,
      searchController: _searchController,
      searchHint: 'Tìm tên topping',
      addTooltip: 'Thêm topping',
      onSearchChanged: (value) => setState(() => _query = value.trim()),
      onAdd: widget.access.canCreateProduct ? _showCreateToppingForm : null,
      footer: _PickerFooter(
        updateKey: const Key('product_create_topping_picker_update_button'),
        onCancel: () => Navigator.of(context).pop(),
        onUpdate: () => Navigator.of(context).pop(),
      ),
      child: toppings.isEmpty
          ? const _InlineEmptyState(
              icon: Icons.add_circle_outline,
              message: 'Chưa có topping phù hợp.',
            )
          : GridView.builder(
              padding: const EdgeInsets.fromLTRB(
                AppConstants.spacingLg,
                0,
                AppConstants.spacingLg,
                AppConstants.spacingXl,
              ),
              gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                maxCrossAxisExtent: 132,
                mainAxisSpacing: AppConstants.spacingMd,
                crossAxisSpacing: AppConstants.spacingMd,
                mainAxisExtent: 130,
              ),
              itemCount: toppings.length,
              itemBuilder: (context, index) {
                final topping = toppings[index];
                return _PickerGridItem(
                  key: Key('product_create_topping_picker_item_${topping.id}'),
                  title: topping.name,
                  subtitle: topping.price > 0
                      ? _formatCurrency(topping.price)
                      : null,
                  icon: Icons.takeout_dining_outlined,
                  visualSize: 70,
                  textAreaHeight: 46,
                  isSelected: _selectedToppingIds.contains(topping.id),
                  leadingAction: _isEditing
                      ? _PickerItemActionButton(
                          key: Key('delete_product_topping_${topping.id}'),
                          tooltip: widget.access.canDeleteProduct
                              ? 'Xóa topping'
                              : 'Không có quyền xóa',
                          icon: Icons.remove_circle_rounded,
                          color: AppColors.error,
                          onPressed: widget.access.canDeleteProduct
                              ? () => _confirmDeleteTopping(topping)
                              : null,
                        )
                      : null,
                  trailingAction: _isEditing
                      ? _PickerItemActionButton(
                          key: Key('edit_product_topping_${topping.id}'),
                          tooltip: widget.access.canUpdateProduct
                              ? 'Sửa topping'
                              : 'Không có quyền sửa',
                          icon: Icons.edit_outlined,
                          color: AppColors.primary,
                          onPressed: widget.access.canUpdateProduct
                              ? () => _showUpdateToppingForm(topping)
                              : null,
                        )
                      : null,
                  onTap: _isEditing ? null : () => _toggleTopping(topping.id),
                );
              },
            ),
    );
  }

  List<ProductTopping> _filteredToppings() {
    if (_query.isEmpty) {
      return _toppings;
    }

    final query = _query.toLowerCase();
    return _toppings
        .where((topping) => topping.name.toLowerCase().contains(query))
        .toList();
  }

  void _toggleTopping(int toppingId) {
    setState(() {
      if (_selectedToppingIds.contains(toppingId)) {
        _selectedToppingIds.remove(toppingId);
      } else {
        _selectedToppingIds.add(toppingId);
      }
    });
    widget.onSelectionChanged({..._selectedToppingIds});
  }

  Future<void> _showCreateToppingForm() async {
    final topping = await showModalBottomSheet<ProductTopping>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return _ToppingFormBottomSheet(onSubmit: widget.onCreateTopping);
      },
    );

    if (topping == null || !mounted) {
      return;
    }

    setState(() {
      _toppings = [..._toppings, topping];
      _selectedToppingIds.add(topping.id);
    });
    widget.onSelectionChanged({..._selectedToppingIds});
  }

  Future<void> _showUpdateToppingForm(ProductTopping topping) async {
    final updatedTopping = await showModalBottomSheet<ProductTopping>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return _ToppingFormBottomSheet(
          topping: topping,
          onSubmit: ({required name, required price}) {
            return widget.onUpdateTopping(
              toppingId: topping.id,
              name: name,
              price: price,
            );
          },
        );
      },
    );

    if (updatedTopping == null || !mounted) {
      return;
    }

    setState(() {
      _toppings = [
        for (final item in _toppings)
          if (item.id == updatedTopping.id) updatedTopping else item,
      ];
    });
  }

  Future<void> _confirmDeleteTopping(ProductTopping topping) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Xóa topping?'),
          content: Text('Topping "${topping.name}" sẽ bị xóa khỏi cửa hàng.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Hủy'),
            ),
            TextButton(
              key: const Key('confirm_delete_product_topping_button'),
              onPressed: () => Navigator.of(context).pop(true),
              style: TextButton.styleFrom(foregroundColor: AppColors.error),
              child: const Text('Xóa'),
            ),
          ],
        );
      },
    );

    if (confirmed != true) {
      return;
    }

    try {
      await widget.onDeleteTopping(topping.id);
      if (!mounted) {
        return;
      }

      setState(() {
        _toppings = _toppings.where((item) => item.id != topping.id).toList();
        _selectedToppingIds.remove(topping.id);
      });
      widget.onSelectionChanged({..._selectedToppingIds});
      _showMessage(context, 'Đã xóa topping');
    } catch (error) {
      if (mounted) {
        _showMessage(context, _cleanError(error));
      }
    }
  }
}

class _PickerSheetFrame extends StatelessWidget {
  final String title;
  final Widget? leadingAction;
  final TextEditingController searchController;
  final String searchHint;
  final String addTooltip;
  final ValueChanged<String> onSearchChanged;
  final VoidCallback? onAdd;
  final Widget child;
  final Widget footer;

  const _PickerSheetFrame({
    super.key,
    required this.title,
    this.leadingAction,
    required this.searchController,
    required this.searchHint,
    required this.addTooltip,
    required this.onSearchChanged,
    required this.onAdd,
    required this.child,
    required this.footer,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Container(
        decoration: const BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          children: [
            const SizedBox(height: AppConstants.spacingMd),
            Container(
              width: 60,
              height: 5,
              decoration: BoxDecoration(
                color: AppColors.borderStrong,
                borderRadius: BorderRadius.circular(999),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppConstants.spacingMd,
                AppConstants.spacingSm,
                AppConstants.spacingMd,
                AppConstants.spacingSm,
              ),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  if (leadingAction != null)
                    Align(
                      alignment: Alignment.centerLeft,
                      child: leadingAction,
                    ),
                  Text(
                    title,
                    style: AppTextStyles.h4.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  Align(
                    alignment: Alignment.centerRight,
                    child: IconButton(
                      tooltip: 'Đóng',
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(Icons.close_rounded),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppConstants.spacingMd,
                AppConstants.spacingSm,
                AppConstants.spacingMd,
                AppConstants.spacingMd,
              ),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: searchController,
                      onChanged: onSearchChanged,
                      textInputAction: TextInputAction.search,
                      decoration: InputDecoration(
                        hintText: searchHint,
                        prefixIcon: const Icon(Icons.search_rounded),
                      ),
                    ),
                  ),
                  const SizedBox(width: AppConstants.spacingMd),
                  SizedBox(
                    width: 56,
                    height: 56,
                    child: IconButton.filled(
                      tooltip: addTooltip,
                      onPressed: onAdd,
                      icon: const Icon(Icons.add_rounded),
                    ),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            const SizedBox(height: AppConstants.spacingLg),
            Expanded(child: child),
            footer,
          ],
        ),
      ),
    );
  }
}

class _PickerFooter extends StatelessWidget {
  final Key updateKey;
  final VoidCallback onCancel;
  final VoidCallback? onUpdate;

  const _PickerFooter({
    required this.updateKey,
    required this.onCancel,
    required this.onUpdate,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Container(
        color: AppColors.surface,
        padding: const EdgeInsets.all(AppConstants.spacingMd),
        child: Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: onCancel,
                child: const Text('Quay lại'),
              ),
            ),
            const SizedBox(width: AppConstants.spacingMd),
            Expanded(
              child: ElevatedButton(
                key: updateKey,
                onPressed: onUpdate,
                child: const Text('Xong'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PickerGridItem extends StatelessWidget {
  final String title;
  final String? subtitle;
  final IconData icon;
  final double visualSize;
  final double? textAreaHeight;
  final bool isSelected;
  final Widget? leadingAction;
  final Widget? trailingAction;
  final VoidCallback? onTap;

  const _PickerGridItem({
    super.key,
    required this.title,
    this.subtitle,
    required this.icon,
    this.visualSize = 90,
    this.textAreaHeight,
    required this.isSelected,
    this.leadingAction,
    this.trailingAction,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppTheme.radiusMd),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: visualSize,
            height: visualSize,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                Positioned.fill(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: AppColors.inputBackground,
                      borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Icon(icon, color: AppColors.textMuted, size: 30),
                  ),
                ),
                if (leadingAction != null)
                  Positioned(top: -8, left: -8, child: leadingAction!),
                if (trailingAction != null)
                  Positioned(top: -8, right: -8, child: trailingAction!),
                if (isSelected && trailingAction == null)
                  Positioned(
                    top: -6,
                    right: -6,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        color: AppColors.success,
                        borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                      ),
                      child: const Padding(
                        padding: EdgeInsets.all(4),
                        child: Icon(
                          Icons.check_rounded,
                          size: 18,
                          color: AppColors.surface,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: AppConstants.spacingXs),
          SizedBox(
            height: textAreaHeight,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: AppTextStyles.labelSm,
                ),
                if (subtitle != null)
                  Text(
                    subtitle!,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                    style: AppTextStyles.caption.copyWith(
                      color: AppColors.primary,
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PickerItemActionButton extends StatelessWidget {
  final String tooltip;
  final IconData icon;
  final Color color;
  final VoidCallback? onPressed;

  const _PickerItemActionButton({
    super.key,
    required this.tooltip,
    required this.icon,
    required this.color,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surface,
      shape: const CircleBorder(),
      child: IconButton(
        tooltip: tooltip,
        onPressed: onPressed,
        iconSize: 18,
        visualDensity: VisualDensity.compact,
        padding: EdgeInsets.zero,
        constraints: const BoxConstraints.tightFor(width: 32, height: 32),
        color: onPressed == null ? AppColors.textDisabled : color,
        icon: Icon(icon),
      ),
    );
  }
}

class _CategoryCreateFormBottomSheet extends StatefulWidget {
  final Future<ProductCategory> Function({required String name}) onSubmit;

  const _CategoryCreateFormBottomSheet({required this.onSubmit});

  @override
  State<_CategoryCreateFormBottomSheet> createState() =>
      _CategoryCreateFormBottomSheetState();
}

class _CategoryCreateFormBottomSheetState
    extends State<_CategoryCreateFormBottomSheet> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  bool _isSubmitting = false;

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return _CompactFormSheet(
      title: 'Thêm danh mục',
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              key: const Key('category_name_field'),
              controller: _nameController,
              decoration: const InputDecoration(labelText: 'Tên danh mục'),
              textInputAction: TextInputAction.done,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Vui lòng nhập tên danh mục';
                }

                return null;
              },
              onFieldSubmitted: (_) => _submit(),
            ),
            const SizedBox(height: AppConstants.spacingLg),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                key: const Key('category_form_submit_button'),
                onPressed: _isSubmitting ? null : _submit,
                child: _isSubmitting
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Lưu'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) {
      return;
    }

    setState(() => _isSubmitting = true);
    try {
      final category = await widget.onSubmit(name: _nameController.text);
      if (mounted) {
        Navigator.of(context).pop(category);
      }
    } catch (error) {
      if (mounted) {
        _showMessage(context, _cleanError(error));
        setState(() => _isSubmitting = false);
      }
    }
  }
}

class _ToppingFormBottomSheet extends StatefulWidget {
  final ProductTopping? topping;
  final Future<ProductTopping> Function({
    required String name,
    required int price,
  })
  onSubmit;

  const _ToppingFormBottomSheet({this.topping, required this.onSubmit});

  @override
  State<_ToppingFormBottomSheet> createState() =>
      _ToppingFormBottomSheetState();
}

class _ToppingFormBottomSheetState extends State<_ToppingFormBottomSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _priceController;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.topping?.name ?? '');
    _priceController = TextEditingController(
      text: widget.topping == null ? '' : widget.topping!.price.toString(),
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _priceController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return _CompactFormSheet(
      title: widget.topping == null ? 'Thêm topping' : 'Sửa topping',
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              key: const Key('topping_name_field'),
              controller: _nameController,
              decoration: const InputDecoration(labelText: 'Tên topping'),
              textInputAction: TextInputAction.next,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Vui lòng nhập tên topping';
                }

                return null;
              },
            ),
            const SizedBox(height: AppConstants.spacingMd),
            TextFormField(
              key: const Key('topping_price_field'),
              controller: _priceController,
              decoration: const InputDecoration(
                labelText: 'Giá',
                suffixText: 'đ',
              ),
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              validator: (value) {
                final price = int.tryParse(value ?? '');
                if (price == null || price < 0) {
                  return 'Nhập giá hợp lệ';
                }

                return null;
              },
            ),
            const SizedBox(height: AppConstants.spacingLg),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                key: const Key('topping_form_submit_button'),
                onPressed: _isSubmitting ? null : _submit,
                child: _isSubmitting
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Lưu'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) {
      return;
    }

    setState(() => _isSubmitting = true);
    try {
      final topping = await widget.onSubmit(
        name: _nameController.text,
        price: int.tryParse(_priceController.text.trim()) ?? 0,
      );
      if (mounted) {
        Navigator.of(context).pop(topping);
      }
    } catch (error) {
      if (mounted) {
        _showMessage(context, _cleanError(error));
        setState(() => _isSubmitting = false);
      }
    }
  }
}

class _CompactFormSheet extends StatelessWidget {
  final String title;
  final Widget child;

  const _CompactFormSheet({required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;

    return SafeArea(
      top: false,
      child: Container(
        decoration: const BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        padding: EdgeInsets.fromLTRB(
          AppConstants.spacingLg,
          AppConstants.spacingMd,
          AppConstants.spacingLg,
          AppConstants.spacingLg + bottomInset,
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 5,
                decoration: BoxDecoration(
                  color: AppColors.borderStrong,
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
              const SizedBox(height: AppConstants.spacingMd),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      title,
                      style: AppTextStyles.h4.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  IconButton(
                    tooltip: 'Đóng',
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close_rounded),
                  ),
                ],
              ),
              const SizedBox(height: AppConstants.spacingMd),
              child,
            ],
          ),
        ),
      ),
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
  final bool isEditing;
  final bool canDelete;
  final VoidCallback onSubmit;
  final VoidCallback? onDelete;

  const _FooterSubmitButton({
    required this.isSubmitting,
    required this.isEditing,
    required this.canDelete,
    required this.onSubmit,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Container(
        color: AppColors.surface,
        padding: const EdgeInsets.all(AppConstants.spacingMd),
        child: Row(
          children: [
            if (isEditing && canDelete) ...[
              Expanded(
                child: OutlinedButton(
                  key: const Key('product_delete_button'),
                  onPressed: isSubmitting ? null : onDelete,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.error,
                  ),
                  child: const Text('Xóa'),
                ),
              ),
              const SizedBox(width: AppConstants.spacingMd),
            ],
            Expanded(
              child: ElevatedButton(
                key: const Key('product_create_submit_button'),
                onPressed: isSubmitting ? null : onSubmit,
                child: isSubmitting
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Text(isEditing ? 'Cập nhật' : 'Thêm mới'),
              ),
            ),
          ],
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

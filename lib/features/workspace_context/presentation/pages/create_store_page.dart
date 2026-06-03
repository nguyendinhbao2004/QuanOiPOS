import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../config/router_config.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/theme/index.dart';
import '../controllers/create_store_state.dart';
import '../providers/workspace_context_providers.dart';

class CreateStorePage extends ConsumerStatefulWidget {
  const CreateStorePage({super.key});

  @override
  ConsumerState<CreateStorePage> createState() => _CreateStorePageState();
}

class _CreateStorePageState extends ConsumerState<CreateStorePage> {
  static final _phonePattern = RegExp(r'^[0-9]{10,11}$');

  final _formKey = GlobalKey<FormState>();
  final _storeNameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _addressController = TextEditingController();

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      ref.read(createStoreNotifierProvider.notifier).reset();
    });
  }

  @override
  void dispose() {
    _storeNameController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final isValid = _formKey.currentState?.validate() ?? false;
    if (!isValid) {
      return;
    }

    await ref
        .read(createStoreNotifierProvider.notifier)
        .submit(
          storeName: _storeNameController.text,
          phone: _phoneController.text,
          address: _addressController.text,
        );
  }

  Future<void> _handleCreatedStore(int storeId) async {
    try {
      await ref.read(lastActiveStoreNotifierProvider.notifier).save(storeId);
      await ref.read(myStoresNotifierProvider.notifier).loadStores();
    } catch (_) {
      // Refreshing local context should not block opening the created store.
    }

    if (!mounted) return;
    context.goNamed(
      RouteNames.storeOverview,
      pathParameters: {'storeId': storeId.toString()},
    );
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(createStoreNotifierProvider, (previous, next) {
      if (previous?.status != CreateStoreStatus.success &&
          next.status == CreateStoreStatus.success &&
          next.store != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Tạo cửa hàng thành công')),
        );
        unawaited(_handleCreatedStore(next.store!.id));
      }

      final errorMessage = next.errorMessage;
      if (errorMessage != null && errorMessage != previous?.errorMessage) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(errorMessage)));
      }
    });

    final state = ref.watch(createStoreNotifierProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Tạo cửa hàng')),
      body: SafeArea(
        child: Container(
          color: AppColors.background,
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(
              AppConstants.spacingMd,
              AppConstants.spacingLg,
              AppConstants.spacingMd,
              AppConstants.spacingXxl,
            ),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const _CreateStoreHeader(),
                  const SizedBox(height: AppConstants.spacingXl),
                  _CreateStoreTextField(
                    key: const Key('create_store_name_field'),
                    label: 'Tên cửa hàng',
                    hintText: 'VD: Quán Ơi Nguyễn Trãi',
                    controller: _storeNameController,
                    enabled: !state.isSubmitting,
                    textInputAction: TextInputAction.next,
                    maxLength: 255,
                    validator: _validateStoreName,
                  ),
                  const SizedBox(height: AppConstants.spacingMd),
                  _CreateStoreTextField(
                    key: const Key('create_store_phone_field'),
                    label: 'Số điện thoại',
                    hintText: '0900000000',
                    controller: _phoneController,
                    enabled: !state.isSubmitting,
                    keyboardType: TextInputType.phone,
                    textInputAction: TextInputAction.next,
                    maxLength: 11,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    validator: _validatePhone,
                  ),
                  const SizedBox(height: AppConstants.spacingMd),
                  _CreateStoreTextField(
                    key: const Key('create_store_address_field'),
                    label: 'Địa chỉ',
                    hintText: 'Nhập địa chỉ cửa hàng',
                    controller: _addressController,
                    enabled: !state.isSubmitting,
                    keyboardType: TextInputType.streetAddress,
                    textInputAction: TextInputAction.done,
                    maxLength: 500,
                    maxLines: 4,
                    onFieldSubmitted: (_) => _submit(),
                    validator: _validateAddress,
                  ),
                  if (state.errorMessage != null) ...[
                    const SizedBox(height: AppConstants.spacingSm),
                    Text(
                      state.errorMessage!,
                      style: AppTextStyles.bodySm.copyWith(
                        color: AppColors.error,
                      ),
                    ),
                  ],
                  const SizedBox(height: AppConstants.spacingXl),
                  ElevatedButton.icon(
                    key: const Key('create_store_submit_button'),
                    onPressed: state.isSubmitting ? null : _submit,
                    icon: state.isSubmitting
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.storefront_outlined),
                    label: const Text('TẠO CỬA HÀNG'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  String? _validateStoreName(String? value) {
    final text = value?.trim() ?? '';
    if (text.isEmpty) {
      return 'Vui lòng nhập tên cửa hàng';
    }

    if (text.length > 255) {
      return 'Tên cửa hàng không quá 255 ký tự';
    }

    return null;
  }

  String? _validatePhone(String? value) {
    final text = value?.trim() ?? '';
    if (text.isEmpty) {
      return 'Vui lòng nhập số điện thoại';
    }

    if (!_phonePattern.hasMatch(text)) {
      return 'Số điện thoại phải gồm 10 hoặc 11 chữ số';
    }

    return null;
  }

  String? _validateAddress(String? value) {
    final text = value?.trim() ?? '';
    if (text.isEmpty) {
      return 'Vui lòng nhập địa chỉ cửa hàng';
    }

    if (text.length > 500) {
      return 'Địa chỉ không quá 500 ký tự';
    }

    return null;
  }
}

class _CreateStoreHeader extends StatelessWidget {
  const _CreateStoreHeader();

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppConstants.spacingLg),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: const BoxDecoration(
                color: AppColors.primaryLight,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.storefront_rounded,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(width: AppConstants.spacingMd),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Thông tin cửa hàng',
                    style: AppTextStyles.h4.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: AppConstants.spacingXs),
                  Text(
                    'Sau khi tạo xong, bạn sẽ được chuyển vào cửa hàng mới.',
                    style: AppTextStyles.bodySm.copyWith(
                      color: AppColors.textSecondary,
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

class _CreateStoreTextField extends StatelessWidget {
  final String label;
  final String hintText;
  final TextEditingController controller;
  final bool enabled;
  final TextInputType? keyboardType;
  final TextInputAction textInputAction;
  final int? maxLength;
  final int maxLines;
  final List<TextInputFormatter>? inputFormatters;
  final ValueChanged<String>? onFieldSubmitted;
  final FormFieldValidator<String> validator;

  const _CreateStoreTextField({
    super.key,
    required this.label,
    required this.hintText,
    required this.controller,
    required this.enabled,
    required this.textInputAction,
    required this.validator,
    this.keyboardType,
    this.maxLength,
    this.maxLines = 1,
    this.inputFormatters,
    this.onFieldSubmitted,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      enabled: enabled,
      keyboardType: keyboardType,
      textInputAction: textInputAction,
      maxLength: maxLength,
      maxLengthEnforcement: MaxLengthEnforcement.none,
      maxLines: maxLines,
      inputFormatters: inputFormatters,
      decoration: InputDecoration(labelText: label, hintText: hintText),
      onFieldSubmitted: onFieldSubmitted,
      validator: validator,
    );
  }
}

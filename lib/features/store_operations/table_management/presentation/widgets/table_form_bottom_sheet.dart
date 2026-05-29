import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../../core/constants/app_constants.dart';
import '../../../../../core/theme/index.dart';
import '../../domain/entities/area.dart';

class TableFormBottomSheet extends StatefulWidget {
  final Area area;
  final Future<void> Function(String name, int capacity) onSubmit;

  const TableFormBottomSheet({
    super.key,
    required this.area,
    required this.onSubmit,
  });

  @override
  State<TableFormBottomSheet> createState() => _TableFormBottomSheetState();
}

class _TableFormBottomSheetState extends State<TableFormBottomSheet> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _capacityController = TextEditingController();
  bool _isSubmitting = false;

  @override
  void dispose() {
    _nameController.dispose();
    _capacityController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.viewInsetsOf(context).bottom,
        ),
        child: Container(
          decoration: const BoxDecoration(
            color: AppColors.background,
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          ),
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(
              AppConstants.spacingLg,
              AppConstants.spacingMd,
              AppConstants.spacingLg,
              AppConstants.spacingLg,
            ),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 5,
                      decoration: BoxDecoration(
                        color: AppColors.borderStrong,
                        borderRadius: BorderRadius.circular(999),
                      ),
                    ),
                  ),
                  const SizedBox(height: AppConstants.spacingMd),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          'Thêm bàn mới',
                          style: AppTextStyles.h4.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      IconButton(
                        tooltip: 'Đóng',
                        onPressed: _isSubmitting
                            ? null
                            : () => Navigator.of(context).pop(false),
                        icon: const Icon(Icons.close_rounded),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppConstants.spacingMd),
                  TextFormField(
                    key: const Key('table_form_area_field'),
                    initialValue: widget.area.name,
                    readOnly: true,
                    decoration: const InputDecoration(
                      labelText: 'Khu vực',
                      prefixIcon: Icon(Icons.layers_outlined),
                    ),
                  ),
                  const SizedBox(height: AppConstants.spacingMd),
                  TextFormField(
                    key: const Key('table_form_name_field'),
                    controller: _nameController,
                    textInputAction: TextInputAction.next,
                    decoration: const InputDecoration(
                      labelText: 'Tên bàn',
                      hintText: 'Ví dụ: Bàn 3',
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Vui lòng nhập tên bàn';
                      }

                      return null;
                    },
                  ),
                  const SizedBox(height: AppConstants.spacingMd),
                  TextFormField(
                    key: const Key('table_form_capacity_field'),
                    controller: _capacityController,
                    keyboardType: TextInputType.number,
                    textInputAction: TextInputAction.done,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    decoration: const InputDecoration(
                      labelText: 'Số chỗ',
                      hintText: 'Ví dụ: 4',
                    ),
                    validator: (value) {
                      final capacity = int.tryParse(value?.trim() ?? '');
                      if (capacity == null) {
                        return 'Vui lòng nhập số chỗ';
                      }

                      if (capacity < 1) {
                        return 'Số chỗ phải lớn hơn 0';
                      }

                      return null;
                    },
                    onFieldSubmitted: (_) => _submit(),
                  ),
                  const SizedBox(height: AppConstants.spacingLg),
                  ElevatedButton(
                    key: const Key('table_form_submit_button'),
                    onPressed: _isSubmitting ? null : _submit,
                    child: _isSubmitting
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text('Tạo bàn'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _submit() async {
    if (_isSubmitting || !_formKey.currentState!.validate()) {
      return;
    }

    setState(() => _isSubmitting = true);
    try {
      await widget.onSubmit(
        _nameController.text.trim(),
        int.parse(_capacityController.text.trim()),
      );

      if (mounted) {
        Navigator.of(context).pop(true);
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(_cleanError(error))));
      }
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  String _cleanError(Object error) {
    return error.toString().replaceFirst('Exception: ', '');
  }
}

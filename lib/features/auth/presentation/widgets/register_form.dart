import 'package:flutter/material.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/theme/index.dart';

class RegisterForm extends StatelessWidget {
  final VoidCallback onBackToLoginPressed;

  const RegisterForm({
    super.key,
    required this.onBackToLoginPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Email', style: AppTextStyles.labelSm),
        const SizedBox(height: AppConstants.spacingSm),
        const TextField(
          decoration: InputDecoration(hintText: 'Nhập email đăng ký'),
        ),
        const SizedBox(height: AppConstants.spacingMd),
        Text('Mật khẩu', style: AppTextStyles.labelSm),
        const SizedBox(height: AppConstants.spacingSm),
        const TextField(
          obscureText: true,
          decoration: InputDecoration(hintText: 'Nhập mật khẩu'),
        ),
        const SizedBox(height: AppConstants.spacingMd),
        Text('Xác nhận mật khẩu', style: AppTextStyles.labelSm),
        const SizedBox(height: AppConstants.spacingSm),
        const TextField(
          obscureText: true,
          decoration: InputDecoration(hintText: 'Nhập lại mật khẩu'),
        ),
        const SizedBox(height: AppConstants.spacingLg),
        ElevatedButton(
          onPressed: () {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Chức năng đăng ký sẽ triển khai ở phase sau')),
            );
          },
          child: const Text('TẠO TÀI KHOẢN'),
        ),
        const SizedBox(height: AppConstants.spacingSm),
        Align(
          alignment: Alignment.centerRight,
          child: TextButton(
            onPressed: onBackToLoginPressed,
            child: const Text('Quay lại đăng nhập'),
          ),
        ),
        const SizedBox(height: AppConstants.spacingSm),
        Text(
          'Register API chưa được triển khai ở phase hiện tại. Đây là UI placeholder để chuyển đổi giữa hai form.',
          style: AppTextStyles.bodyXs,
        ),
      ],
    );
  }
}

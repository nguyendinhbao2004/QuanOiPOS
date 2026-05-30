import 'package:flutter/material.dart';

import 'account_pdf_document_page.dart';

class PrivacyPolicyPage extends StatelessWidget {
  static const String assetPath = 'assets/documents/privacy_policy.pdf';

  const PrivacyPolicyPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const AccountPdfDocumentPage(
      title: 'Chính sách bảo mật',
      assetPath: assetPath,
      viewerKey: Key('privacy_policy_pdf_viewer'),
      errorMessage: 'Không thể tải tài liệu chính sách bảo mật',
    );
  }
}

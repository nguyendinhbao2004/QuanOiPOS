import 'package:flutter/material.dart';

import 'account_pdf_document_page.dart';

class OperationRegulationsPage extends StatelessWidget {
  static const String assetPath = 'assets/documents/operating_regulations.pdf';

  const OperationRegulationsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const AccountPdfDocumentPage(
      title: 'Quy chế hoạt động',
      assetPath: assetPath,
      viewerKey: Key('operation_regulations_pdf_viewer'),
      errorMessage: 'Không thể tải tài liệu quy chế hoạt động',
    );
  }
}

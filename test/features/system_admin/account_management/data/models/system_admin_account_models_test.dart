import 'package:flutter_test/flutter_test.dart';
import 'package:quan_oi/features/system_admin/account_management/data/models/system_admin_account_models.dart';

void main() {
  test('maps account summary and paged account contract', () {
    final summary = SystemAdminAccountSummaryModel.fromJson({
      'totalAccounts': 12,
      'systemAdminAccounts': 2,
      'storeUserAccounts': 10,
      'activeAccounts': 9,
      'suspendedAccounts': 1,
      'pendingRegistrationCount': 3,
    }).value;
    final page = SystemAdminPageModel.fromJson({
      'items': [
        {
          'id': 1,
          'fullName': 'Admin',
          'email': 'admin@example.com',
          'phone': '0900',
          'accountType': 'SystemAdmin',
          'status': 'Active',
          'createdAt': '2026-06-01T00:00:00Z',
          'lastLogin': null,
        },
      ],
      'pagination': {
        'pageIndex': 1,
        'pageSize': 20,
        'totalItems': 1,
        'totalPages': 1,
      },
    }, SystemAdminAccountModel.fromJson).value;

    expect(summary.pendingRegistrationCount, 3);
    expect(page.items.single.value.email, 'admin@example.com');
    expect(page.totalItems, 1);
  });
}

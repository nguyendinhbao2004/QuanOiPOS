import 'package:flutter_test/flutter_test.dart';
import 'package:quan_oi/core/network/responses/api_response.dart';
import 'package:quan_oi/features/store_operations/staff_management/data/models/staff_member_model.dart';
import 'package:quan_oi/features/store_operations/staff_management/data/models/staff_request_models.dart';
import 'package:quan_oi/features/store_operations/staff_management/data/models/staff_role_model.dart';
import 'package:quan_oi/features/store_operations/staff_management/domain/entities/staff_status.dart';

void main() {
  group('staff management models', () {
    test('parses PascalCase role response envelope', () {
      final response = ApiResponse<List<StaffRoleModel>>.fromJson(const {
        'Succeeded': true,
        'Message': 'OK',
        'Errors': [],
        'Data': [
          {
            'Id': 1,
            'StoreId': null,
            'Name': 'Manager',
            'IsSystemRole': true,
            'Permissions': [
              {
                'Id': 10,
                'Code': 'STAFF.VIEW',
                'Name': 'Xem nhân viên',
                'GroupId': 1,
                'GroupName': 'Nhân viên',
              },
            ],
          },
        ],
      }, dataFromJson: StaffRoleModel.listFromJson);

      expect(response.succeeded, isTrue);
      expect(response.message, 'OK');
      expect(response.data, hasLength(1));
      expect(response.data!.first.name, 'Manager');
      expect(response.data!.first.permissions.first.code, 'STAFF.VIEW');
    });

    test('parses mixed active and pending staff items', () {
      final staff = StaffMemberModel.listFromJson(const [
        {
          'Status': 'Active',
          'StoreUserId': 12,
          'InvitationId': null,
          'AccountId': 8,
          'InvitedAccountId': null,
          'DisplayName': 'Bạn Thu ngân',
          'AccountFullName': 'Nguyen Van A',
          'Email': 'staff@example.com',
          'Phone': '090',
          'Role': {
            'Id': 3,
            'StoreId': 1,
            'Name': 'Thu ngân',
            'IsSystemRole': false,
          },
          'Permissions': [],
          'JoinedAt': '2026-06-01T00:00:00Z',
          'CreatedAt': null,
          'ExpiresAt': null,
          'IsOwner': false,
        },
        {
          'Status': 'Pending',
          'StoreUserId': null,
          'InvitationId': 20,
          'DisplayName': 'Bạn ca tối',
          'Email': 'pending@example.com',
          'Role': {'Id': 4, 'Name': 'Nhân viên', 'IsSystemRole': false},
          'Permissions': [],
          'CreatedAt': '2026-06-01T00:00:00Z',
          'ExpiresAt': '2026-06-08T00:00:00Z',
          'IsOwner': false,
        },
      ]);

      expect(staff, hasLength(2));
      expect(staff.first.status, StaffStatus.active);
      expect(staff.first.toEntity().primaryName, 'Bạn Thu ngân');
      expect(staff.last.status, StaffStatus.pending);
      expect(staff.last.invitationId, 20);
    });

    test('invite request uses backend PascalCase body keys', () {
      final request = InviteStaffRequestModel(
        storeId: 1,
        invitedEmail: 'staff@example.com',
        displayName: 'Bạn Thu ngân',
        roleId: 3,
        permissionIds: const [10, 11],
      );

      expect(request.toJson(), {
        'StoreId': 1,
        'InvitedEmail': 'staff@example.com',
        'DisplayName': 'Bạn Thu ngân',
        'RoleId': 3,
        'PermissionIds': [10, 11],
      });
    });
  });
}

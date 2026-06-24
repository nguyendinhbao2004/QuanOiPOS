import 'package:flutter_test/flutter_test.dart';
import 'package:quan_oi/features/store_invitations/data/models/received_store_invitation_model.dart';

void main() {
  test('parses received store invitation response item', () {
    final model = ReceivedStoreInvitationModel.fromJson({
      'invitationId': 14,
      'storeId': 5,
      'storeName': 'Buffet Cửu Vân Long Premium - Saigon Marina IFC',
      'invitedEmail': 'tinhntse184614@fpt.edu.vn',
      'displayName': 'Tính fpt',
      'invitedAccountId': 39,
      'roleId': 2,
      'roleName': 'Manager',
      'invitedByAccountId': 8,
      'invitedByFullName': 'quang',
      'invitedByEmail': 'quangca1307@gmail.com',
      'status': 1,
      'createdAt': '2026-06-24T05:45:40.256643Z',
      'expiresAt': '2026-07-01T05:45:40.256141Z',
      'respondedAt': null,
      'permissionIds': [70, 66, 68],
    });

    expect(model.invitationId, 14);
    expect(model.storeId, 5);
    expect(model.storeName, 'Buffet Cửu Vân Long Premium - Saigon Marina IFC');
    expect(model.roleName, 'Manager');
    expect(model.invitedByFullName, 'quang');
    expect(model.permissionIds, [70, 66, 68]);
    expect(model.respondedAt, isNull);

    final entity = model.toEntity();
    expect(entity.isPending, isTrue);
    expect(entity.inviterDisplayName, 'quang');
  });

  test('parses list response safely', () {
    final models = ReceivedStoreInvitationModel.listFromJson([
      {
        'invitationId': 1,
        'storeId': 2,
        'storeName': 'Store A',
        'invitedEmail': 'a@example.com',
        'displayName': 'A',
        'roleId': 3,
        'roleName': 'Staff',
        'invitedByAccountId': 4,
        'invitedByFullName': 'Owner',
        'invitedByEmail': 'owner@example.com',
        'status': 1,
        'permissionIds': [1, 2],
      },
    ]);

    expect(models, hasLength(1));
    expect(models.first.storeName, 'Store A');
  });
}

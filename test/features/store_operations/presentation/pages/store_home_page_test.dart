import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quan_oi/core/theme/index.dart';
import 'package:quan_oi/features/auth/domain/entities/account_type.dart';
import 'package:quan_oi/features/auth/presentation/controllers/auth_notifier.dart';
import 'package:quan_oi/features/auth/presentation/controllers/auth_state.dart';
import 'package:quan_oi/features/auth/presentation/providers/auth_providers.dart';
import 'package:quan_oi/features/store_invitations/domain/entities/received_store_invitation.dart';
import 'package:quan_oi/features/store_invitations/domain/repositories/store_invitation_repository.dart';
import 'package:quan_oi/features/store_invitations/domain/usecases/accept_store_invitation_use_case.dart';
import 'package:quan_oi/features/store_invitations/domain/usecases/load_received_store_invitations_use_case.dart';
import 'package:quan_oi/features/store_invitations/domain/usecases/reject_store_invitation_use_case.dart';
import 'package:quan_oi/features/store_invitations/presentation/providers/store_invitation_providers.dart';
import 'package:quan_oi/features/store_operations/presentation/pages/store_home_page.dart';

void main() {
  testWidgets('account hub shows invitation badge and notification sheet', (
    tester,
  ) async {
    final repository = _FakeStoreInvitationRepository();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authNotifierProvider.overrideWith(() => _FixedAuthNotifier()),
          loadReceivedStoreInvitationsUseCaseProvider.overrideWithValue(
            LoadReceivedStoreInvitationsUseCase(repository),
          ),
          acceptStoreInvitationUseCaseProvider.overrideWithValue(
            AcceptStoreInvitationUseCase(repository),
          ),
          rejectStoreInvitationUseCaseProvider.overrideWithValue(
            RejectStoreInvitationUseCase(repository),
          ),
        ],
        child: MaterialApp(theme: AppTheme.light, home: const StoreHomePage()),
      ),
    );

    await tester.pump(const Duration(milliseconds: 500));
    await tester.pumpAndSettle();

    expect(
      find.byKey(const Key('account_hub_notification_badge')),
      findsOneWidget,
    );
    expect(find.text('1'), findsOneWidget);

    await tester.tap(find.byKey(const Key('account_hub_notification_button')));
    await tester.pumpAndSettle();

    expect(find.text('Lời mời cửa hàng'), findsOneWidget);
    expect(
      find.text('Buffet Cửu Vân Long Premium - Saigon Marina IFC'),
      findsOneWidget,
    );
    expect(find.text('Manager'), findsOneWidget);
    expect(find.textContaining('Người mời: quang'), findsOneWidget);
    expect(
      find.text('Email nhận lời mời: tinhntse184614@fpt.edu.vn'),
      findsOneWidget,
    );
  });

  testWidgets('accept invitation removes item and shows success message', (
    tester,
  ) async {
    final repository = _FakeStoreInvitationRepository();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authNotifierProvider.overrideWith(() => _FixedAuthNotifier()),
          loadReceivedStoreInvitationsUseCaseProvider.overrideWithValue(
            LoadReceivedStoreInvitationsUseCase(repository),
          ),
          acceptStoreInvitationUseCaseProvider.overrideWithValue(
            AcceptStoreInvitationUseCase(repository),
          ),
          rejectStoreInvitationUseCaseProvider.overrideWithValue(
            RejectStoreInvitationUseCase(repository),
          ),
        ],
        child: MaterialApp(theme: AppTheme.light, home: const StoreHomePage()),
      ),
    );

    await tester.pump(const Duration(milliseconds: 500));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('account_hub_notification_button')));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('accept_store_invitation_14')));
    await tester.pump();
    await tester.pumpAndSettle();

    expect(repository.acceptedInvitationIds, [14]);
    expect(find.text('Chấp nhận lời mời thành công'), findsOneWidget);
    expect(find.text('Chưa có thông báo mới'), findsOneWidget);
  });

  testWidgets('reject invitation removes item and shows success message', (
    tester,
  ) async {
    final repository = _FakeStoreInvitationRepository();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authNotifierProvider.overrideWith(() => _FixedAuthNotifier()),
          loadReceivedStoreInvitationsUseCaseProvider.overrideWithValue(
            LoadReceivedStoreInvitationsUseCase(repository),
          ),
          acceptStoreInvitationUseCaseProvider.overrideWithValue(
            AcceptStoreInvitationUseCase(repository),
          ),
          rejectStoreInvitationUseCaseProvider.overrideWithValue(
            RejectStoreInvitationUseCase(repository),
          ),
        ],
        child: MaterialApp(theme: AppTheme.light, home: const StoreHomePage()),
      ),
    );

    await tester.pump(const Duration(milliseconds: 500));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('account_hub_notification_button')));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('reject_store_invitation_14')));
    await tester.pump();
    await tester.pumpAndSettle();

    expect(repository.rejectedInvitationIds, [14]);
    expect(find.text('Từ chối lời mời thành công'), findsOneWidget);
    expect(find.text('Chưa có thông báo mới'), findsOneWidget);
  });
}

class _FixedAuthNotifier extends AuthNotifier {
  @override
  AuthState build() {
    return const AuthState(
      status: AuthStatus.authenticated,
      accountType: AccountType.storeUser,
      fullName: 'Tính',
      email: 'tinhntse184614@fpt.edu.vn',
    );
  }
}

class _FakeStoreInvitationRepository implements StoreInvitationRepository {
  final List<int> acceptedInvitationIds = [];
  final List<int> rejectedInvitationIds = [];

  @override
  Future<String> acceptInvitation(int invitationId) async {
    acceptedInvitationIds.add(invitationId);
    return 'Chấp nhận lời mời thành công';
  }

  @override
  Future<List<ReceivedStoreInvitation>> loadReceivedInvitations() async {
    return [
      ReceivedStoreInvitation(
        invitationId: 14,
        storeId: 5,
        storeName: 'Buffet Cửu Vân Long Premium - Saigon Marina IFC',
        invitedEmail: 'tinhntse184614@fpt.edu.vn',
        displayName: 'Tính fpt',
        invitedAccountId: 39,
        roleId: 2,
        roleName: 'Manager',
        invitedByAccountId: 8,
        invitedByFullName: 'quang',
        invitedByEmail: 'quangca1307@gmail.com',
        status: 1,
        createdAt: DateTime.utc(2026, 6, 24, 5, 45, 40),
        expiresAt: DateTime.utc(2026, 7, 1, 5, 45, 40),
        respondedAt: null,
        permissionIds: const [70, 66, 68],
      ),
    ];
  }

  @override
  Future<String> rejectInvitation(int invitationId) async {
    rejectedInvitationIds.add(invitationId);
    return 'Từ chối lời mời thành công';
  }
}

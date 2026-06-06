import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../core/di/injection.dart';
import '../../data/datasources/staff_management_remote_data_source.dart';
import '../../domain/repositories/staff_management_repository.dart';
import '../../domain/usecases/cancel_staff_invitation_use_case.dart';
import '../../domain/usecases/create_staff_role_use_case.dart';
import '../../domain/usecases/delete_staff_role_use_case.dart';
import '../../domain/usecases/invite_staff_use_case.dart';
import '../../domain/usecases/load_staff_members_use_case.dart';
import '../../domain/usecases/load_staff_permission_groups_use_case.dart';
import '../../domain/usecases/load_staff_roles_use_case.dart';
import '../../domain/usecases/remove_staff_use_case.dart';
import '../../domain/usecases/update_staff_access_use_case.dart';
import '../../domain/usecases/update_staff_display_name_use_case.dart';
import '../../domain/usecases/update_staff_role_use_case.dart';
import '../controllers/staff_detail_notifier.dart';
import '../controllers/staff_detail_state.dart';
import '../controllers/staff_invite_notifier.dart';
import '../controllers/staff_invite_state.dart';
import '../controllers/staff_management_access.dart';
import '../controllers/staff_management_notifier.dart';
import '../controllers/staff_management_state.dart';
import '../controllers/staff_role_form_notifier.dart';
import '../controllers/staff_role_form_state.dart';

final staffManagementRemoteDataSourceProvider =
    Provider<StaffManagementRemoteDataSource>((ref) {
      return locator<StaffManagementRemoteDataSource>();
    });

final staffManagementRepositoryProvider = Provider<StaffManagementRepository>((
  ref,
) {
  return locator<StaffManagementRepository>();
});

final loadStaffRolesUseCaseProvider = Provider<LoadStaffRolesUseCase>((ref) {
  return locator<LoadStaffRolesUseCase>();
});

final loadStaffMembersUseCaseProvider = Provider<LoadStaffMembersUseCase>((
  ref,
) {
  return locator<LoadStaffMembersUseCase>();
});

final loadStaffPermissionGroupsUseCaseProvider =
    Provider<LoadStaffPermissionGroupsUseCase>((ref) {
      return locator<LoadStaffPermissionGroupsUseCase>();
    });

final inviteStaffUseCaseProvider = Provider<InviteStaffUseCase>((ref) {
  return locator<InviteStaffUseCase>();
});

final cancelStaffInvitationUseCaseProvider =
    Provider<CancelStaffInvitationUseCase>((ref) {
      return locator<CancelStaffInvitationUseCase>();
    });

final updateStaffDisplayNameUseCaseProvider =
    Provider<UpdateStaffDisplayNameUseCase>((ref) {
      return locator<UpdateStaffDisplayNameUseCase>();
    });

final updateStaffAccessUseCaseProvider = Provider<UpdateStaffAccessUseCase>((
  ref,
) {
  return locator<UpdateStaffAccessUseCase>();
});

final removeStaffUseCaseProvider = Provider<RemoveStaffUseCase>((ref) {
  return locator<RemoveStaffUseCase>();
});

final createStaffRoleUseCaseProvider = Provider<CreateStaffRoleUseCase>((ref) {
  return locator<CreateStaffRoleUseCase>();
});

final updateStaffRoleUseCaseProvider = Provider<UpdateStaffRoleUseCase>((ref) {
  return locator<UpdateStaffRoleUseCase>();
});

final deleteStaffRoleUseCaseProvider = Provider<DeleteStaffRoleUseCase>((ref) {
  return locator<DeleteStaffRoleUseCase>();
});

final staffManagementNotifierProvider = NotifierProvider.autoDispose
    .family<
      StaffManagementNotifier,
      StaffManagementState,
      StaffManagementAccess
    >(StaffManagementNotifier.new);

final staffDetailNotifierProvider = NotifierProvider.autoDispose
    .family<StaffDetailNotifier, StaffDetailState, StaffDetailArgs>(
      StaffDetailNotifier.new,
    );

final staffInviteNotifierProvider = NotifierProvider.autoDispose
    .family<StaffInviteNotifier, StaffInviteState, StaffManagementAccess>(
      StaffInviteNotifier.new,
    );

final staffRoleFormNotifierProvider = NotifierProvider.autoDispose
    .family<StaffRoleFormNotifier, StaffRoleFormState, StaffRoleFormArgs>(
      StaffRoleFormNotifier.new,
    );

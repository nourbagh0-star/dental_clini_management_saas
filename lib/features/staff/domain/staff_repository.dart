import 'staff_models.dart';

abstract interface class StaffRepository {
  Future<List<StaffMember>> getStaffMembers(String clinicId);

  Future<List<StaffInvitation>> getInvitations(String clinicId);
  Future<void> createAccount({
    required String clinicId,
    required String displayName,
    required String email,
    required Set<StaffRole> roles,
    required String temporaryPassword,
    required String ownerPassword,
  });

  Future<StaffInvitationDelivery> createInvitation({
    required String clinicId,
    required String email,
    required Set<StaffRole> roles,
    required Uri appOrigin,
    String? ownerPassword,
  });

  Future<StaffInvitationDelivery> resendInvitation({
    required String clinicId,
    required String invitationId,
    required Uri appOrigin,
    String? ownerPassword,
  });

  Future<void> revokeInvitation({
    required String clinicId,
    required String invitationId,
    String? ownerPassword,
  });

  Future<String> acceptInvitation(String token);

  Future<void> replaceMemberRoles({
    required String clinicId,
    required String memberId,
    required Set<StaffRole> roles,
    String? ownerPassword,
  });

  Future<void> setMemberActive({
    required String clinicId,
    required String memberId,
    required bool isActive,
    String? ownerPassword,
  });
}

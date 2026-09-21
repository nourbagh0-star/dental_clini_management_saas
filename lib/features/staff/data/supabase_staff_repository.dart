import 'package:injectable/injectable.dart';

import '../../../core/error/app_failure.dart';
import '../domain/staff_models.dart';
import '../domain/staff_repository.dart';
import '../domain/staff_validation.dart';
import 'staff_data_source.dart';

@LazySingleton(as: StaffRepository)
class SupabaseStaffRepository implements StaffRepository {
  SupabaseStaffRepository(this._source);

  final StaffDataSource _source;

  @override
  Future<void> createAccount({
    required String clinicId,
    required String displayName,
    required String email,
    required Set<StaffRole> roles,
    required String temporaryPassword,
    required String ownerPassword,
  }) async {
    if (temporaryPassword.length < 15 ||
        temporaryPassword.length > 128 ||
        displayName.trim().length < 2 ||
        displayName.trim().length > 120 ||
        ownerPassword.isEmpty) {
      throw const StaffOperationException(StaffOperationIssue.invalidInput);
    }
    await _complete({
      'action': 'create_account',
      'clinicId': StaffValidation.id(clinicId),
      'displayName': displayName.trim(),
      'email': StaffValidation.email(email),
      'roles': _roleValues(roles),
      'temporaryPassword': temporaryPassword,
      'ownerPassword': ownerPassword,
    });
  }

  @override
  Future<List<StaffMember>> getStaffMembers(String clinicId) async {
    StaffValidation.id(clinicId);
    return (await _source.getStaffMemberRows(
      clinicId,
    )).map(_staffMemberFromRow).toList(growable: false);
  }

  @override
  Future<List<StaffInvitation>> getInvitations(String clinicId) async {
    StaffValidation.id(clinicId);
    return (await _source.getInvitationRows(
      clinicId,
    )).map(_invitationFromRow).toList(growable: false);
  }

  @override
  Future<StaffInvitationDelivery> createInvitation({
    required String clinicId,
    required String email,
    required Set<StaffRole> roles,
    required Uri appOrigin,
    String? ownerPassword,
  }) async {
    final response = await _source.invokeStaffAction({
      'action': 'create',
      'clinicId': StaffValidation.id(clinicId),
      'email': StaffValidation.email(email),
      'roles': _roleValues(roles),
      'appOrigin': StaffValidation.appOrigin(appOrigin).toString(),
      if (ownerPassword != null && ownerPassword.isNotEmpty) ...{
        '_proofPassword': ownerPassword,
        '_proofAction': 'owner_invitation_create',
        '_proofClinicId': StaffValidation.id(clinicId),
        '_proofTargetId': null,
        '_proofCommand': {
          'clinicId': StaffValidation.id(clinicId),
          'email': StaffValidation.email(email),
          'roles': _roleValues(roles),
        },
      },
    });
    return _deliveryFromResponse(response);
  }

  @override
  Future<StaffInvitationDelivery> resendInvitation({
    required String clinicId,
    required String invitationId,
    required Uri appOrigin,
    String? ownerPassword,
  }) async {
    final response = await _source.invokeStaffAction({
      'action': 'resend',
      'invitationId': StaffValidation.id(invitationId),
      'appOrigin': StaffValidation.appOrigin(appOrigin).toString(),
      if (ownerPassword != null && ownerPassword.isNotEmpty) ...{
        '_proofPassword': ownerPassword,
        '_proofAction': 'owner_invitation_resend',
        '_proofClinicId': StaffValidation.id(clinicId),
        '_proofTargetId': StaffValidation.id(invitationId),
        '_proofCommand': {'invitationId': StaffValidation.id(invitationId)},
      },
    });
    return _deliveryFromResponse(response);
  }

  @override
  Future<void> revokeInvitation({
    required String clinicId,
    required String invitationId,
    String? ownerPassword,
  }) => _complete({
    'action': 'revoke',
    'invitationId': StaffValidation.id(invitationId),
    if (ownerPassword != null && ownerPassword.isNotEmpty) ...{
      '_proofPassword': ownerPassword,
      '_proofAction': 'owner_invitation_revoke',
      '_proofClinicId': StaffValidation.id(clinicId),
      '_proofTargetId': StaffValidation.id(invitationId),
      '_proofCommand': {'invitationId': StaffValidation.id(invitationId)},
    },
  });

  @override
  Future<String> acceptInvitation(String token) async {
    final response = await _source.invokeStaffAction({
      'action': 'accept',
      'token': StaffValidation.invitationToken(token),
    });
    return _requiredString(response, 'clinicId');
  }

  @override
  Future<void> replaceMemberRoles({
    required String clinicId,
    required String memberId,
    required Set<StaffRole> roles,
    String? ownerPassword,
  }) => _complete({
    'action': 'replace_roles',
    'memberId': StaffValidation.id(memberId),
    'roles': _roleValues(roles),
    if (ownerPassword != null && ownerPassword.isNotEmpty) ...{
      '_proofPassword': ownerPassword,
      '_proofAction': 'staff_roles_replace',
      '_proofClinicId': StaffValidation.id(clinicId),
      '_proofTargetId': StaffValidation.id(memberId),
      '_proofCommand': {
        'memberId': StaffValidation.id(memberId),
        'roles': _roleValues(roles),
      },
    },
  });

  @override
  Future<void> setMemberActive({
    required String clinicId,
    required String memberId,
    required bool isActive,
    String? ownerPassword,
  }) => _complete({
    'action': 'set_active',
    'memberId': StaffValidation.id(memberId),
    'isActive': isActive,
    if (ownerPassword != null && ownerPassword.isNotEmpty) ...{
      '_proofPassword': ownerPassword,
      '_proofAction': 'staff_deactivate',
      '_proofClinicId': StaffValidation.id(clinicId),
      '_proofTargetId': StaffValidation.id(memberId),
      '_proofCommand': {
        'memberId': StaffValidation.id(memberId),
        'isActive': isActive,
      },
    },
  });

  Future<void> _complete(Map<String, dynamic> request) async {
    final response = await _source.invokeStaffAction(request);
    if (response['ok'] != true) throw const ServerFailure();
  }

  List<String> _roleValues(Set<StaffRole> roles) => StaffValidation.roles(
    roles,
  ).map((role) => role.apiValue).toList(growable: false);

  StaffMember _staffMemberFromRow(Map<String, dynamic> row) => StaffMember(
    id: _requiredString(row, 'id'),
    userId: _requiredString(row, 'user_id'),
    displayName: _requiredString(row, 'display_name'),
    email: StaffValidation.email(_requiredString(row, 'email')),
    isActive: _requiredBool(row, 'is_active'),
    roles: _rolesFromRow(row, 'clinic_member_roles'),
    deactivatedAt: _optionalDate(row, 'deactivated_at'),
  );

  StaffInvitation _invitationFromRow(Map<String, dynamic> row) =>
      StaffInvitation(
        id: _requiredString(row, 'id'),
        clinicId: _requiredString(row, 'clinic_id'),
        email: StaffValidation.email(_requiredString(row, 'email')),
        roles: _rolesFromRow(row, 'clinic_invitation_roles'),
        status:
            StaffInvitationStatus.fromApi(row['status']) ??
            (throw const ServerFailure()),
        createdAt: _requiredDate(row, 'created_at'),
        expiresAt: _requiredDate(row, 'expires_at'),
        lastSentAt: _requiredDate(row, 'last_sent_at'),
        resendCount: _requiredNonNegativeInt(row, 'resend_count'),
        acceptedAt: _optionalDate(row, 'accepted_at'),
        revokedAt: _optionalDate(row, 'revoked_at'),
      );

  StaffInvitationDelivery _deliveryFromResponse(Map<String, dynamic> row) =>
      StaffInvitationDelivery(
        invitationId: _requiredString(row, 'invitationId'),
        expiresAt: _requiredDate(row, 'expiresAt'),
      );

  Set<StaffRole> _rolesFromRow(Map<String, dynamic> row, String key) {
    final values = row[key];
    if (values is! List) throw const ServerFailure();
    final roles = values.map((value) {
      if (value is! Map) throw const ServerFailure();
      return StaffRole.fromApi(value['role']) ?? (throw const ServerFailure());
    });
    return StaffValidation.roles(roles);
  }

  String _requiredString(Map<String, dynamic> value, String key) {
    final result = value[key];
    if (result is! String || result.isEmpty) throw const ServerFailure();
    return result;
  }

  bool _requiredBool(Map<String, dynamic> value, String key) {
    final result = value[key];
    if (result is! bool) throw const ServerFailure();
    return result;
  }

  int _requiredNonNegativeInt(Map<String, dynamic> value, String key) {
    final result = value[key];
    if (result is! int || result < 0) throw const ServerFailure();
    return result;
  }

  DateTime _requiredDate(Map<String, dynamic> value, String key) {
    final result = _optionalDate(value, key);
    if (result == null) throw const ServerFailure();
    return result;
  }

  DateTime? _optionalDate(Map<String, dynamic> value, String key) {
    final raw = value[key];
    if (raw == null) return null;
    if (raw is! String) throw const ServerFailure();
    return DateTime.tryParse(raw)?.toUtc() ?? (throw const ServerFailure());
  }
}

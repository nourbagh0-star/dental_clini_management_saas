import 'package:dio/dio.dart';
import 'package:injectable/injectable.dart';

import '../../../core/error/app_failure.dart';
import '../../../core/network/dio_client.dart';
import '../../../core/network/interceptors/auth_interceptor.dart';
import '../domain/staff_models.dart';
import 'staff_data_source.dart';

@LazySingleton(as: StaffDataSource)
class SupabaseStaffDataSource implements StaffDataSource {
  SupabaseStaffDataSource(this._functions);

  final DioClient _functions;

  @override
  Future<List<Map<String, dynamic>>> getStaffMemberRows(String clinicId) =>
      _staffRows({'action': 'list_members', 'clinicId': clinicId});

  @override
  Future<List<Map<String, dynamic>>> getInvitationRows(String clinicId) =>
      _staffRows({'action': 'list_invitations', 'clinicId': clinicId});

  Future<List<Map<String, dynamic>>> _staffRows(
    Map<String, dynamic> request,
  ) async {
    final response = await invokeStaffAction(request);
    return List<Map<String, dynamic>>.from(
      response['rows'] as List? ?? const [],
    );
  }

  @override
  Future<Map<String, dynamic>> invokeStaffAction(
    Map<String, dynamic> request,
  ) async {
    try {
      final outgoing = Map<String, dynamic>.from(request);
      final password = outgoing.remove('_proofPassword');
      final proofAction = outgoing.remove('_proofAction');
      final proofClinicId = outgoing.remove('_proofClinicId');
      final proofTargetId = outgoing.remove('_proofTargetId');
      final proofCommand = outgoing.remove('_proofCommand');
      if (password is String && password.isNotEmpty) {
        final proofResponse = await _functions.client
            .post<Map<String, dynamic>>(
              'security-session',
              data: {
                'action': 'prove_owner_action',
                'actionCode': proofAction,
                'clinicId': proofClinicId,
                'targetId': proofTargetId,
                'command': proofCommand,
                'password': password,
              },
              options: Options(extra: {AuthInterceptor.requiresAuth: true}),
            );
        final proof = proofResponse.data?['proof'];
        if (proof is! String || proof.isEmpty) throw const ServerFailure();
        outgoing['proof'] = proof;
      }
      final response = await _functions.client.post<Map<String, dynamic>>(
        'staff-invitations',
        data: outgoing,
        options: Options(extra: {AuthInterceptor.requiresAuth: true}),
      );
      final body = response.data;
      if (body == null) throw const ServerFailure();
      return Map<String, dynamic>.from(body);
    } on DioException catch (error) {
      final code = _errorCode(error.response?.data);
      final staffFailure = switch (code) {
        'staff_creation_unavailable' => const StaffOperationException(
          StaffOperationIssue.accountUnavailable,
        ),
        'credentials_invalid' ||
        'owner_proof_forbidden' ||
        'owner_reauthentication_required' => const StaffOperationException(
          StaffOperationIssue.ownerReauthenticationRequired,
        ),
        'invitation_unavailable' => const StaffOperationException(
          StaffOperationIssue.invitationUnavailable,
        ),
        'member_unavailable' => const StaffOperationException(
          StaffOperationIssue.memberUnavailable,
        ),
        _ => null,
      };
      if (staffFailure != null) throw staffFailure;
      if (error.error case final AppFailure failure) throw failure;
      throw const UnknownFailure();
    } on AppFailure {
      rethrow;
    } on StaffOperationException {
      rethrow;
    } on Object {
      throw const UnknownFailure();
    }
  }

  String? _errorCode(Object? value) {
    if (value is Map<String, dynamic> && value['error'] is String) {
      return value['error'] as String;
    }
    if (value is Map && value['error'] is String) {
      return value['error'] as String;
    }
    return null;
  }
}

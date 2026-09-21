import 'package:dio/dio.dart';
import 'package:injectable/injectable.dart';

import '../../../core/error/app_failure.dart';
import '../../../core/network/dio_client.dart';
import '../../../core/network/interceptors/auth_interceptor.dart';
import '../domain/clinical_session_models.dart';
import 'clinical_session_data_source.dart';

@LazySingleton(as: ClinicalSessionDataSource)
class SupabaseClinicalSessionDataSource implements ClinicalSessionDataSource {
  SupabaseClinicalSessionDataSource(this._functions);
  final DioClient _functions;

  @override
  Future<List<Map<String, dynamic>>> sessionRows({
    required String patientId,
    required int offset,
    required int limit,
  }) => _rows({
    'action': 'read_sessions',
    'patientId': patientId,
    'offset': offset,
    'limit': limit,
  });

  @override
  Future<List<Map<String, dynamic>>> amendmentRows(String sessionId) =>
      _rows({'action': 'read_amendments', 'sessionId': sessionId});

  @override
  Future<List<Map<String, dynamic>>> eligibleAppointmentRows(
    String patientId,
  ) => _rows({'action': 'read_eligible_appointments', 'patientId': patientId});

  Future<List<Map<String, dynamic>>> _rows(Map<String, dynamic> request) async {
    final response = await invokeAction(request);
    return List<Map<String, dynamic>>.from(
      response['rows'] as List? ?? const [],
    );
  }

  @override
  Future<Map<String, dynamic>> invokeAction(
    Map<String, dynamic> request,
  ) async {
    try {
      final response = await _functions.client.post<Map<String, dynamic>>(
        'clinical-sessions',
        data: request,
        options: Options(extra: {AuthInterceptor.requiresAuth: true}),
      );
      if (response.data == null) throw const ServerFailure();
      return Map<String, dynamic>.from(response.data!);
    } on DioException catch (error) {
      final body = error.response?.data;
      final code = body is Map ? body['error'] : null;
      final issue = switch (code) {
        'clinical_session_forbidden' => ClinicalSessionOperationIssue.forbidden,
        'clinical_session_unavailable' ||
        'patient_unavailable' ||
        'appointment_unavailable' ||
        'dentist_unavailable' => ClinicalSessionOperationIssue.unavailable,
        'appointment_already_has_session' =>
          ClinicalSessionOperationIssue.appointmentHasSession,
        'appointment_not_eligible' =>
          ClinicalSessionOperationIssue.appointmentNotEligible,
        'assigned_dentist_mismatch' =>
          ClinicalSessionOperationIssue.dentistMismatch,
        'clinical_notes_required' =>
          ClinicalSessionOperationIssue.notesRequired,
        'clinical_session_draft_only' =>
          ClinicalSessionOperationIssue.draftOnly,
        'clinical_session_finalized_required' =>
          ClinicalSessionOperationIssue.finalizedRequired,
        'clinical_session_revision_conflict' =>
          ClinicalSessionOperationIssue.revisionConflict,
        'clinical_session_immutable' ||
        'clinical_session_identity_immutable' ||
        'clinical_session_amendment_immutable' =>
          ClinicalSessionOperationIssue.immutable,
        'invalid_clinical_session_input' ||
        'invalid_clinical_session_transition' ||
        'invalid_request' => ClinicalSessionOperationIssue.invalidInput,
        _ => null,
      };
      if (issue != null) throw ClinicalSessionOperationException(issue);
      if (error.error case final AppFailure failure) throw failure;
      throw const UnknownFailure();
    }
  }
}

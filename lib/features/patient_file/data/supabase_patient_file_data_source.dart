import 'package:dio/dio.dart';
import 'package:injectable/injectable.dart';

import '../../../core/error/app_failure.dart';
import '../../../core/network/dio_client.dart';
import '../../../core/network/interceptors/auth_interceptor.dart';
import '../domain/patient_file_models.dart';
import 'patient_file_data_source.dart';

@LazySingleton(as: PatientFileDataSource)
class SupabasePatientFileDataSource implements PatientFileDataSource {
  SupabasePatientFileDataSource(this._functions);
  final DioClient _functions;

  @override
  Future<List<Map<String, dynamic>>> fileRows({
    required String patientId,
    required bool includeArchived,
    required String? category,
    required int offset,
    required int limit,
  }) async {
    final response = await invokeAction({
      'action': 'read_files',
      'patientId': patientId,
      'includeArchived': includeArchived,
      'category': category,
      'offset': offset,
      'limit': limit,
    });
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
        'patient-files',
        data: request,
        options: Options(extra: {AuthInterceptor.requiresAuth: true}),
      );
      if (response.data == null) throw const ServerFailure();
      return Map<String, dynamic>.from(response.data!);
    } on DioException catch (error) {
      final body = error.response?.data;
      final code = body is Map ? body['error'] : null;
      final issue = switch (code) {
        'patient_file_forbidden' => PatientFileOperationIssue.forbidden,
        'patient_file_unavailable' ||
        'patient_unavailable' ||
        'appointment_unavailable' ||
        'clinical_session_unavailable' ||
        'replacement_file_unavailable' => PatientFileOperationIssue.unavailable,
        'patient_archived' => PatientFileOperationIssue.patientArchived,
        'patient_file_invalid_name' => PatientFileOperationIssue.invalidName,
        'patient_file_type_not_allowed' =>
          PatientFileOperationIssue.typeNotAllowed,
        'patient_file_too_large' => PatientFileOperationIssue.tooLarge,
        'patient_file_empty' => PatientFileOperationIssue.empty,
        'patient_file_upload_expired' =>
          PatientFileOperationIssue.uploadExpired,
        'patient_file_upload_missing' =>
          PatientFileOperationIssue.uploadMissing,
        'patient_file_signature_mismatch' =>
          PatientFileOperationIssue.signatureMismatch,
        'patient_file_pending_only' ||
        'patient_file_available_only' ||
        'patient_file_archived_only' ||
        'patient_file_immutable' ||
        'patient_file_identity_immutable' ||
        'invalid_patient_file_transition' =>
          PatientFileOperationIssue.invalidState,
        'patient_file_storage_unavailable' =>
          PatientFileOperationIssue.storageUnavailable,
        'invalid_patient_file_input' ||
        'invalid_request' => PatientFileOperationIssue.invalidInput,
        _ => null,
      };
      if (issue != null) throw PatientFileOperationException(issue);
      if (error.error case final AppFailure failure) throw failure;
      throw const UnknownFailure();
    }
  }
}

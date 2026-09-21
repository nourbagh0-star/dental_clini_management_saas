import 'package:dio/dio.dart';
import 'package:injectable/injectable.dart';

import '../../../core/error/app_failure.dart';
import '../../../core/network/dio_client.dart';
import '../../../core/network/interceptors/auth_interceptor.dart';
import '../domain/patient_models.dart';
import 'patient_data_source.dart';

@LazySingleton(as: PatientDataSource)
class SupabasePatientDataSource implements PatientDataSource {
  SupabasePatientDataSource(this._functions);
  final DioClient _functions;

  @override
  Future<List<Map<String, dynamic>>> searchRows({
    required String clinicId,
    required String query,
    required int offset,
    required int limit,
  }) async {
    final response = await invokePatientAction({
      'action': 'search',
      'clinicId': clinicId,
      'query': query,
      'offset': offset,
      'limit': limit,
    });
    return List<Map<String, dynamic>>.from(
      response['rows'] as List? ?? const [],
    );
  }

  @override
  Future<Map<String, dynamic>?> medicalProfileRow(String patientId) async {
    final response = await invokePatientAction({
      'action': 'medical_profile',
      'patientId': patientId,
    });
    final row = response['row'];
    return row is Map ? Map<String, dynamic>.from(row) : null;
  }

  @override
  Future<Map<String, dynamic>> invokePatientAction(
    Map<String, dynamic> request,
  ) async {
    try {
      final response = await _functions.client.post<Map<String, dynamic>>(
        'patients',
        data: request,
        options: Options(extra: {AuthInterceptor.requiresAuth: true}),
      );
      if (response.data == null) throw const ServerFailure();
      return Map<String, dynamic>.from(response.data!);
    } on DioException catch (error) {
      final body = error.response?.data;
      final code = body is Map ? body['error'] : null;
      final issue = switch (code) {
        'patient_edit_forbidden' => PatientOperationIssue.forbidden,
        'patient_unavailable' => PatientOperationIssue.unavailable,
        _ => null,
      };
      if (issue != null) throw PatientOperationException(issue);
      if (error.error case final AppFailure failure) throw failure;
      throw const UnknownFailure();
    }
  }
}

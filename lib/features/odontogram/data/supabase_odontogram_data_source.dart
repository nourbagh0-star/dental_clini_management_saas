import 'package:dio/dio.dart';
import 'package:injectable/injectable.dart';

import '../../../core/error/app_failure.dart';
import '../../../core/network/dio_client.dart';
import '../../../core/network/interceptors/auth_interceptor.dart';
import '../domain/odontogram_models.dart';
import 'odontogram_data_source.dart';

@LazySingleton(as: OdontogramDataSource)
class SupabaseOdontogramDataSource implements OdontogramDataSource {
  SupabaseOdontogramDataSource(this._functions);
  final DioClient _functions;

  @override
  Future<List<Map<String, dynamic>>> activeRows(String patientId) =>
      _rows({'action': 'read_active', 'patientId': patientId});

  @override
  Future<List<Map<String, dynamic>>> historyRows({
    required String patientId,
    required int offset,
    required int limit,
  }) => _rows({
    'action': 'read_history',
    'patientId': patientId,
    'offset': offset,
    'limit': limit,
  });

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
        'odontogram',
        data: request,
        options: Options(extra: {AuthInterceptor.requiresAuth: true}),
      );
      if (response.data == null) throw const ServerFailure();
      return Map<String, dynamic>.from(response.data!);
    } on DioException catch (error) {
      final body = error.response?.data;
      final code = body is Map ? body['error'] : null;
      final issue = switch (code) {
        'tooth_condition_edit_forbidden' => OdontogramOperationIssue.forbidden,
        'patient_unavailable' ||
        'tooth_condition_unavailable' => OdontogramOperationIssue.unavailable,
        'missing_tooth_conflict' =>
          OdontogramOperationIssue.missingToothConflict,
        'duplicate_active_tooth_condition' =>
          OdontogramOperationIssue.duplicateActiveCondition,
        'tooth_condition_not_active' =>
          OdontogramOperationIssue.conditionNotActive,
        'invalid_tooth_condition_input' =>
          OdontogramOperationIssue.invalidInput,
        _ => null,
      };
      if (issue != null) throw OdontogramOperationException(issue);
      if (error.error case final AppFailure failure) throw failure;
      throw const UnknownFailure();
    }
  }
}

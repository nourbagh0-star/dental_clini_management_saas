import 'package:dio/dio.dart';
import 'package:injectable/injectable.dart';

import '../../../core/error/app_failure.dart';
import '../../../core/network/dio_client.dart';
import '../../../core/network/interceptors/auth_interceptor.dart';
import '../domain/schedule_models.dart';
import 'schedule_data_source.dart';

@LazySingleton(as: ScheduleDataSource)
class SupabaseScheduleDataSource implements ScheduleDataSource {
  SupabaseScheduleDataSource(this._functions);

  final DioClient _functions;

  @override
  Future<List<Map<String, dynamic>>> getScheduleVersionRows(String clinicId) =>
      _rows({'action': 'list_versions', 'clinicId': clinicId});

  @override
  Future<List<Map<String, dynamic>>> getScheduleExceptionRows(
    String clinicId,
  ) => _rows({'action': 'list_exceptions', 'clinicId': clinicId});

  @override
  Future<List<Map<String, dynamic>>> getManageableDentistRows(
    String clinicId,
  ) => _rows({'action': 'list_dentists', 'clinicId': clinicId});

  Future<List<Map<String, dynamic>>> _rows(Map<String, dynamic> request) async {
    final response = await invokeScheduleAction(request);
    return List<Map<String, dynamic>>.from(
      response['rows'] as List? ?? const [],
    );
  }

  @override
  Future<Map<String, dynamic>> invokeScheduleAction(
    Map<String, dynamic> request,
  ) async {
    try {
      final response = await _functions.client.post<Map<String, dynamic>>(
        'doctor-schedules',
        data: request,
        options: Options(extra: {AuthInterceptor.requiresAuth: true}),
      );
      final body = response.data;
      if (body == null) throw const ServerFailure();
      return Map<String, dynamic>.from(body);
    } on DioException catch (error) {
      final code = _errorCode(error.response?.data);
      final issue = switch (code) {
        'schedule_edit_forbidden' => ScheduleOperationIssue.editForbidden,
        'active_dentist_required' =>
          ScheduleOperationIssue.activeDentistRequired,
        'schedule_effective_date_invalid' =>
          ScheduleOperationIssue.effectiveDateInvalid,
        'schedule_exception_unavailable' =>
          ScheduleOperationIssue.exceptionUnavailable,
        'schedule_change_affects_appointments' =>
          ScheduleOperationIssue.affectedAppointments,
        _ => null,
      };
      if (issue != null) throw ScheduleOperationException(issue);
      if (error.error case final AppFailure failure) throw failure;
      throw const UnknownFailure();
    } on AppFailure {
      rethrow;
    } on ScheduleOperationException {
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

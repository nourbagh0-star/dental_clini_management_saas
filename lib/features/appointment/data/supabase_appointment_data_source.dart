import 'package:dio/dio.dart';
import 'package:injectable/injectable.dart';

import '../../../core/error/app_failure.dart';
import '../../../core/network/dio_client.dart';
import '../../../core/network/interceptors/auth_interceptor.dart';
import '../domain/appointment_models.dart';
import 'appointment_data_source.dart';

@LazySingleton(as: AppointmentDataSource)
class SupabaseAppointmentDataSource implements AppointmentDataSource {
  SupabaseAppointmentDataSource(this._functions);
  final DioClient _functions;

  @override
  Future<List<Map<String, dynamic>>> listRows({
    required String clinicId,
    required DateTime from,
    required DateTime until,
  }) async {
    final response = await invokeAction({
      'action': 'list',
      'clinicId': clinicId,
      'from': from.toUtc().toIso8601String(),
      'until': until.toUtc().toIso8601String(),
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
        'appointments',
        data: request,
        options: Options(extra: {AuthInterceptor.requiresAuth: true}),
      );
      if (response.data == null) throw const ServerFailure();
      return Map<String, dynamic>.from(response.data!);
    } on DioException catch (error) {
      final body = error.response?.data;
      final code = body is Map ? body['error'] : null;
      final issue = switch (code) {
        'patient_unavailable' ||
        'appointment_unavailable' => AppointmentOperationIssue.unavailable,
        'appointment_action_forbidden' ||
        'active_dentist_required' => AppointmentOperationIssue.forbidden,
        'patient_overlap' => AppointmentOperationIssue.patientOverlap,
        'dentist_overlap' => AppointmentOperationIssue.dentistOverlap,
        'working_hours_conflict' => AppointmentOperationIssue.workingHours,
        'leave_conflict' => AppointmentOperationIssue.leave,
        'unavailable_conflict' => AppointmentOperationIssue.unavailablePeriod,
        'override_reason_required' =>
          AppointmentOperationIssue.overrideReasonRequired,
        'invalid_appointment_transition' =>
          AppointmentOperationIssue.invalidTransition,
        _ => null,
      };
      if (issue != null) throw AppointmentOperationException(issue);
      if (error.error case final AppFailure failure) throw failure;
      throw const UnknownFailure();
    }
  }
}

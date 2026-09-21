import 'package:dio/dio.dart';
import 'package:injectable/injectable.dart';

import '../../../core/error/app_failure.dart';
import '../../../core/network/dio_client.dart';
import '../../../core/network/interceptors/auth_interceptor.dart';
import '../domain/treatment_plan_models.dart';
import 'treatment_plan_data_source.dart';

@LazySingleton(as: TreatmentPlanDataSource)
class SupabaseTreatmentPlanDataSource implements TreatmentPlanDataSource {
  SupabaseTreatmentPlanDataSource(this._functions);
  final DioClient _functions;

  @override
  Future<List<Map<String, dynamic>>> procedureRows(String clinicId) =>
      _rows({'action': 'read_procedures', 'clinicId': clinicId});

  @override
  Future<List<Map<String, dynamic>>> planRows(String patientId) =>
      _rows({'action': 'read_plans', 'patientId': patientId});

  @override
  Future<List<Map<String, dynamic>>> itemRows(String planId) =>
      _rows({'action': 'read_items', 'planId': planId});

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
        'treatment-plans',
        data: request,
        options: Options(extra: {AuthInterceptor.requiresAuth: true}),
      );
      if (response.data == null) throw const ServerFailure();
      return Map<String, dynamic>.from(response.data!);
    } on DioException catch (error) {
      final body = error.response?.data;
      final code = body is Map ? body['error'] : null;
      final issue = switch (code) {
        'treatment_plan_edit_forbidden' =>
          TreatmentPlanOperationIssue.forbidden,
        'patient_unavailable' ||
        'procedure_unavailable' ||
        'treatment_plan_unavailable' ||
        'treatment_plan_item_unavailable' ||
        'assigned_dentist_unavailable' =>
          TreatmentPlanOperationIssue.unavailable,
        'treatment_plan_draft_only' => TreatmentPlanOperationIssue.draftOnly,
        'treatment_plan_active_required' =>
          TreatmentPlanOperationIssue.activeRequired,
        'treatment_plan_items_required' =>
          TreatmentPlanOperationIssue.itemsRequired,
        'treatment_plan_active_exists' =>
          TreatmentPlanOperationIssue.activePlanExists,
        'invalid_treatment_plan_transition' ||
        'invalid_treatment_plan_item_transition' =>
          TreatmentPlanOperationIssue.invalidTransition,
        'invalid_procedure_input' ||
        'invalid_treatment_plan_input' ||
        'invalid_treatment_plan_item_input' ||
        'invalid_treatment_plan_item_order' ||
        'invalid_request' => TreatmentPlanOperationIssue.invalidInput,
        _ => null,
      };
      if (issue != null) throw TreatmentPlanOperationException(issue);
      if (error.error case final AppFailure failure) throw failure;
      throw const UnknownFailure();
    }
  }
}

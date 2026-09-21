import 'package:dio/dio.dart';
import 'package:injectable/injectable.dart';

import '../../../core/error/app_failure.dart';
import '../../../core/network/dio_client.dart';
import '../../../core/network/interceptors/auth_interceptor.dart';
import '../domain/billing_models.dart';
import 'billing_data_source.dart';

@LazySingleton(as: BillingDataSource)
class SupabaseBillingDataSource implements BillingDataSource {
  SupabaseBillingDataSource(this._functions);
  final DioClient _functions;

  @override
  Future<List<Map<String, dynamic>>> invoiceRows({
    required String clinicId,
    String? patientId,
  }) => _billingRows({
    'action': 'read_invoices',
    'clinicId': clinicId,
    'patientId': patientId,
  });

  @override
  Future<List<Map<String, dynamic>>> itemRows(String invoiceId) =>
      _billingRows({'action': 'read_items', 'invoiceId': invoiceId});

  @override
  Future<List<Map<String, dynamic>>> procedureRows(String clinicId) =>
      _billingRows({'action': 'read_procedures', 'clinicId': clinicId});

  @override
  Future<List<Map<String, dynamic>>> paymentRows(String invoiceId) =>
      _billingRows({'action': 'read_payments', 'invoiceId': invoiceId});

  @override
  Future<Map<String, dynamic>?> creditRow(
    String patientId,
    String currencyCode,
  ) async {
    final response = await _invokeBilling({
      'action': 'read_credit',
      'patientId': patientId,
      'currencyCode': currencyCode,
    });
    final row = response['row'];
    return row is Map ? Map<String, dynamic>.from(row) : null;
  }

  Future<List<Map<String, dynamic>>> _billingRows(
    Map<String, dynamic> request,
  ) async {
    final response = await _invokeBilling(request);
    return List<Map<String, dynamic>>.from(
      response['rows'] as List? ?? const [],
    );
  }

  @override
  Future<Map<String, dynamic>> invokeBilling(Map<String, dynamic> request) =>
      _invokeBilling(request);

  @override
  Future<Map<String, dynamic>> invokePdf(Map<String, dynamic> request) =>
      _invoke('invoice-pdf', request);

  Future<Map<String, dynamic>> _invokeBilling(
    Map<String, dynamic> request,
  ) async {
    final outgoing = Map<String, dynamic>.from(request);
    final password = outgoing.remove('_proofPassword');
    final proofAction = outgoing.remove('_proofAction');
    final proofClinicId = outgoing.remove('_proofClinicId');
    final proofTargetId = outgoing.remove('_proofTargetId');
    final proofCommand = outgoing.remove('_proofCommand');
    if (password is String && password.isNotEmpty) {
      final proofResponse = await _invoke('security-session', {
        'action': 'prove_owner_action',
        'actionCode': proofAction,
        'clinicId': proofClinicId,
        'targetId': proofTargetId,
        'command': proofCommand,
        'password': password,
      });
      final proof = proofResponse['proof'];
      if (proof is! String || proof.isEmpty) throw const ServerFailure();
      outgoing['proof'] = proof;
    }
    return _invoke('billing', outgoing);
  }

  Future<Map<String, dynamic>> _invoke(
    String function,
    Map<String, dynamic> request,
  ) async {
    try {
      final response = await _functions.client.post<Map<String, dynamic>>(
        function,
        data: request,
        options: Options(extra: {AuthInterceptor.requiresAuth: true}),
      );
      if (response.data == null) throw const ServerFailure();
      return Map<String, dynamic>.from(response.data!);
    } on DioException catch (error) {
      final body = error.response?.data;
      final code = body is Map ? body['error'] : null;
      final issue = switch (code) {
        'credentials_invalid' ||
        'owner_proof_forbidden' ||
        'owner_reauthentication_required' =>
          BillingOperationIssue.ownerReauthenticationRequired,
        'billing_forbidden' => BillingOperationIssue.forbidden,
        'invoice_unavailable' ||
        'financial_entry_unavailable' ||
        'procedure_unavailable' ||
        'treatment_plan_item_unavailable' => BillingOperationIssue.unavailable,
        'patient_archived' => BillingOperationIssue.archivedPatient,
        'invoice_pdf_pending' => BillingOperationIssue.pendingPdf,
        'invoice_pdf_generation_failed' ||
        'invoice_pdf_unavailable' ||
        'invoice_pdf_stale' => BillingOperationIssue.pdfUnavailable,
        'invoice_revision_conflict' ||
        'invoice_draft_only' ||
        'invoice_content_approved' ||
        'invoice_treatment_item_already_claimed' ||
        'invoice_clinical_approval_required' ||
        'invoice_finalized_only' ||
        'invoice_already_paid' ||
        'invoice_nonzero_paid_balance' ||
        'invoice_not_cancellable' ||
        'billing_command_conflict' ||
        'financial_entry_not_reversible' ||
        'financial_reversal_exceeds_available' ||
        'insufficient_patient_credit' ||
        'credit_exceeds_invoice_balance' => BillingOperationIssue.conflict,
        'invalid_request' ||
        'invalid_billing_input' ||
        'invalid_invoice_item' ||
        'invalid_invoice_financials' ||
        'invalid_payment' ||
        'invalid_financial_reversal' ||
        'invalid_credit_application' ||
        'invoice_items_required' => BillingOperationIssue.invalidInput,
        _ => null,
      };
      if (issue != null) throw BillingOperationException(issue);
      if (error.error case final AppFailure failure) throw failure;
      throw const UnknownFailure();
    }
  }
}

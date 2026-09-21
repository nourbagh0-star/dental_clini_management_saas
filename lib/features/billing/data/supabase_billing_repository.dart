import 'dart:math';

import 'package:injectable/injectable.dart';

import '../../../core/config/app_config.dart';
import '../../../core/value/money.dart';
import '../../treatment_plan/domain/treatment_plan_models.dart';
import '../domain/billing_models.dart';
import '../domain/billing_repository.dart';
import 'billing_data_source.dart';

@LazySingleton(as: BillingRepository)
class SupabaseBillingRepository implements BillingRepository {
  SupabaseBillingRepository(this._source, this._config);
  final BillingDataSource _source;
  final AppConfig _config;

  @override
  Future<List<BillingInvoice>> invoices({
    required String clinicId,
    String? patientId,
  }) async => (await _source.invoiceRows(
    clinicId: clinicId,
    patientId: patientId,
  )).map(_invoice).toList(growable: false);

  @override
  Future<List<BillingInvoiceItem>> items(String invoiceId) async =>
      (await _source.itemRows(invoiceId)).map(_item).toList(growable: false);

  @override
  Future<List<ClinicProcedure>> procedures(String clinicId) async =>
      (await _source.procedureRows(
        clinicId,
      )).map(_procedure).toList(growable: false);

  @override
  Future<List<EligibleTreatmentItem>> eligibleTreatmentItems(
    String patientId,
  ) async {
    final response = await _source.invokeBilling({
      'action': 'eligible_treatment_items',
      'patientId': patientId,
    });
    return (response['items'] as List<dynamic>? ?? const [])
        .map((value) => _eligible(Map<String, dynamic>.from(value as Map)))
        .toList(growable: false);
  }

  @override
  Future<List<BillingPayment>> payments(String invoiceId) async =>
      (await _source.paymentRows(
        invoiceId,
      )).map(_payment).toList(growable: false);

  @override
  Future<PatientCredit?> credit(String patientId, String currencyCode) async {
    final row = await _source.creditRow(patientId, currencyCode);
    return row == null
        ? null
        : PatientCredit(
            patientId: row['patient_id'] as String,
            currencyCode: row['currency_code'] as String,
            balance: _money(row['balance']),
          );
  }

  @override
  Future<List<FinancialEntry>> financialEntries(String invoiceId) async {
    final response = await _source.invokeBilling({
      'action': 'financial_entries',
      'invoiceId': invoiceId,
    });
    return (response['entries'] as List<dynamic>? ?? const [])
        .map((value) => _entry(Map<String, dynamic>.from(value as Map)))
        .toList(growable: false);
  }

  @override
  Future<String> createDraft(String patientId, InvoiceLocale locale) async {
    final response = await _source.invokeBilling({
      'action': 'create_invoice_draft',
      'patientId': patientId,
      'locale': locale.apiValue,
      'commandId': _commandId(),
    });
    return response['invoiceId'] as String;
  }

  @override
  Future<void> addItem({
    required String invoiceId,
    required String procedureId,
    required String quantity,
    required int revision,
    String? treatmentPlanItemId,
  }) => _source.invokeBilling({
    'action': 'add_invoice_item',
    'invoiceId': invoiceId,
    'procedureId': procedureId,
    'treatmentPlanItemId': treatmentPlanItemId,
    'quantity': quantity,
    'revision': revision,
  });

  @override
  Future<void> updateItem({
    required String itemId,
    required String quantity,
    required int revision,
  }) => _source.invokeBilling({
    'action': 'update_invoice_item',
    'itemId': itemId,
    'quantity': quantity,
    'revision': revision,
  });

  @override
  Future<void> removeItem(String itemId, int revision) => _source.invokeBilling(
    {'action': 'remove_invoice_item', 'itemId': itemId, 'revision': revision},
  );

  @override
  Future<void> approveContent(String invoiceId, int revision, bool approved) =>
      _source.invokeBilling({
        'action': 'approve_invoice_content',
        'invoiceId': invoiceId,
        'revision': revision,
        'approved': approved,
      });

  @override
  Future<void> setFinancials(
    String invoiceId,
    int revision,
    InvoiceFinancialDraft draft,
  ) => _source.invokeBilling({
    'action': 'set_invoice_financials',
    'invoiceId': invoiceId,
    'revision': revision,
    'itemPrices': draft.itemPrices.entries
        .map(
          (entry) => {
            'itemId': entry.key,
            'unitPrice': entry.value.toDecimalString(),
          },
        )
        .toList(growable: false),
    'discountType': draft.discountType.apiValue,
    'discountValue': draft.discountValue.toDecimalString(),
    'taxRate': draft.taxRate.toDecimalString(),
    'locale': draft.locale.apiValue,
  });

  @override
  Future<void> finalize(String invoiceId, int revision) =>
      _source.invokeBilling({
        'action': 'finalize_invoice',
        'invoiceId': invoiceId,
        'revision': revision,
        'commandId': _commandId(),
      });

  @override
  Future<void> cancel(String invoiceId, int revision, String reason) =>
      _source.invokeBilling({
        'action': 'cancel_invoice',
        'invoiceId': invoiceId,
        'revision': revision,
        'reason': reason,
      });

  @override
  Future<void> recordPayment({
    required String invoiceId,
    required Money amount,
    required BillingPaymentMethod method,
    required DateTime receivedAt,
    String? reference,
  }) => _source.invokeBilling({
    'action': 'record_payment',
    'invoiceId': invoiceId,
    'amount': amount.toDecimalString(),
    'method': method.apiValue,
    'reference': reference,
    'receivedAt': receivedAt.toUtc().toIso8601String(),
    'commandId': _commandId(),
  });

  @override
  Future<void> applyCredit(String invoiceId, Money amount) =>
      _source.invokeBilling({
        'action': 'apply_patient_credit',
        'invoiceId': invoiceId,
        'amount': amount.toDecimalString(),
        'commandId': _commandId(),
      });

  @override
  Future<void> reverseEntry({
    required String clinicId,
    required String entryId,
    required Money amount,
    required bool refund,
    required String reason,
    required String ownerPassword,
  }) {
    final input = {
      'entryId': entryId,
      'amount': amount.toDecimalString(),
      'reversalAction': refund ? 'refund' : 'correction',
      'reason': reason,
    };
    return _source.invokeBilling({
      'action': 'reverse_financial_entry',
      ...input,
      'commandId': _commandId(),
      '_proofPassword': ownerPassword,
      '_proofAction': 'financial_entry_reverse',
      '_proofClinicId': clinicId,
      '_proofTargetId': entryId,
      '_proofCommand': input,
    });
  }

  @override
  Future<InvoicePdfAccess> invoicePdf(
    String invoiceId,
    InvoiceLocale locale,
  ) async {
    final response = await _source.invokePdf({
      'invoiceId': invoiceId,
      'locale': locale.apiValue,
    });
    final raw = Uri.parse(response['url'] as String);
    final url = raw.hasScheme ? raw : _config.supabaseUrl?.resolveUri(raw);
    if (url == null) {
      throw const BillingOperationException(
        BillingOperationIssue.pdfUnavailable,
      );
    }
    return InvoicePdfAccess(
      url: url,
      expiresIn: Duration(seconds: response['expiresIn'] as int),
    );
  }

  BillingInvoice _invoice(Map<String, dynamic> row) => BillingInvoice(
    id: row['id'] as String,
    clinicId: row['clinic_id'] as String,
    patientId: row['patient_id'] as String,
    patientDisplayName: row['patient_display_name'] as String?,
    patientDisplayNumber: row['patient_display_number'] as String?,
    invoiceNumber: row['invoice_number'] as String?,
    documentStatus: InvoiceDocumentStatus.fromApi(row['document_status']),
    paymentStatus: InvoicePaymentStatus.fromApi(row['payment_status']),
    currencyCode: row['currency_code'] as String,
    discountType: InvoiceDiscountType.fromApi(row['discount_type']),
    discountValue: _money(row['discount_value']),
    discountAmount: _money(row['discount_amount']),
    taxRate: _money(row['tax_rate']),
    subtotal: _money(row['subtotal']),
    taxAmount: _money(row['tax_amount']),
    total: _money(row['total']),
    paidAmount: _money(row['paid_amount']),
    outstandingBalance: _money(row['outstanding_balance']),
    locale: InvoiceLocale.fromApi(row['document_locale']),
    preparedBy: row['prepared_by'] as String,
    clinicalApprovedAt: _date(row['clinical_approved_at']),
    finalizedAt: _date(row['finalized_at']),
    cancelledAt: _date(row['cancelled_at']),
    cancellationReason: row['cancellation_reason'] as String?,
    revision: row['revision'] as int,
    financialRevision: (row['financial_revision'] as num).toInt(),
    createdAt: _date(row['created_at'])!,
    updatedAt: _date(row['updated_at'])!,
  );

  BillingInvoiceItem _item(Map<String, dynamic> row) => BillingInvoiceItem(
    id: row['id'] as String,
    invoiceId: row['invoice_id'] as String,
    procedureId: row['procedure_id'] as String,
    treatmentPlanItemId: row['treatment_plan_item_id'] as String?,
    procedureName: row['procedure_name_snapshot'] as String,
    category: row['category_snapshot'] as String,
    description: row['description_snapshot'] as String?,
    toothNumber: row['tooth_number_snapshot'] as int?,
    quantity: row['quantity'] as String,
    unitPrice: _money(row['unit_price']),
    lineTotal: _money(row['line_total']),
    sortOrder: row['sort_order'] as int,
  );

  ClinicProcedure _procedure(Map<String, dynamic> row) => ClinicProcedure(
    id: row['id'] as String,
    clinicId: row['clinic_id'] as String,
    name: row['name'] as String,
    category: row['category'] as String,
    defaultPrice: _money(row['default_price']),
    durationMinutes: row['duration_minutes'] as int,
    active: row['active'] as bool,
  );

  EligibleTreatmentItem _eligible(Map<String, dynamic> row) =>
      EligibleTreatmentItem(
        id: row['item_id'] as String,
        procedureId: row['procedure_id'] as String,
        procedureName: row['procedure_name'] as String,
        estimatedPrice: _money(row['estimated_price']),
        status: row['item_status'] as String,
        toothNumber: row['tooth_number'] as int?,
        description: row['description'] as String?,
      );

  BillingPayment _payment(Map<String, dynamic> row) => BillingPayment(
    id: row['id'] as String,
    invoiceId: row['received_for_invoice_id'] as String,
    amount: _money(row['amount_received']),
    method: BillingPaymentMethod.values.firstWhere(
      (method) => method.apiValue == row['method'],
    ),
    reference: row['reference'] as String?,
    receivedAt: _date(row['received_at'])!,
  );

  FinancialEntry _entry(Map<String, dynamic> row) => FinancialEntry(
    id: row['entry_id'] as String,
    kind: row['kind'] as String,
    amount: _money(row['amount']),
    reversibleRemaining: _money(row['reversible_remaining']),
    reason: row['reason'] as String?,
    createdAt: _date(row['created_at'])!,
  );

  Money _money(Object? value) => Money.parseCanonical(value as String);
  DateTime? _date(Object? value) =>
      value is String ? DateTime.parse(value).toUtc() : null;

  String _commandId() {
    final bytes = List<int>.generate(16, (_) => Random.secure().nextInt(256));
    bytes[6] = (bytes[6] & 0x0f) | 0x40;
    bytes[8] = (bytes[8] & 0x3f) | 0x80;
    final value = bytes
        .map((byte) => byte.toRadixString(16).padLeft(2, '0'))
        .join();
    return '${value.substring(0, 8)}-${value.substring(8, 12)}-'
        '${value.substring(12, 16)}-${value.substring(16, 20)}-'
        '${value.substring(20)}';
  }
}

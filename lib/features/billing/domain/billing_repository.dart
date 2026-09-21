import '../../../core/value/money.dart';
import '../../treatment_plan/domain/treatment_plan_models.dart';
import 'billing_models.dart';

abstract class BillingRepository {
  Future<List<BillingInvoice>> invoices({
    required String clinicId,
    String? patientId,
  });
  Future<List<BillingInvoiceItem>> items(String invoiceId);
  Future<List<ClinicProcedure>> procedures(String clinicId);
  Future<List<EligibleTreatmentItem>> eligibleTreatmentItems(String patientId);
  Future<List<BillingPayment>> payments(String invoiceId);
  Future<PatientCredit?> credit(String patientId, String currencyCode);
  Future<List<FinancialEntry>> financialEntries(String invoiceId);

  Future<String> createDraft(String patientId, InvoiceLocale locale);
  Future<void> addItem({
    required String invoiceId,
    required String procedureId,
    required String quantity,
    required int revision,
    String? treatmentPlanItemId,
  });
  Future<void> updateItem({
    required String itemId,
    required String quantity,
    required int revision,
  });
  Future<void> removeItem(String itemId, int revision);
  Future<void> approveContent(String invoiceId, int revision, bool approved);
  Future<void> setFinancials(
    String invoiceId,
    int revision,
    InvoiceFinancialDraft draft,
  );
  Future<void> finalize(String invoiceId, int revision);
  Future<void> cancel(String invoiceId, int revision, String reason);
  Future<void> recordPayment({
    required String invoiceId,
    required Money amount,
    required BillingPaymentMethod method,
    required DateTime receivedAt,
    String? reference,
  });
  Future<void> applyCredit(String invoiceId, Money amount);
  Future<void> reverseEntry({
    required String clinicId,
    required String entryId,
    required Money amount,
    required bool refund,
    required String reason,
    required String ownerPassword,
  });
  Future<InvoicePdfAccess> invoicePdf(String invoiceId, InvoiceLocale locale);
}

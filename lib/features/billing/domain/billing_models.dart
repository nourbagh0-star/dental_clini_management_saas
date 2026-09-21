import '../../../core/value/money.dart';

enum InvoiceDocumentStatus {
  draft,
  finalized,
  cancelled;

  static InvoiceDocumentStatus fromApi(Object? value) => switch (value) {
    'finalized' => InvoiceDocumentStatus.finalized,
    'cancelled' => InvoiceDocumentStatus.cancelled,
    _ => InvoiceDocumentStatus.draft,
  };
}

enum InvoicePaymentStatus {
  unpaid,
  partiallyPaid,
  paid;

  static InvoicePaymentStatus fromApi(Object? value) => switch (value) {
    'partially_paid' => InvoicePaymentStatus.partiallyPaid,
    'paid' => InvoicePaymentStatus.paid,
    _ => InvoicePaymentStatus.unpaid,
  };
}

enum InvoiceDiscountType {
  none,
  fixed,
  percentage;

  String get apiValue => name;

  static InvoiceDiscountType fromApi(Object? value) => switch (value) {
    'fixed' => InvoiceDiscountType.fixed,
    'percentage' => InvoiceDiscountType.percentage,
    _ => InvoiceDiscountType.none,
  };
}

enum InvoiceLocale {
  english('en'),
  russian('ru'),
  arabic('ar');

  const InvoiceLocale(this.apiValue);
  final String apiValue;

  static InvoiceLocale fromApi(Object? value) => switch (value) {
    'ru' => InvoiceLocale.russian,
    'ar' => InvoiceLocale.arabic,
    _ => InvoiceLocale.english,
  };
}

enum BillingPaymentMethod {
  cash('cash'),
  card('card'),
  bankTransfer('bank_transfer'),
  other('other');

  const BillingPaymentMethod(this.apiValue);
  final String apiValue;
}

class BillingInvoice {
  const BillingInvoice({
    required this.id,
    required this.clinicId,
    required this.patientId,
    required this.documentStatus,
    required this.paymentStatus,
    required this.currencyCode,
    required this.discountType,
    required this.discountValue,
    required this.discountAmount,
    required this.taxRate,
    required this.subtotal,
    required this.taxAmount,
    required this.total,
    required this.paidAmount,
    required this.outstandingBalance,
    required this.locale,
    required this.preparedBy,
    required this.revision,
    required this.financialRevision,
    required this.createdAt,
    required this.updatedAt,
    this.patientDisplayName,
    this.patientDisplayNumber,
    this.invoiceNumber,
    this.clinicalApprovedAt,
    this.finalizedAt,
    this.cancelledAt,
    this.cancellationReason,
  });

  final String id;
  final String clinicId;
  final String patientId;
  final String? patientDisplayName;
  final String? patientDisplayNumber;
  final String? invoiceNumber;
  final InvoiceDocumentStatus documentStatus;
  final InvoicePaymentStatus paymentStatus;
  final String currencyCode;
  final InvoiceDiscountType discountType;
  final Money discountValue;
  final Money discountAmount;
  final Money taxRate;
  final Money subtotal;
  final Money taxAmount;
  final Money total;
  final Money paidAmount;
  final Money outstandingBalance;
  final InvoiceLocale locale;
  final String preparedBy;
  final DateTime? clinicalApprovedAt;
  final DateTime? finalizedAt;
  final DateTime? cancelledAt;
  final String? cancellationReason;
  final int revision;
  final int financialRevision;
  final DateTime createdAt;
  final DateTime updatedAt;

  bool get isDraft => documentStatus == InvoiceDocumentStatus.draft;
  bool get isFinalized => documentStatus == InvoiceDocumentStatus.finalized;
  bool get isClinicallyApproved => clinicalApprovedAt != null;
}

class BillingInvoiceItem {
  const BillingInvoiceItem({
    required this.id,
    required this.invoiceId,
    required this.procedureId,
    required this.procedureName,
    required this.category,
    required this.quantity,
    required this.unitPrice,
    required this.lineTotal,
    required this.sortOrder,
    this.treatmentPlanItemId,
    this.description,
    this.toothNumber,
  });

  final String id;
  final String invoiceId;
  final String procedureId;
  final String? treatmentPlanItemId;
  final String procedureName;
  final String category;
  final String? description;
  final int? toothNumber;
  final String quantity;
  final Money unitPrice;
  final Money lineTotal;
  final int sortOrder;
}

class EligibleTreatmentItem {
  const EligibleTreatmentItem({
    required this.id,
    required this.procedureId,
    required this.procedureName,
    required this.estimatedPrice,
    required this.status,
    this.toothNumber,
    this.description,
  });
  final String id;
  final String procedureId;
  final String procedureName;
  final Money estimatedPrice;
  final String status;
  final int? toothNumber;
  final String? description;
}

class BillingPayment {
  const BillingPayment({
    required this.id,
    required this.invoiceId,
    required this.amount,
    required this.method,
    required this.receivedAt,
    this.reference,
  });
  final String id;
  final String invoiceId;
  final Money amount;
  final BillingPaymentMethod method;
  final String? reference;
  final DateTime receivedAt;
}

class PatientCredit {
  const PatientCredit({
    required this.patientId,
    required this.currencyCode,
    required this.balance,
  });
  final String patientId;
  final String currencyCode;
  final Money balance;
}

class FinancialEntry {
  const FinancialEntry({
    required this.id,
    required this.kind,
    required this.amount,
    required this.reversibleRemaining,
    required this.createdAt,
    this.reason,
  });
  final String id;
  final String kind;
  final Money amount;
  final Money reversibleRemaining;
  final String? reason;
  final DateTime createdAt;
}

class InvoiceFinancialDraft {
  const InvoiceFinancialDraft({
    required this.itemPrices,
    required this.discountType,
    required this.discountValue,
    required this.taxRate,
    required this.locale,
  });
  final Map<String, Money> itemPrices;
  final InvoiceDiscountType discountType;
  final Money discountValue;
  final Money taxRate;
  final InvoiceLocale locale;
}

class InvoicePdfAccess {
  const InvoicePdfAccess({required this.url, required this.expiresIn});
  final Uri url;
  final Duration expiresIn;
}

enum BillingOperationIssue {
  ownerReauthenticationRequired,
  forbidden,
  unavailable,
  invalidInput,
  conflict,
  archivedPatient,
  pendingPdf,
  pdfUnavailable,
}

class BillingOperationException implements Exception {
  const BillingOperationException(this.issue);
  final BillingOperationIssue issue;
}

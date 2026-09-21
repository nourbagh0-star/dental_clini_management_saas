import 'package:bloc_test/bloc_test.dart';
import 'package:dental_clini_management_saas/core/value/money.dart';
import 'package:dental_clini_management_saas/features/billing/domain/billing_models.dart';
import 'package:dental_clini_management_saas/features/billing/domain/billing_repository.dart';
import 'package:dental_clini_management_saas/features/billing/presentation/billing_cubit.dart';
import 'package:dental_clini_management_saas/features/treatment_plan/domain/treatment_plan_models.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  blocTest<BillingCubit, BillingState>(
    'loads a patient invoice with exact monetary values',
    build: () => BillingCubit(_FakeBillingRepository()),
    act: (cubit) => cubit.load(
      clinicId: 'clinic-1',
      patientId: 'patient-1',
      roles: {'dentist'},
    ),
    verify: (cubit) {
      expect(cubit.state.status, BillingLoadStatus.ready);
      expect(cubit.state.selectedInvoice?.total.minorUnits, 120050);
      expect(cubit.state.items.single.unitPrice.minorUnits, 120050);
      expect(cubit.state.canPrepare, isTrue);
      expect(cubit.state.canRecordPayments, isFalse);
    },
  );

  blocTest<BillingCubit, BillingState>(
    'creates and selects a new draft for a patient',
    build: () => BillingCubit(_FakeBillingRepository()),
    act: (cubit) async {
      await cubit.load(
        clinicId: 'clinic-1',
        patientId: 'patient-1',
        roles: {'dentist'},
      );
      await cubit.createDraft(InvoiceLocale.arabic);
    },
    verify: (cubit) {
      expect(cubit.state.selectedInvoiceId, 'invoice-2');
      expect(cubit.state.selectedInvoice?.locale, InvoiceLocale.arabic);
    },
  );
}

class _FakeBillingRepository implements BillingRepository {
  final invoicesList = <BillingInvoice>[_invoice('invoice-1')];

  @override
  Future<List<BillingInvoice>> invoices({
    required String clinicId,
    String? patientId,
  }) async => List.unmodifiable(invoicesList);

  @override
  Future<List<BillingInvoiceItem>> items(String invoiceId) async => [
    BillingInvoiceItem(
      id: 'item-1',
      invoiceId: invoiceId,
      procedureId: 'procedure-1',
      procedureName: 'Crown',
      category: 'Restoration',
      quantity: '1.00',
      unitPrice: const Money.fromMinorUnits(120050),
      lineTotal: const Money.fromMinorUnits(120050),
      sortOrder: 0,
    ),
  ];

  @override
  Future<List<ClinicProcedure>> procedures(String clinicId) async => const [];

  @override
  Future<List<EligibleTreatmentItem>> eligibleTreatmentItems(
    String patientId,
  ) async => const [];

  @override
  Future<List<BillingPayment>> payments(String invoiceId) async => const [];

  @override
  Future<PatientCredit?> credit(String patientId, String currencyCode) async =>
      null;

  @override
  Future<List<FinancialEntry>> financialEntries(String invoiceId) async =>
      const [];

  @override
  Future<String> createDraft(String patientId, InvoiceLocale locale) async {
    invoicesList.insert(0, _invoice('invoice-2', locale: locale));
    return 'invoice-2';
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

BillingInvoice _invoice(
  String id, {
  InvoiceLocale locale = InvoiceLocale.english,
}) => BillingInvoice(
  id: id,
  clinicId: 'clinic-1',
  patientId: 'patient-1',
  documentStatus: InvoiceDocumentStatus.draft,
  paymentStatus: InvoicePaymentStatus.unpaid,
  currencyCode: 'RUB',
  discountType: InvoiceDiscountType.none,
  discountValue: Money.zero,
  discountAmount: Money.zero,
  taxRate: Money.zero,
  subtotal: const Money.fromMinorUnits(120050),
  taxAmount: Money.zero,
  total: const Money.fromMinorUnits(120050),
  paidAmount: Money.zero,
  outstandingBalance: const Money.fromMinorUnits(120050),
  locale: locale,
  preparedBy: 'dentist-1',
  revision: 1,
  financialRevision: 0,
  createdAt: DateTime.utc(2026, 9, 11),
  updatedAt: DateTime.utc(2026, 9, 11),
);

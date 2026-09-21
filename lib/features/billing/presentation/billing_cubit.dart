import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';

import '../../../core/error/app_failure.dart';
import '../../../core/value/money.dart';
import '../../treatment_plan/domain/treatment_plan_models.dart';
import '../domain/billing_models.dart';
import '../domain/billing_repository.dart';

enum BillingLoadStatus { initial, loading, ready, failure }

class BillingState {
  const BillingState({
    this.status = BillingLoadStatus.initial,
    this.clinicId,
    this.patientId,
    this.invoices = const [],
    this.selectedInvoiceId,
    this.items = const [],
    this.procedures = const [],
    this.eligibleItems = const [],
    this.payments = const [],
    this.entries = const [],
    this.credit,
    this.canPrepare = false,
    this.canManageFinancials = false,
    this.canRecordPayments = false,
    this.mutating = false,
    this.failure,
    this.issue,
  });

  final BillingLoadStatus status;
  final String? clinicId;
  final String? patientId;
  final List<BillingInvoice> invoices;
  final String? selectedInvoiceId;
  final List<BillingInvoiceItem> items;
  final List<ClinicProcedure> procedures;
  final List<EligibleTreatmentItem> eligibleItems;
  final List<BillingPayment> payments;
  final List<FinancialEntry> entries;
  final PatientCredit? credit;
  final bool canPrepare;
  final bool canManageFinancials;
  final bool canRecordPayments;
  final bool mutating;
  final AppFailure? failure;
  final BillingOperationIssue? issue;

  BillingInvoice? get selectedInvoice {
    for (final invoice in invoices) {
      if (invoice.id == selectedInvoiceId) return invoice;
    }
    return null;
  }

  BillingState copyWith({
    BillingLoadStatus? status,
    String? clinicId,
    String? patientId,
    List<BillingInvoice>? invoices,
    String? selectedInvoiceId,
    bool clearSelectedInvoice = false,
    List<BillingInvoiceItem>? items,
    List<ClinicProcedure>? procedures,
    List<EligibleTreatmentItem>? eligibleItems,
    List<BillingPayment>? payments,
    List<FinancialEntry>? entries,
    PatientCredit? credit,
    bool clearCredit = false,
    bool? canPrepare,
    bool? canManageFinancials,
    bool? canRecordPayments,
    bool? mutating,
    AppFailure? failure,
    bool clearFailure = false,
    BillingOperationIssue? issue,
    bool clearIssue = false,
  }) => BillingState(
    status: status ?? this.status,
    clinicId: clinicId ?? this.clinicId,
    patientId: patientId ?? this.patientId,
    invoices: invoices ?? this.invoices,
    selectedInvoiceId: clearSelectedInvoice
        ? null
        : selectedInvoiceId ?? this.selectedInvoiceId,
    items: items ?? this.items,
    procedures: procedures ?? this.procedures,
    eligibleItems: eligibleItems ?? this.eligibleItems,
    payments: payments ?? this.payments,
    entries: entries ?? this.entries,
    credit: clearCredit ? null : credit ?? this.credit,
    canPrepare: canPrepare ?? this.canPrepare,
    canManageFinancials: canManageFinancials ?? this.canManageFinancials,
    canRecordPayments: canRecordPayments ?? this.canRecordPayments,
    mutating: mutating ?? this.mutating,
    failure: clearFailure ? null : failure ?? this.failure,
    issue: clearIssue ? null : issue ?? this.issue,
  );
}

@lazySingleton
class BillingCubit extends Cubit<BillingState> {
  BillingCubit(this._repository) : super(const BillingState());
  final BillingRepository _repository;
  int _request = 0;

  Future<void> load({
    required String clinicId,
    required String? patientId,
    required Set<String> roles,
  }) async {
    final request = ++_request;
    final canPrepare = roles.contains('dentist');
    final canManage = roles.contains('owner');
    final canPay = canManage || roles.contains('receptionist');
    emit(
      BillingState(
        status: BillingLoadStatus.loading,
        clinicId: clinicId,
        patientId: patientId,
        canPrepare: canPrepare,
        canManageFinancials: canManage,
        canRecordPayments: canPay,
      ),
    );
    try {
      final invoices = await _repository.invoices(
        clinicId: clinicId,
        patientId: patientId,
      );
      if (isClosed || request != _request) return;
      emit(
        state.copyWith(
          status: BillingLoadStatus.ready,
          invoices: invoices,
          clearFailure: true,
          clearIssue: true,
        ),
      );
      if (invoices.isNotEmpty) await selectInvoice(invoices.first.id);
    } on AppFailure catch (failure) {
      _failure(request, failure);
    } on BillingOperationException catch (error) {
      _issue(request, error.issue);
    } on Object {
      _failure(request, const UnknownFailure());
    }
  }

  Future<void> selectInvoice(String invoiceId) async {
    if (state.mutating) return;
    final invoice = state.invoices
        .where((item) => item.id == invoiceId)
        .firstOrNull;
    if (invoice == null) return;
    final request = ++_request;
    emit(
      state.copyWith(
        status: BillingLoadStatus.loading,
        selectedInvoiceId: invoiceId,
        items: const [],
        payments: const [],
        entries: const [],
        eligibleItems: const [],
        clearCredit: true,
        clearFailure: true,
        clearIssue: true,
      ),
    );
    try {
      final results = await Future.wait<Object?>([
        if (state.canPrepare || state.canManageFinancials)
          _repository.items(invoiceId)
        else
          Future.value(const <BillingInvoiceItem>[]),
        if (state.canPrepare)
          _repository.procedures(invoice.clinicId)
        else
          Future.value(const <ClinicProcedure>[]),
        if (state.canPrepare)
          _repository.eligibleTreatmentItems(invoice.patientId)
        else
          Future.value(const <EligibleTreatmentItem>[]),
        if (state.canRecordPayments)
          _repository.payments(invoiceId)
        else
          Future.value(const <BillingPayment>[]),
        if (state.canRecordPayments)
          _repository.credit(invoice.patientId, invoice.currencyCode)
        else
          Future<PatientCredit?>.value(),
        if (state.canManageFinancials)
          _repository.financialEntries(invoiceId)
        else
          Future.value(const <FinancialEntry>[]),
      ]);
      if (isClosed || request != _request) return;
      emit(
        state.copyWith(
          status: BillingLoadStatus.ready,
          items: results[0] as List<BillingInvoiceItem>,
          procedures: results[1] as List<ClinicProcedure>,
          eligibleItems: results[2] as List<EligibleTreatmentItem>,
          payments: results[3] as List<BillingPayment>,
          credit: results[4] as PatientCredit?,
          clearCredit: results[4] == null,
          entries: results[5] as List<FinancialEntry>,
        ),
      );
    } on BillingOperationException catch (error) {
      _issue(request, error.issue);
    } on AppFailure catch (failure) {
      _failure(request, failure);
    } on Object {
      _failure(request, const UnknownFailure());
    }
  }

  Future<bool> createDraft(InvoiceLocale locale) async {
    final patientId = state.patientId;
    if (patientId == null || !state.canPrepare) return false;
    String? createdId;
    final succeeded = await _mutate(() async {
      createdId = await _repository.createDraft(patientId, locale);
    }, selectCreated: () => createdId);
    return succeeded;
  }

  Future<bool> addCatalogueItem(String procedureId, String quantity) =>
      _withInvoice(
        (invoice) => _repository.addItem(
          invoiceId: invoice.id,
          procedureId: procedureId,
          quantity: quantity,
          revision: invoice.revision,
        ),
      );

  Future<bool> addTreatmentItem(EligibleTreatmentItem item, String quantity) =>
      _withInvoice(
        (invoice) => _repository.addItem(
          invoiceId: invoice.id,
          procedureId: item.procedureId,
          treatmentPlanItemId: item.id,
          quantity: quantity,
          revision: invoice.revision,
        ),
      );

  Future<bool> updateQuantity(BillingInvoiceItem item, String quantity) =>
      _withInvoice(
        (invoice) => _repository.updateItem(
          itemId: item.id,
          quantity: quantity,
          revision: invoice.revision,
        ),
      );

  Future<bool> removeItem(BillingInvoiceItem item) => _withInvoice(
    (invoice) => _repository.removeItem(item.id, invoice.revision),
  );

  Future<bool> approveContent(bool approved) => _withInvoice(
    (invoice) =>
        _repository.approveContent(invoice.id, invoice.revision, approved),
  );

  Future<bool> setFinancials(InvoiceFinancialDraft draft) => _withInvoice(
    (invoice) => _repository.setFinancials(invoice.id, invoice.revision, draft),
  );

  Future<bool> finalize() => _withInvoice(
    (invoice) => _repository.finalize(invoice.id, invoice.revision),
  );

  Future<bool> cancel(String reason) => _withInvoice(
    (invoice) => _repository.cancel(invoice.id, invoice.revision, reason),
  );

  Future<bool> recordPayment({
    required Money amount,
    required BillingPaymentMethod method,
    String? reference,
  }) => _withInvoice(
    (invoice) => _repository.recordPayment(
      invoiceId: invoice.id,
      amount: amount,
      method: method,
      receivedAt: DateTime.now(),
      reference: reference,
    ),
  );

  Future<bool> applyCredit(Money amount) =>
      _withInvoice((invoice) => _repository.applyCredit(invoice.id, amount));

  Future<bool> reverseEntry({
    required FinancialEntry entry,
    required Money amount,
    required bool refund,
    required String reason,
    required String ownerPassword,
  }) {
    final invoice = state.selectedInvoice;
    if (invoice == null) return Future.value(false);
    return _mutate(
      () => _repository.reverseEntry(
        clinicId: invoice.clinicId,
        entryId: entry.id,
        amount: amount,
        refund: refund,
        reason: reason,
        ownerPassword: ownerPassword,
      ),
    );
  }

  Future<Uri?> exportPdf(InvoiceLocale locale) async {
    final invoice = state.selectedInvoice;
    if (invoice == null || !invoice.isFinalized || state.mutating) return null;
    emit(state.copyWith(mutating: true, clearFailure: true, clearIssue: true));
    try {
      final access = await _repository.invoicePdf(invoice.id, locale);
      if (!isClosed) emit(state.copyWith(mutating: false));
      return access.url;
    } on BillingOperationException catch (error) {
      if (!isClosed) {
        emit(state.copyWith(mutating: false, issue: error.issue));
      }
    } on AppFailure catch (failure) {
      if (!isClosed) emit(state.copyWith(mutating: false, failure: failure));
    } on Object {
      if (!isClosed) {
        emit(state.copyWith(mutating: false, failure: const UnknownFailure()));
      }
    }
    return null;
  }

  Future<bool> _withInvoice(
    Future<void> Function(BillingInvoice invoice) action,
  ) {
    final invoice = state.selectedInvoice;
    if (invoice == null) return Future.value(false);
    return _mutate(() => action(invoice));
  }

  Future<bool> _mutate(
    Future<void> Function() action, {
    String? Function()? selectCreated,
  }) async {
    if (state.mutating) return false;
    final request = ++_request;
    emit(state.copyWith(mutating: true, clearFailure: true, clearIssue: true));
    try {
      await action();
      if (isClosed || request != _request) return false;
      await _reload(selectId: selectCreated?.call());
      return state.status == BillingLoadStatus.ready;
    } on BillingOperationException catch (error) {
      _issue(request, error.issue, mutating: false);
    } on AppFailure catch (failure) {
      _failure(request, failure, mutating: false);
    } on Object {
      _failure(request, const UnknownFailure(), mutating: false);
    }
    return false;
  }

  Future<void> _reload({String? selectId}) async {
    final clinicId = state.clinicId;
    if (clinicId == null) return;
    final invoices = await _repository.invoices(
      clinicId: clinicId,
      patientId: state.patientId,
    );
    final preferred = selectId ?? state.selectedInvoiceId;
    final selected = invoices.any((invoice) => invoice.id == preferred)
        ? preferred
        : invoices.firstOrNull?.id;
    emit(
      state.copyWith(
        status: BillingLoadStatus.ready,
        invoices: invoices,
        selectedInvoiceId: selected,
        mutating: false,
      ),
    );
    if (selected != null) await selectInvoice(selected);
  }

  void _issue(int request, BillingOperationIssue issue, {bool? mutating}) {
    if (!isClosed && request == _request) {
      emit(
        state.copyWith(
          status: BillingLoadStatus.failure,
          mutating: mutating ?? state.mutating,
          issue: issue,
          clearFailure: true,
        ),
      );
    }
  }

  void _failure(int request, AppFailure failure, {bool? mutating}) {
    if (!isClosed && request == _request) {
      emit(
        state.copyWith(
          status: BillingLoadStatus.failure,
          mutating: mutating ?? state.mutating,
          failure: failure,
          clearIssue: true,
        ),
      );
    }
  }

  void clear() {
    _request++;
    emit(const BillingState());
  }
}

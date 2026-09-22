import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../app/localization/generated/app_localizations.dart';
import '../../../../core/error/failure_message.dart';
import '../../../../core/widgets/app_dialog.dart';
import '../../../../core/value/money.dart';
import '../../../clinic/presentation/clinic_cubit.dart';
import '../../../patient/presentation/patient_cubit.dart';
import '../../domain/billing_models.dart';
import '../billing_cubit.dart';

class BillingPage extends StatefulWidget {
  const BillingPage({this.patientId, super.key});
  final String? patientId;

  @override
  State<BillingPage> createState() => _BillingPageState();
}

class _BillingPageState extends State<BillingPage> {
  String? _loadedKey;

  @override
  Widget build(BuildContext context) {
    final clinicState = context.watch<ClinicCubit>().state;
    final clinic = clinicState.activeClinic;
    final roles = clinicState.activeMembership?.roles ?? const <String>{};
    final allowed = roles.any(
      (role) => role == 'owner' || role == 'dentist' || role == 'receptionist',
    );
    final l = AppLocalizations.of(context);
    if (clinic == null) {
      return Scaffold(body: Center(child: Text(l.selectClinicTitle)));
    }
    if (!allowed) {
      return Scaffold(
        appBar: AppBar(title: Text(l.billingTitle)),
        body: Center(child: Text(l.billingRestricted)),
      );
    }
    final key = '${clinic.id}:${widget.patientId}:${roles.toList()..sort()}';
    if (_loadedKey != key) {
      _loadedKey = key;
      WidgetsBinding.instance.addPostFrameCallback(
        (_) => context.read<BillingCubit>().load(
          clinicId: clinic.id,
          patientId: widget.patientId,
          roles: roles,
        ),
      );
    }
    final patient = widget.patientId == null
        ? null
        : context
              .watch<PatientCubit>()
              .state
              .patients
              .where((item) => item.id == widget.patientId)
              .firstOrNull;
    return Scaffold(
      appBar: AppBar(
        title: Text(
          patient == null
              ? l.billingTitle
              : '${l.billingTitle} · ${patient.fullName}',
        ),
        leading: IconButton(
          onPressed: () => widget.patientId == null
              ? context.go('/dashboard')
              : context.go('/patients/${widget.patientId}'),
          icon: const Icon(Icons.arrow_back),
        ),
      ),
      floatingActionButton:
          widget.patientId != null && roles.contains('dentist')
          ? FloatingActionButton.extended(
              onPressed: () => _createDraft(context),
              icon: const Icon(Icons.receipt_long_outlined),
              label: Text(l.newInvoiceLabel),
            )
          : null,
      body: BlocConsumer<BillingCubit, BillingState>(
        listener: (context, state) {
          if (state.issue != null) {
            _message(context, _issueMessage(state.issue!, l));
          }
        },
        builder: (context, state) => Column(
          children: [
            if (state.status == BillingLoadStatus.loading || state.mutating)
              const LinearProgressIndicator(),
            Expanded(
              child: state.failure != null
                  ? Center(child: Text(failureMessage(state.failure!, l)))
                  : state.invoices.isEmpty &&
                        state.status == BillingLoadStatus.ready
                  ? Center(child: Text(l.noInvoicesMessage))
                  : LayoutBuilder(
                      builder: (context, constraints) {
                        if (constraints.maxWidth >= 900) {
                          return Row(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              SizedBox(
                                width: 330,
                                child: _InvoiceList(state: state),
                              ),
                              const VerticalDivider(width: 1),
                              Expanded(child: _InvoiceDetail(state: state)),
                            ],
                          );
                        }
                        return ListView(
                          padding: const EdgeInsets.all(12),
                          children: [
                            _InvoicePicker(state: state),
                            const SizedBox(height: 12),
                            _InvoiceDetail(state: state, embedded: true),
                            const SizedBox(height: 80),
                          ],
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _createDraft(BuildContext context) async {
    final locale = switch (Localizations.localeOf(context).languageCode) {
      'ru' => InvoiceLocale.russian,
      'ar' => InvoiceLocale.arabic,
      _ => InvoiceLocale.english,
    };
    await context.read<BillingCubit>().createDraft(locale);
  }
}

class _InvoiceList extends StatelessWidget {
  const _InvoiceList({required this.state});
  final BillingState state;

  @override
  Widget build(BuildContext context) => ListView.builder(
    padding: const EdgeInsets.all(12),
    itemCount: state.invoices.length,
    itemBuilder: (context, index) {
      final invoice = state.invoices[index];
      return _InvoiceTile(
        invoice: invoice,
        selected: invoice.id == state.selectedInvoiceId,
      );
    },
  );
}

class _InvoicePicker extends StatelessWidget {
  const _InvoicePicker({required this.state});
  final BillingState state;

  @override
  Widget build(BuildContext context) => DropdownButtonFormField<String>(
    isExpanded: true,
    initialValue: state.selectedInvoiceId,
    decoration: InputDecoration(
      labelText: AppLocalizations.of(context).billingTitle,
    ),
    items: state.invoices
        .map(
          (invoice) => DropdownMenuItem(
            value: invoice.id,
            child: Text(_invoiceTitle(invoice, AppLocalizations.of(context))),
          ),
        )
        .toList(growable: false),
    onChanged: state.mutating
        ? null
        : (id) {
            if (id != null) context.read<BillingCubit>().selectInvoice(id);
          },
  );
}

class _InvoiceTile extends StatelessWidget {
  const _InvoiceTile({required this.invoice, required this.selected});
  final BillingInvoice invoice;
  final bool selected;

  @override
  Widget build(BuildContext context) => Card(
    color: selected ? Theme.of(context).colorScheme.secondaryContainer : null,
    child: ListTile(
      selected: selected,
      onTap: () => context.read<BillingCubit>().selectInvoice(invoice.id),
      title: Text(_invoiceTitle(invoice, AppLocalizations.of(context))),
      subtitle: Text(
        [
          if (invoice.patientDisplayName != null) invoice.patientDisplayName!,
          '${invoice.total.toDecimalString()} ${invoice.currencyCode}',
          DateFormat.yMMMd().format(invoice.createdAt.toLocal()),
        ].join('\n'),
      ),
      isThreeLine: true,
      trailing: _PaymentChip(status: invoice.paymentStatus),
    ),
  );
}

class _InvoiceDetail extends StatelessWidget {
  const _InvoiceDetail({required this.state, this.embedded = false});
  final BillingState state;
  final bool embedded;

  @override
  Widget build(BuildContext context) {
    final invoice = state.selectedInvoice;
    if (invoice == null) return const SizedBox.shrink();
    final content = <Widget>[
      _SummaryCard(invoice: invoice),
      if (state.canPrepare || state.canManageFinancials) ...[
        const SizedBox(height: 12),
        _ItemsCard(state: state),
      ],
      const SizedBox(height: 12),
      _ActionCard(state: state),
      if (state.canRecordPayments) ...[
        const SizedBox(height: 12),
        _PaymentsCard(state: state),
      ],
      const SizedBox(height: 24),
    ];
    if (embedded) return Column(children: content);
    return ListView(padding: const EdgeInsets.all(20), children: content);
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({required this.invoice});
  final BillingInvoice invoice;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final values = [
      (l.invoiceSubtotalLabel, invoice.subtotal),
      (l.invoiceDiscountLabel, invoice.discountAmount),
      (l.invoiceTaxLabel, invoice.taxAmount),
      (l.invoiceTotalLabel, invoice.total),
      (l.invoicePaidLabel, invoice.paidAmount),
      (l.invoiceDueLabel, invoice.outstandingBalance),
    ];
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Wrap(
              alignment: WrapAlignment.spaceBetween,
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: 12,
              children: [
                Text(
                  _invoiceTitle(invoice, l),
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                _PaymentChip(status: invoice.paymentStatus),
              ],
            ),
            if (invoice.patientDisplayName != null) ...[
              const SizedBox(height: 4),
              Text(
                '${invoice.patientDisplayName} · ${invoice.patientDisplayNumber ?? ''}',
              ),
            ],
            const Divider(height: 28),
            Wrap(
              spacing: 24,
              runSpacing: 12,
              children: values
                  .map(
                    (value) => SizedBox(
                      width: 145,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(value.$1),
                          Text(
                            '${value.$2.toDecimalString()} ${invoice.currencyCode}',
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                        ],
                      ),
                    ),
                  )
                  .toList(growable: false),
            ),
          ],
        ),
      ),
    );
  }
}

class _ItemsCard extends StatelessWidget {
  const _ItemsCard({required this.state});
  final BillingState state;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final invoice = state.selectedInvoice!;
    final editable =
        state.canPrepare &&
        invoice.isDraft &&
        !invoice.isClinicallyApproved &&
        !state.mutating;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              l.invoiceItemsTitle,
              style: Theme.of(context).textTheme.titleLarge,
            ),
            if (state.items.isEmpty) ...[
              const SizedBox(height: 12),
              Text(l.noInvoiceItemsMessage),
            ],
            for (final item in state.items) ...[
              const Divider(),
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(item.procedureName),
                subtitle: Text(
                  [
                    item.category,
                    if (item.toothNumber != null) '#${item.toothNumber}',
                    '${l.quantityLabel}: ${item.quantity}',
                    '${item.lineTotal.toDecimalString()} ${invoice.currencyCode}',
                  ].join(' · '),
                ),
                trailing: editable
                    ? PopupMenuButton<String>(
                        onSelected: (action) => action == 'quantity'
                            ? _quantityDialog(context, item)
                            : context.read<BillingCubit>().removeItem(item),
                        itemBuilder: (_) => [
                          PopupMenuItem(
                            value: 'quantity',
                            child: Text(l.quantityLabel),
                          ),
                          PopupMenuItem(
                            value: 'remove',
                            child: Text(l.cancelLabel),
                          ),
                        ],
                      )
                    : null,
              ),
            ],
            if (editable) ...[
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  OutlinedButton.icon(
                    onPressed: state.procedures.isEmpty
                        ? null
                        : () => _addCatalogueDialog(context, state),
                    icon: const Icon(Icons.add),
                    label: Text(l.addCatalogueItemLabel),
                  ),
                  OutlinedButton.icon(
                    onPressed: state.eligibleItems.isEmpty
                        ? null
                        : () => _addTreatmentDialog(context, state),
                    icon: const Icon(Icons.playlist_add),
                    label: Text(l.addTreatmentItemLabel),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _ActionCard extends StatelessWidget {
  const _ActionCard({required this.state});
  final BillingState state;

  @override
  Widget build(BuildContext context) {
    final invoice = state.selectedInvoice!;
    final l = AppLocalizations.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            if (state.canPrepare && invoice.isDraft)
              FilledButton.icon(
                onPressed:
                    state.mutating ||
                        (!invoice.isClinicallyApproved && state.items.isEmpty)
                    ? null
                    : () => context.read<BillingCubit>().approveContent(
                        !invoice.isClinicallyApproved,
                      ),
                icon: Icon(
                  invoice.isClinicallyApproved ? Icons.edit : Icons.verified,
                ),
                label: Text(
                  invoice.isClinicallyApproved
                      ? l.reopenContentLabel
                      : l.approveContentLabel,
                ),
              ),
            if (state.canManageFinancials && invoice.isDraft)
              OutlinedButton.icon(
                onPressed: state.mutating || state.items.isEmpty
                    ? null
                    : () => _financialDialog(context, state),
                icon: const Icon(Icons.calculate_outlined),
                label: Text(l.financialDetailsTitle),
              ),
            if (state.canManageFinancials && invoice.isDraft)
              FilledButton.icon(
                onPressed: state.mutating || !invoice.isClinicallyApproved
                    ? null
                    : () => _finalizeDialog(context),
                icon: const Icon(Icons.lock_outline),
                label: Text(l.finalizeInvoiceLabel),
              ),
            if (invoice.isFinalized)
              OutlinedButton.icon(
                onPressed: state.mutating
                    ? null
                    : () => _openPdf(context, invoice),
                icon: const Icon(Icons.picture_as_pdf_outlined),
                label: Text(l.exportInvoiceLabel),
              ),
            if ((state.canManageFinancials ||
                    (state.canPrepare && invoice.isDraft)) &&
                invoice.documentStatus != InvoiceDocumentStatus.cancelled)
              TextButton.icon(
                onPressed: state.mutating ? null : () => _cancelDialog(context),
                icon: const Icon(Icons.cancel_outlined),
                label: Text(l.cancelInvoiceLabel),
              ),
          ],
        ),
      ),
    );
  }
}

class _PaymentsCard extends StatelessWidget {
  const _PaymentsCard({required this.state});
  final BillingState state;

  @override
  Widget build(BuildContext context) {
    final invoice = state.selectedInvoice!;
    final l = AppLocalizations.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              l.paymentHistoryTitle,
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(
              '${l.patientCreditLabel}: '
              '${(state.credit?.balance ?? Money.zero).toDecimalString()} '
              '${invoice.currencyCode}',
            ),
            if (invoice.isFinalized &&
                invoice.outstandingBalance != Money.zero) ...[
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  FilledButton.icon(
                    onPressed: state.mutating
                        ? null
                        : () => _paymentDialog(context, invoice),
                    icon: const Icon(Icons.payments_outlined),
                    label: Text(l.recordPaymentLabel),
                  ),
                  if ((state.credit?.balance ?? Money.zero) != Money.zero)
                    OutlinedButton.icon(
                      onPressed: state.mutating
                          ? null
                          : () => _creditDialog(context, state),
                      icon: const Icon(Icons.account_balance_wallet_outlined),
                      label: Text(l.applyCreditLabel),
                    ),
                ],
              ),
            ],
            for (final payment in state.payments) ...[
              const Divider(),
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(
                  '${payment.amount.toDecimalString()} ${invoice.currencyCode}',
                ),
                subtitle: Text(
                  '${_methodLabel(payment.method, l)} · '
                  '${DateFormat.yMMMd().add_Hm().format(payment.receivedAt.toLocal())}'
                  '${payment.reference == null ? '' : '\n${payment.reference}'}',
                ),
              ),
            ],
            if (state.canManageFinancials)
              for (final entry in state.entries.where(
                (entry) => entry.reversibleRemaining != Money.zero,
              ))
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(
                    '${entry.kind.replaceAll('_', ' ')} · '
                    '${entry.reversibleRemaining.toDecimalString()} ${invoice.currencyCode}',
                  ),
                  trailing: PopupMenuButton<bool>(
                    onSelected: (refund) =>
                        _reversalDialog(context, entry, refund),
                    itemBuilder: (_) => [
                      PopupMenuItem(value: true, child: Text(l.refundLabel)),
                      PopupMenuItem(
                        value: false,
                        child: Text(l.correctionLabel),
                      ),
                    ],
                  ),
                ),
          ],
        ),
      ),
    );
  }
}

class _PaymentChip extends StatelessWidget {
  const _PaymentChip({required this.status});
  final InvoicePaymentStatus status;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final text = switch (status) {
      InvoicePaymentStatus.unpaid => l.paymentUnpaidLabel,
      InvoicePaymentStatus.partiallyPaid => l.paymentPartialLabel,
      InvoicePaymentStatus.paid => l.paymentPaidLabel,
    };
    return Chip(label: Text(text));
  }
}

Future<void> _addCatalogueDialog(
  BuildContext context,
  BillingState state,
) async {
  var selected = state.procedures.first.id;
  final quantity = TextEditingController(text: '1');
  final form = GlobalKey<FormState>();
  final accepted = await showSettledDialog<bool>(
    context: context,
    builder: (dialogContext) => StatefulBuilder(
      builder: (context, setDialogState) => AlertDialog(
        scrollable: true,
        title: Text(AppLocalizations.of(context).addCatalogueItemLabel),
        content: DialogBody(
          child: Form(
            key: form,
            child: DialogFormColumn(
              children: [
                DropdownButtonFormField<String>(
                  isExpanded: true,
                  initialValue: selected,
                  items: state.procedures
                      .map(
                        (item) => DropdownMenuItem(
                          value: item.id,
                          child: Text(
                            '${item.name} · ${item.defaultPrice.toDecimalString()}',
                          ),
                        ),
                      )
                      .toList(growable: false),
                  onChanged: (value) => setDialogState(() => selected = value!),
                ),
                TextFormField(
                  controller: quantity,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  decoration: InputDecoration(
                    labelText: AppLocalizations.of(context).quantityLabel,
                  ),
                  validator: (value) =>
                      _quantityValidator(value, AppLocalizations.of(context)),
                ),
              ],
            ),
          ),
        ),
        actions: _dialogActions(context, form),
      ),
    ),
  );
  if (accepted == true && context.mounted) {
    await context.read<BillingCubit>().addCatalogueItem(
      selected,
      quantity.text.trim(),
    );
  }
  quantity.dispose();
}

Future<void> _addTreatmentDialog(
  BuildContext context,
  BillingState state,
) async {
  var selected = state.eligibleItems.first;
  final quantity = TextEditingController(text: '1');
  final form = GlobalKey<FormState>();
  final accepted = await showSettledDialog<bool>(
    context: context,
    builder: (dialogContext) => StatefulBuilder(
      builder: (context, setDialogState) => AlertDialog(
        scrollable: true,
        title: Text(AppLocalizations.of(context).addTreatmentItemLabel),
        content: DialogBody(
          child: Form(
            key: form,
            child: DialogFormColumn(
              children: [
                DropdownButtonFormField<String>(
                  isExpanded: true,
                  initialValue: selected.id,
                  items: state.eligibleItems
                      .map(
                        (item) => DropdownMenuItem(
                          value: item.id,
                          child: Text(
                            '${item.procedureName}${item.toothNumber == null ? '' : ' #${item.toothNumber}'}',
                          ),
                        ),
                      )
                      .toList(growable: false),
                  onChanged: (value) => setDialogState(
                    () => selected = state.eligibleItems.firstWhere(
                      (item) => item.id == value,
                    ),
                  ),
                ),
                TextFormField(
                  controller: quantity,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  decoration: InputDecoration(
                    labelText: AppLocalizations.of(context).quantityLabel,
                  ),
                  validator: (value) =>
                      _quantityValidator(value, AppLocalizations.of(context)),
                ),
              ],
            ),
          ),
        ),
        actions: _dialogActions(context, form),
      ),
    ),
  );
  if (accepted == true && context.mounted) {
    await context.read<BillingCubit>().addTreatmentItem(
      selected,
      quantity.text.trim(),
    );
  }
  quantity.dispose();
}

Future<void> _quantityDialog(
  BuildContext context,
  BillingInvoiceItem item,
) async {
  final quantity = TextEditingController(text: item.quantity);
  final form = GlobalKey<FormState>();
  final accepted = await showSettledDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      scrollable: true,
      title: Text(AppLocalizations.of(context).quantityLabel),
      content: Form(
        key: form,
        child: TextFormField(
          controller: quantity,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          validator: (value) =>
              _quantityValidator(value, AppLocalizations.of(context)),
        ),
      ),
      actions: _dialogActions(context, form),
    ),
  );
  if (accepted == true && context.mounted) {
    await context.read<BillingCubit>().updateQuantity(
      item,
      quantity.text.trim(),
    );
  }
  quantity.dispose();
}

Future<void> _financialDialog(BuildContext context, BillingState state) async {
  final invoice = state.selectedInvoice!;
  final form = GlobalKey<FormState>();
  final prices = {
    for (final item in state.items)
      item.id: TextEditingController(text: item.unitPrice.toDecimalString()),
  };
  final discount = TextEditingController(
    text: invoice.discountValue.toDecimalString(),
  );
  final tax = TextEditingController(text: invoice.taxRate.toDecimalString());
  var type = invoice.discountType;
  var locale = invoice.locale;
  final accepted = await showSettledDialog<bool>(
    context: context,
    builder: (dialogContext) => StatefulBuilder(
      builder: (context, setDialogState) => AlertDialog(
        scrollable: true,
        title: Text(AppLocalizations.of(context).financialDetailsTitle),
        content: DialogBody(
          child: Form(
            key: form,
            child: SingleChildScrollView(
              child: DialogFormColumn(
                children: [
                  for (final item in state.items)
                    TextFormField(
                      controller: prices[item.id],
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      decoration: InputDecoration(
                        labelText:
                            '${item.procedureName} · ${AppLocalizations.of(context).unitPriceLabel}',
                      ),
                      validator: (value) =>
                          _moneyValidator(value, AppLocalizations.of(context)),
                    ),
                  DropdownButtonFormField<InvoiceDiscountType>(
                    isExpanded: true,
                    initialValue: type,
                    decoration: InputDecoration(
                      labelText: AppLocalizations.of(context).discountTypeLabel,
                    ),
                    items: InvoiceDiscountType.values
                        .map(
                          (value) => DropdownMenuItem(
                            value: value,
                            child: Text(
                              _discountLabel(
                                value,
                                AppLocalizations.of(context),
                              ),
                            ),
                          ),
                        )
                        .toList(growable: false),
                    onChanged: (value) => setDialogState(() => type = value!),
                  ),
                  if (type != InvoiceDiscountType.none)
                    TextFormField(
                      controller: discount,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      decoration: InputDecoration(
                        labelText: AppLocalizations.of(
                          context,
                        ).discountValueLabel,
                      ),
                      validator: (value) =>
                          _moneyValidator(value, AppLocalizations.of(context)),
                    ),
                  TextFormField(
                    controller: tax,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    decoration: InputDecoration(
                      labelText: AppLocalizations.of(context).taxRateLabel,
                    ),
                    validator: (value) {
                      final parsed = Money.tryParseUserInput(value ?? '');
                      return parsed == null || parsed.minorUnits > 10000
                          ? AppLocalizations.of(context).validationFailure
                          : null;
                    },
                  ),
                  DropdownButtonFormField<InvoiceLocale>(
                    isExpanded: true,
                    initialValue: locale,
                    decoration: InputDecoration(
                      labelText: AppLocalizations.of(
                        context,
                      ).invoiceLanguageLabel,
                    ),
                    items: InvoiceLocale.values
                        .map(
                          (value) => DropdownMenuItem(
                            value: value,
                            child: Text(
                              _localeLabel(value, AppLocalizations.of(context)),
                            ),
                          ),
                        )
                        .toList(growable: false),
                    onChanged: (value) => setDialogState(() => locale = value!),
                  ),
                ],
              ),
            ),
          ),
        ),
        actions: _dialogActions(
          context,
          form,
          saveLabel: AppLocalizations.of(context).saveFinancialsLabel,
        ),
      ),
    ),
  );
  if (accepted == true && context.mounted) {
    await context.read<BillingCubit>().setFinancials(
      InvoiceFinancialDraft(
        itemPrices: {
          for (final entry in prices.entries)
            entry.key: Money.tryParseUserInput(entry.value.text)!,
        },
        discountType: type,
        discountValue: type == InvoiceDiscountType.none
            ? Money.zero
            : Money.tryParseUserInput(discount.text)!,
        taxRate: Money.tryParseUserInput(tax.text)!,
        locale: locale,
      ),
    );
  }
  for (final controller in prices.values) {
    controller.dispose();
  }
  discount.dispose();
  tax.dispose();
}

Future<void> _finalizeDialog(BuildContext context) async {
  final l = AppLocalizations.of(context);
  final accepted = await showSettledDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      scrollable: true,
      title: Text(l.finalizeInvoiceLabel),
      content: Text(l.finalizeInvoiceWarning),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: Text(l.cancelLabel),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(context, true),
          child: Text(l.finalizeInvoiceLabel),
        ),
      ],
    ),
  );
  if (accepted == true && context.mounted) {
    await context.read<BillingCubit>().finalize();
  }
}

Future<void> _cancelDialog(BuildContext context) async {
  final reason = TextEditingController();
  final form = GlobalKey<FormState>();
  final l = AppLocalizations.of(context);
  final accepted = await showSettledDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      scrollable: true,
      title: Text(l.cancelInvoiceLabel),
      content: Form(
        key: form,
        child: TextFormField(
          controller: reason,
          maxLength: 1000,
          decoration: InputDecoration(labelText: l.reasonLabel),
          validator: (value) => value == null || value.trim().isEmpty
              ? l.validationFailure
              : null,
        ),
      ),
      actions: _dialogActions(context, form),
    ),
  );
  if (accepted == true && context.mounted) {
    await context.read<BillingCubit>().cancel(reason.text.trim());
  }
  reason.dispose();
}

Future<void> _paymentDialog(
  BuildContext context,
  BillingInvoice invoice,
) async {
  final amount = TextEditingController(
    text: invoice.outstandingBalance.toDecimalString(),
  );
  final reference = TextEditingController();
  final form = GlobalKey<FormState>();
  var method = BillingPaymentMethod.cash;
  final accepted = await showSettledDialog<bool>(
    context: context,
    builder: (dialogContext) => StatefulBuilder(
      builder: (context, setDialogState) => AlertDialog(
        scrollable: true,
        title: Text(AppLocalizations.of(context).recordPaymentLabel),
        content: DialogBody(
          child: Form(
            key: form,
            child: DialogFormColumn(
              children: [
                TextFormField(
                  controller: amount,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  decoration: InputDecoration(
                    labelText: AppLocalizations.of(context).paymentAmountLabel,
                  ),
                  validator: (value) {
                    final parsed = Money.tryParseUserInput(value ?? '');
                    return parsed == null || parsed == Money.zero
                        ? AppLocalizations.of(context).validationFailure
                        : null;
                  },
                ),
                DropdownButtonFormField<BillingPaymentMethod>(
                  isExpanded: true,
                  initialValue: method,
                  decoration: InputDecoration(
                    labelText: AppLocalizations.of(context).paymentMethodLabel,
                  ),
                  items: BillingPaymentMethod.values
                      .map(
                        (value) => DropdownMenuItem(
                          value: value,
                          child: Text(
                            _methodLabel(value, AppLocalizations.of(context)),
                          ),
                        ),
                      )
                      .toList(growable: false),
                  onChanged: (value) => setDialogState(() => method = value!),
                ),
                TextField(
                  controller: reference,
                  maxLength: 200,
                  decoration: InputDecoration(
                    labelText: AppLocalizations.of(context).referenceLabel,
                  ),
                ),
              ],
            ),
          ),
        ),
        actions: _dialogActions(context, form),
      ),
    ),
  );
  if (accepted == true && context.mounted) {
    await context.read<BillingCubit>().recordPayment(
      amount: Money.tryParseUserInput(amount.text)!,
      method: method,
      reference: reference.text.trim().isEmpty ? null : reference.text.trim(),
    );
  }
  amount.dispose();
  reference.dispose();
}

Future<void> _creditDialog(BuildContext context, BillingState state) async {
  final available = state.credit!.balance;
  final due = state.selectedInvoice!.outstandingBalance;
  final maximum = available.compareTo(due) <= 0 ? available : due;
  final amount = TextEditingController(text: maximum.toDecimalString());
  final form = GlobalKey<FormState>();
  final accepted = await showSettledDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      scrollable: true,
      title: Text(AppLocalizations.of(context).applyCreditLabel),
      content: Form(
        key: form,
        child: TextFormField(
          controller: amount,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          validator: (value) {
            final parsed = Money.tryParseUserInput(value ?? '');
            return parsed == null ||
                    parsed == Money.zero ||
                    parsed.compareTo(maximum) > 0
                ? AppLocalizations.of(context).validationFailure
                : null;
          },
        ),
      ),
      actions: _dialogActions(context, form),
    ),
  );
  if (accepted == true && context.mounted) {
    await context.read<BillingCubit>().applyCredit(
      Money.tryParseUserInput(amount.text)!,
    );
  }
  amount.dispose();
}

Future<void> _reversalDialog(
  BuildContext context,
  FinancialEntry entry,
  bool refund,
) async {
  final amount = TextEditingController(
    text: entry.reversibleRemaining.toDecimalString(),
  );
  final reason = TextEditingController();
  final password = TextEditingController();
  final form = GlobalKey<FormState>();
  final l = AppLocalizations.of(context);
  final accepted = await showSettledDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      scrollable: true,
      title: Text(refund ? l.refundLabel : l.correctionLabel),
      content: DialogBody(
        child: Form(
          key: form,
          child: DialogFormColumn(
            children: [
              TextFormField(
                controller: amount,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                validator: (value) {
                  final parsed = Money.tryParseUserInput(value ?? '');
                  return parsed == null ||
                          parsed == Money.zero ||
                          parsed.compareTo(entry.reversibleRemaining) > 0
                      ? l.validationFailure
                      : null;
                },
              ),
              TextFormField(
                controller: reason,
                maxLength: 1000,
                decoration: InputDecoration(labelText: l.reasonLabel),
                validator: (value) => value == null || value.trim().isEmpty
                    ? l.validationFailure
                    : null,
              ),
              TextFormField(
                controller: password,
                obscureText: true,
                autocorrect: false,
                enableSuggestions: false,
                decoration: InputDecoration(labelText: l.passwordLabel),
                validator: (value) =>
                    value == null || value.isEmpty ? l.validationFailure : null,
              ),
            ],
          ),
        ),
      ),
      actions: _dialogActions(context, form),
    ),
  );
  if (accepted == true && context.mounted) {
    await context.read<BillingCubit>().reverseEntry(
      entry: entry,
      amount: Money.tryParseUserInput(amount.text)!,
      refund: refund,
      reason: reason.text.trim(),
      ownerPassword: password.text,
    );
  }
  amount.dispose();
  reason.dispose();
  password.dispose();
}

Future<void> _openPdf(BuildContext context, BillingInvoice invoice) async {
  final url = await context.read<BillingCubit>().exportPdf(invoice.locale);
  if (url != null && context.mounted) {
    final opened = await launchUrl(url, mode: LaunchMode.externalApplication);
    if (!opened && context.mounted) {
      _message(
        context,
        AppLocalizations.of(context).invoicePdfUnavailableMessage,
      );
    }
  }
}

List<Widget> _dialogActions(
  BuildContext context,
  GlobalKey<FormState> form, {
  String? saveLabel,
}) {
  final l = AppLocalizations.of(context);
  return [
    TextButton(
      onPressed: () => Navigator.pop(context, false),
      child: Text(l.cancelLabel),
    ),
    FilledButton(
      onPressed: () {
        if (form.currentState?.validate() ?? false) {
          Navigator.pop(context, true);
        }
      },
      child: Text(saveLabel ?? l.saveDraftLabel),
    ),
  ];
}

String? _moneyValidator(String? value, AppLocalizations l) =>
    Money.tryParseUserInput(value ?? '') == null
    ? l.validAmountValidation
    : null;

String? _quantityValidator(String? value, AppLocalizations l) =>
    RegExp(
      r'^(?:0\.(?:0[1-9]|[1-9]\d)|[1-9]\d{0,2}(?:[\.,]\d{1,2})?)$',
    ).hasMatch(value?.trim() ?? '')
    ? null
    : l.quantityRangeValidation;

String _invoiceTitle(
  BillingInvoice invoice,
  AppLocalizations l,
) => switch (invoice.documentStatus) {
  InvoiceDocumentStatus.draft => l.invoiceDraftLabel,
  InvoiceDocumentStatus.finalized => invoice.invoiceNumber!,
  InvoiceDocumentStatus.cancelled =>
    '${invoice.invoiceNumber ?? l.invoiceDraftLabel} · ${l.invoiceCancelledLabel}',
};

String _discountLabel(InvoiceDiscountType type, AppLocalizations l) =>
    switch (type) {
      InvoiceDiscountType.none => l.discountNoneLabel,
      InvoiceDiscountType.fixed => l.discountFixedLabel,
      InvoiceDiscountType.percentage => l.discountPercentageLabel,
    };

String _localeLabel(InvoiceLocale locale, AppLocalizations l) =>
    switch (locale) {
      InvoiceLocale.english => l.languageEnglishLabel,
      InvoiceLocale.russian => l.languageRussianLabel,
      InvoiceLocale.arabic => l.languageArabicLabel,
    };

String _methodLabel(BillingPaymentMethod method, AppLocalizations l) =>
    switch (method) {
      BillingPaymentMethod.cash => l.paymentCashLabel,
      BillingPaymentMethod.card => l.paymentCardLabel,
      BillingPaymentMethod.bankTransfer => l.paymentBankLabel,
      BillingPaymentMethod.other => l.paymentOtherLabel,
    };

String _issueMessage(BillingOperationIssue issue, AppLocalizations l) =>
    switch (issue) {
      BillingOperationIssue.conflict => l.billingConflictMessage,
      BillingOperationIssue.pendingPdf ||
      BillingOperationIssue.pdfUnavailable => l.invoicePdfUnavailableMessage,
      BillingOperationIssue.forbidden => l.billingRestricted,
      BillingOperationIssue.ownerReauthenticationRequired => l.authCredentials,
      _ => l.billingActionFailedMessage,
    };

void _message(BuildContext context, String message) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(content: Text(message)));
}

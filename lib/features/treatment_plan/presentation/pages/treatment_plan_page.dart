import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../app/localization/generated/app_localizations.dart';
import '../../../../core/error/failure_message.dart';
import '../../../../core/widgets/app_dialog.dart';
import '../../../../core/value/money.dart';
import '../../../clinic/presentation/clinic_cubit.dart';
import '../../../patient/domain/patient_models.dart';
import '../../../patient/presentation/patient_cubit.dart';
import '../../../staff/domain/staff_models.dart';
import '../../../staff/presentation/staff_cubit.dart';
import '../../domain/treatment_plan_models.dart';
import '../treatment_plan_cubit.dart';

class TreatmentPlanPage extends StatefulWidget {
  const TreatmentPlanPage({required this.patientId, super.key});
  final String patientId;

  @override
  State<TreatmentPlanPage> createState() => _TreatmentPlanPageState();
}

class _TreatmentPlanPageState extends State<TreatmentPlanPage> {
  String? _loadedKey;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final clinicState = context.watch<ClinicCubit>().state;
    final clinic = clinicState.activeClinic;
    final roles = clinicState.activeMembership?.roles ?? const <String>{};
    final canEdit = roles.contains('dentist');
    final patient = context
        .watch<PatientCubit>()
        .state
        .patients
        .where((item) => item.id == widget.patientId)
        .firstOrNull;
    if (clinic == null || patient == null) {
      return Scaffold(
        appBar: AppBar(title: Text(l.treatmentPlansTitle)),
        body: _MessageCard(message: l.treatmentPlansUnavailable),
      );
    }
    final loadKey = '${clinic.id}:${widget.patientId}';
    if (_loadedKey != loadKey) {
      _loadedKey = loadKey;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        context.read<TreatmentPlanCubit>().loadPatient(
          clinic.id,
          widget.patientId,
        );
        context.read<StaffCubit>().load(clinic.id);
      });
    }
    final dentists = context
        .watch<StaffCubit>()
        .state
        .members
        .where(
          (member) =>
              member.isActive && member.roles.contains(StaffRole.dentist),
        )
        .toList(growable: false);
    return Scaffold(
      appBar: AppBar(
        title: Text(l.treatmentPlansTitle),
        leading: IconButton(
          onPressed: () => context.go('/patients/${widget.patientId}'),
          icon: const Icon(Icons.arrow_back),
          tooltip: l.backToClinicLabel,
        ),
        actions: [
          IconButton(
            onPressed: () => context.go('/procedures'),
            icon: const Icon(Icons.medical_services_outlined),
            tooltip: l.procedureCatalogueTitle,
          ),
        ],
      ),
      floatingActionButton: canEdit
          ? FloatingActionButton.extended(
              onPressed: dentists.isEmpty
                  ? () => _showMessage(context, l.noActiveDentist)
                  : () => _createPlan(context, dentists),
              icon: const Icon(Icons.playlist_add),
              label: Text(l.newPlanLabel),
            )
          : null,
      body: BlocConsumer<TreatmentPlanCubit, TreatmentPlanState>(
        listener: (context, state) {
          if (state.issue != null) {
            _showMessage(context, _issueMessage(state.issue!, l));
          }
        },
        builder: (context, state) => LayoutBuilder(
          builder: (context, constraints) {
            final content = <Widget>[
              _PatientHeader(patient: patient),
              if (!canEdit)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(l.treatmentViewOnly),
                ),
              const SizedBox(height: 16),
              if (state.status == TreatmentPlanLoadStatus.loading ||
                  state.mutating)
                const LinearProgressIndicator(),
              if (state.failure != null)
                _MessageCard(
                  message: failureMessage(
                    state.failure!,
                    AppLocalizations.of(context),
                  ),
                ),
              if (state.status == TreatmentPlanLoadStatus.ready &&
                  state.plans.isEmpty)
                _MessageCard(message: l.noTreatmentPlan),
              if (state.plans.isNotEmpty)
                _PlanWorkspace(
                  state: state,
                  canEdit: canEdit,
                  currencyCode: clinic.currencyCode,
                  dentists: dentists,
                  onEditNotes: () => _editNotes(context, state.selectedPlan!),
                  onAddItem: () => _editItem(context, state, dentists),
                  onEditItem: (item) =>
                      _editItem(context, state, dentists, existing: item),
                  onPlanTransition: (status) => _confirmPlanTransition(
                    context,
                    state.selectedPlan!,
                    status,
                  ),
                  onItemTransition: (item, status) => context
                      .read<TreatmentPlanCubit>()
                      .transitionItem(item.id, status),
                ),
              const SizedBox(height: 80),
            ];
            return ListView(
              padding: EdgeInsets.symmetric(
                horizontal: constraints.maxWidth >= 900 ? 32 : 16,
                vertical: 16,
              ),
              children: [
                Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 1200),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: content,
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Future<void> _createPlan(
    BuildContext context,
    List<StaffMember> dentists,
  ) async {
    final l = AppLocalizations.of(context);
    final notes = TextEditingController();
    final currentMemberId = context
        .read<ClinicCubit>()
        .state
        .activeMembership
        ?.memberId;
    var dentistId = dentists.any((member) => member.id == currentMemberId)
        ? currentMemberId!
        : dentists.first.id;
    final submitted = await showSettledDialog<bool>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text(l.newTreatmentPlanTitle),
          content: SizedBox(
            width: 460,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButtonFormField<String>(
                  isExpanded: true,
                  initialValue: dentistId,
                  decoration: InputDecoration(labelText: l.leadDentistLabel),
                  items: dentists
                      .map(
                        (member) => DropdownMenuItem(
                          value: member.id,
                          child: Text(member.email),
                        ),
                      )
                      .toList(growable: false),
                  onChanged: (value) =>
                      setDialogState(() => dentistId = value!),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: notes,
                  maxLength: 5000,
                  maxLines: 4,
                  decoration: InputDecoration(labelText: l.planNotesOptional),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: Text(l.cancelLabel),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              child: Text(l.createDraftLabel),
            ),
          ],
        ),
      ),
    );
    if (submitted == true && context.mounted) {
      await context.read<TreatmentPlanCubit>().createPlan(
        patientId: widget.patientId,
        dentistMemberId: dentistId,
        notes: _optional(notes.text),
      );
    }
    notes.dispose();
  }

  Future<void> _editNotes(BuildContext context, TreatmentPlan plan) async {
    final l = AppLocalizations.of(context);
    final notes = TextEditingController(text: plan.notes);
    final submitted = await showSettledDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(l.editPlanNotesTitle),
        content: SizedBox(
          width: 460,
          child: TextField(
            controller: notes,
            autofocus: true,
            maxLength: 5000,
            maxLines: 6,
            decoration: InputDecoration(labelText: l.notesLabel),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: Text(l.cancelLabel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: Text(l.saveLabel),
          ),
        ],
      ),
    );
    if (submitted == true && context.mounted) {
      await context.read<TreatmentPlanCubit>().updateDraftPlan(
        plan.id,
        _optional(notes.text),
      );
    }
    notes.dispose();
  }

  Future<void> _editItem(
    BuildContext context,
    TreatmentPlanState state,
    List<StaffMember> dentists, {
    TreatmentPlanItem? existing,
  }) async {
    final l = AppLocalizations.of(context);
    final procedures = state.procedures.where((item) => item.active).toList();
    if (procedures.isEmpty) {
      _showMessage(context, l.ownerAddProcedureFirst);
      return;
    }
    final form = GlobalKey<FormState>();
    var procedureId = existing?.procedureId;
    if (!procedures.any((item) => item.id == procedureId)) {
      procedureId = procedures.first.id;
    }
    var assignedDentistId = existing?.assignedDentistId;
    final tooth = TextEditingController(
      text: existing?.toothNumber?.toString(),
    );
    final description = TextEditingController(text: existing?.description);
    final price = TextEditingController(
      text: existing?.estimatedPrice.toDecimalString(),
    );
    if (existing == null) {
      price.text = procedures
          .firstWhere((item) => item.id == procedureId)
          .defaultPrice
          .toDecimalString();
    }
    final submitted = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      builder: (sheetContext) => StatefulBuilder(
        builder: (context, setSheetState) => Padding(
          padding: EdgeInsets.fromLTRB(
            24,
            24,
            24,
            MediaQuery.viewInsetsOf(context).bottom + 24,
          ),
          child: Form(
            key: form,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    existing == null
                        ? l.addProcedureLabel
                        : l.editProcedureLabel,
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    isExpanded: true,
                    initialValue: procedureId,
                    decoration: InputDecoration(labelText: l.procedureLabel),
                    items: procedures
                        .map(
                          (item) => DropdownMenuItem(
                            value: item.id,
                            child: Text(item.name),
                          ),
                        )
                        .toList(growable: false),
                    onChanged: (value) {
                      setSheetState(() => procedureId = value!);
                      price.text = procedures
                          .firstWhere((item) => item.id == value)
                          .defaultPrice
                          .toDecimalString();
                    },
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: tooth,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(labelText: l.fdiToothOptional),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) return null;
                      final number = int.tryParse(value.trim());
                      return number == null || !_validFdi(number)
                          ? l.validFdiValidation
                          : null;
                    },
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: price,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    decoration: InputDecoration(
                      labelText: l.estimatedPriceLabel,
                    ),
                    validator: (value) {
                      final amount = Money.tryParseUserInput(
                        value?.trim() ?? '',
                      );
                      return amount == null ? l.validPriceValidation : null;
                    },
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String?>(
                    isExpanded: true,
                    initialValue: assignedDentistId,
                    decoration: InputDecoration(
                      labelText: l.assignedDentistOptional,
                    ),
                    items: [
                      DropdownMenuItem<String?>(
                        value: null,
                        child: Text(l.notAssignedLabel),
                      ),
                      ...dentists.map(
                        (member) => DropdownMenuItem<String?>(
                          value: member.id,
                          child: Text(member.email),
                        ),
                      ),
                    ],
                    onChanged: (value) =>
                        setSheetState(() => assignedDentistId = value),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: description,
                    maxLength: 2000,
                    maxLines: 3,
                    decoration: InputDecoration(
                      labelText: l.clinicalDescriptionOptional,
                    ),
                  ),
                  const SizedBox(height: 16),
                  FilledButton(
                    onPressed: () {
                      if (form.currentState?.validate() ?? false) {
                        Navigator.pop(sheetContext, true);
                      }
                    },
                    child: Text(l.saveProcedureLabel),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
    if (submitted == true && context.mounted) {
      final draft = TreatmentPlanItemDraft(
        procedureId: procedureId!,
        toothNumber: int.tryParse(tooth.text.trim()),
        description: _optional(description.text),
        estimatedPrice: Money.tryParseUserInput(price.text)!,
        assignedDentistId: assignedDentistId,
      );
      final cubit = context.read<TreatmentPlanCubit>();
      if (existing == null) {
        await cubit.addItem(state.selectedPlanId!, draft);
      } else {
        await cubit.updateDraftItem(existing.id, draft);
      }
    }
    tooth.dispose();
    description.dispose();
    price.dispose();
  }

  Future<void> _confirmPlanTransition(
    BuildContext context,
    TreatmentPlan plan,
    TreatmentPlanStatus status,
  ) async {
    final l = AppLocalizations.of(context);
    final statusLabel = _planStatusLabel(status, l);
    final confirmed = await showSettledDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(l.planTransitionQuestion(statusLabel)),
        content: Text(
          status == TreatmentPlanStatus.active
              ? l.activatePlanExplanation
              : l.finalPlanTransitionExplanation,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: Text(l.cancelLabel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: Text(statusLabel),
          ),
        ],
      ),
    );
    if (confirmed == true && context.mounted) {
      await context.read<TreatmentPlanCubit>().transitionPlan(plan.id, status);
    }
  }
}

class _PatientHeader extends StatelessWidget {
  const _PatientHeader({required this.patient});
  final Patient patient;
  @override
  Widget build(BuildContext context) => Card(
    child: ListTile(
      leading: const CircleAvatar(child: Icon(Icons.person_outline)),
      title: Text(patient.fullName),
      subtitle: Text(patient.patientNumber),
    ),
  );
}

class _PlanWorkspace extends StatelessWidget {
  const _PlanWorkspace({
    required this.state,
    required this.canEdit,
    required this.currencyCode,
    required this.dentists,
    required this.onEditNotes,
    required this.onAddItem,
    required this.onEditItem,
    required this.onPlanTransition,
    required this.onItemTransition,
  });
  final TreatmentPlanState state;
  final bool canEdit;
  final String currencyCode;
  final List<StaffMember> dentists;
  final VoidCallback onEditNotes;
  final VoidCallback onAddItem;
  final ValueChanged<TreatmentPlanItem> onEditItem;
  final ValueChanged<TreatmentPlanStatus> onPlanTransition;
  final void Function(TreatmentPlanItem, TreatmentPlanItemStatus)
  onItemTransition;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final plan = state.selectedPlan!;
    final draft = plan.status == TreatmentPlanStatus.draft;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(l.plansTitle, style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 8),
        SizedBox(
          height: 94,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: state.plans.length,
            separatorBuilder: (_, _) => const SizedBox(width: 8),
            itemBuilder: (context, index) {
              final option = state.plans[index];
              final selected = option.id == state.selectedPlanId;
              return SizedBox(
                width: 220,
                child: Card(
                  color: selected
                      ? Theme.of(context).colorScheme.secondaryContainer
                      : null,
                  child: ListTile(
                    onTap: () => context.read<TreatmentPlanCubit>().selectPlan(
                      option.id,
                    ),
                    title: Text(_planStatusLabel(option.status, l)),
                    subtitle: Text(
                      '${option.totalEstimatedCost.toDecimalString()} $currencyCode\n'
                      '${DateFormat.yMMMd().format(option.updatedAt.toLocal())}',
                    ),
                    isThreeLine: true,
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 16),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Wrap(
                  alignment: WrapAlignment.spaceBetween,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  spacing: 12,
                  runSpacing: 8,
                  children: [
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          _planStatusLabel(plan.status, l),
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        const SizedBox(width: 8),
                        Chip(
                          label: Text(
                            l.procedureCountValue(state.items.length),
                          ),
                        ),
                      ],
                    ),
                    Text(
                      '${plan.totalEstimatedCost.toDecimalString()} $currencyCode',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                  ],
                ),
                if (plan.notes != null) ...[
                  const SizedBox(height: 8),
                  Text(plan.notes!),
                ],
                if (canEdit && draft) ...[
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      OutlinedButton.icon(
                        onPressed: state.mutating ? null : onEditNotes,
                        icon: const Icon(Icons.edit_note),
                        label: Text(l.editNotesLabel),
                      ),
                      FilledButton.icon(
                        onPressed: state.mutating ? null : onAddItem,
                        icon: const Icon(Icons.add),
                        label: Text(l.addProcedureLabel),
                      ),
                      FilledButton.tonal(
                        onPressed: state.mutating
                            ? null
                            : () =>
                                  onPlanTransition(TreatmentPlanStatus.active),
                        child: Text(l.activatePlanLabel),
                      ),
                      TextButton(
                        onPressed: state.mutating
                            ? null
                            : () => onPlanTransition(
                                TreatmentPlanStatus.cancelled,
                              ),
                        child: Text(l.cancelPlanLabel),
                      ),
                    ],
                  ),
                ],
                if (canEdit && plan.status == TreatmentPlanStatus.active) ...[
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    children: [
                      FilledButton.tonal(
                        onPressed: state.mutating
                            ? null
                            : () => onPlanTransition(
                                TreatmentPlanStatus.completed,
                              ),
                        child: Text(l.completePlanLabel),
                      ),
                      TextButton(
                        onPressed: state.mutating
                            ? null
                            : () => onPlanTransition(
                                TreatmentPlanStatus.cancelled,
                              ),
                        child: Text(l.cancelPlanLabel),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        if (state.items.isEmpty)
          _MessageCard(message: l.planHasNoProcedures)
        else if (canEdit && draft)
          ReorderableListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: state.items.length,
            onReorderItem: (oldIndex, newIndex) {
              final ids = state.items.map((item) => item.id).toList();
              final moved = ids.removeAt(oldIndex);
              ids.insert(newIndex, moved);
              context.read<TreatmentPlanCubit>().reorderItems(plan.id, ids);
            },
            itemBuilder: (context, index) {
              final item = state.items[index];
              return _PlanItemCard(
                key: ValueKey(item.id),
                item: item,
                procedure: _procedure(state.procedures, item.procedureId),
                currencyCode: currencyCode,
                dentist: _dentist(dentists, item.assignedDentistId),
                canEditDraft: true,
                canTransition: false,
                mutating: state.mutating,
                onEdit: () => onEditItem(item),
                onTransition: (status) => onItemTransition(item, status),
              );
            },
          )
        else
          for (final item in state.items)
            _PlanItemCard(
              key: ValueKey(item.id),
              item: item,
              procedure: _procedure(state.procedures, item.procedureId),
              currencyCode: currencyCode,
              dentist: _dentist(dentists, item.assignedDentistId),
              canEditDraft: false,
              canTransition:
                  canEdit && plan.status == TreatmentPlanStatus.active,
              mutating: state.mutating,
              onEdit: () => onEditItem(item),
              onTransition: (status) => onItemTransition(item, status),
            ),
      ],
    );
  }

  ClinicProcedure? _procedure(List<ClinicProcedure> values, String id) {
    for (final value in values) {
      if (value.id == id) return value;
    }
    return null;
  }

  StaffMember? _dentist(List<StaffMember> values, String? id) {
    for (final value in values) {
      if (value.id == id) return value;
    }
    return null;
  }
}

class _PlanItemCard extends StatelessWidget {
  const _PlanItemCard({
    required this.item,
    required this.procedure,
    required this.currencyCode,
    required this.dentist,
    required this.canEditDraft,
    required this.canTransition,
    required this.mutating,
    required this.onEdit,
    required this.onTransition,
    super.key,
  });
  final TreatmentPlanItem item;
  final ClinicProcedure? procedure;
  final String currencyCode;
  final StaffMember? dentist;
  final bool canEditDraft;
  final bool canTransition;
  final bool mutating;
  final VoidCallback onEdit;
  final ValueChanged<TreatmentPlanItemStatus> onTransition;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final nextStatuses = _nextStatuses(item.status);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (canEditDraft)
              const Padding(
                padding: EdgeInsets.only(right: 8, top: 12),
                child: Icon(Icons.drag_handle),
              ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    procedure?.name ?? l.unavailableProcedure,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    [
                      if (item.toothNumber != null)
                        l.toothNumberValue(item.toothNumber!),
                      '${item.estimatedPrice.toDecimalString()} $currencyCode',
                      _itemStatusLabel(item.status, l),
                    ].join(' · '),
                  ),
                  if (item.description != null) Text(item.description!),
                  if (dentist != null) Text(l.dentistValue(dentist!.email)),
                ],
              ),
            ),
            if (canEditDraft)
              IconButton(
                onPressed: mutating ? null : onEdit,
                icon: const Icon(Icons.edit_outlined),
                tooltip: l.editProcedureLabel,
              ),
            if (canTransition && nextStatuses.isNotEmpty)
              PopupMenuButton<TreatmentPlanItemStatus>(
                enabled: !mutating,
                tooltip: l.changeStatusLabel,
                onSelected: onTransition,
                itemBuilder: (_) => nextStatuses
                    .map(
                      (status) => PopupMenuItem(
                        value: status,
                        child: Text(_itemStatusLabel(status, l)),
                      ),
                    )
                    .toList(growable: false),
              ),
          ],
        ),
      ),
    );
  }

  List<TreatmentPlanItemStatus> _nextStatuses(TreatmentPlanItemStatus status) =>
      switch (status) {
        TreatmentPlanItemStatus.planned => const [
          TreatmentPlanItemStatus.approved,
          TreatmentPlanItemStatus.cancelled,
        ],
        TreatmentPlanItemStatus.approved => const [
          TreatmentPlanItemStatus.inProgress,
          TreatmentPlanItemStatus.cancelled,
        ],
        TreatmentPlanItemStatus.inProgress => const [
          TreatmentPlanItemStatus.completed,
          TreatmentPlanItemStatus.cancelled,
        ],
        TreatmentPlanItemStatus.completed ||
        TreatmentPlanItemStatus.cancelled => const [],
      };
}

class _MessageCard extends StatelessWidget {
  const _MessageCard({required this.message});
  final String message;
  @override
  Widget build(BuildContext context) => Card(
    child: Padding(padding: const EdgeInsets.all(16), child: Text(message)),
  );
}

bool _validFdi(int number) {
  final quadrant = number ~/ 10;
  final tooth = number % 10;
  return (quadrant >= 1 && quadrant <= 4 && tooth >= 1 && tooth <= 8) ||
      (quadrant >= 5 && quadrant <= 8 && tooth >= 1 && tooth <= 5);
}

String? _optional(String value) {
  final trimmed = value.trim();
  return trimmed.isEmpty ? null : trimmed;
}

void _showMessage(BuildContext context, String message) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(content: Text(message)));
}

String _issueMessage(
  TreatmentPlanOperationIssue issue,
  AppLocalizations l,
) => switch (issue) {
  TreatmentPlanOperationIssue.forbidden => l.treatmentForbiddenIssue,
  TreatmentPlanOperationIssue.unavailable => l.treatmentUnavailableIssue,
  TreatmentPlanOperationIssue.invalidInput => l.treatmentInvalidInputIssue,
  TreatmentPlanOperationIssue.draftOnly => l.treatmentDraftOnlyIssue,
  TreatmentPlanOperationIssue.activeRequired => l.treatmentActiveRequiredIssue,
  TreatmentPlanOperationIssue.itemsRequired => l.treatmentItemsRequiredIssue,
  TreatmentPlanOperationIssue.activePlanExists => l.activePlanExistsIssue,
  TreatmentPlanOperationIssue.invalidTransition =>
    l.treatmentInvalidTransitionIssue,
};

String _planStatusLabel(TreatmentPlanStatus status, AppLocalizations l) =>
    switch (status) {
      TreatmentPlanStatus.draft => l.planStatusDraft,
      TreatmentPlanStatus.active => l.planStatusActive,
      TreatmentPlanStatus.completed => l.planStatusCompleted,
      TreatmentPlanStatus.cancelled => l.planStatusCancelled,
    };

String _itemStatusLabel(TreatmentPlanItemStatus status, AppLocalizations l) =>
    switch (status) {
      TreatmentPlanItemStatus.planned => l.itemStatusPlanned,
      TreatmentPlanItemStatus.approved => l.itemStatusApproved,
      TreatmentPlanItemStatus.inProgress => l.itemStatusInProgress,
      TreatmentPlanItemStatus.completed => l.itemStatusCompleted,
      TreatmentPlanItemStatus.cancelled => l.itemStatusCancelled,
    };

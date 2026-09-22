import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart' hide TextDirection;

import '../../../../app/localization/generated/app_localizations.dart';
import '../../../../app/theme/app_theme.dart';
import '../../../../core/error/failure_message.dart';
import '../../../../core/value/money.dart';
import '../../../../core/widgets/app_dialog.dart';
import '../../../clinic/presentation/clinic_cubit.dart';
import '../../../patient/domain/patient_models.dart';
import '../../../patient/presentation/patient_cubit.dart';
import '../../../patient/presentation/widgets/patient_medical_alert_banner.dart';
import '../../../treatment_plan/domain/treatment_plan_models.dart';
import '../../../treatment_plan/presentation/treatment_plan_cubit.dart';
import '../../domain/odontogram_models.dart';
import '../odontogram_cubit.dart';

enum JawView { both, upper, lower }

class DentalChartPage extends StatefulWidget {
  const DentalChartPage({required this.patientId, super.key});
  final String patientId;

  @override
  State<DentalChartPage> createState() => _DentalChartPageState();
}

class _DentalChartPageState extends State<DentalChartPage> {
  String? _loadedPatientId;
  Dentition _dentition = Dentition.permanent;
  JawView _jawView = JawView.both;
  int? _selectedTooth;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final mobile = AppBreakpoints.of(context) == AppLayoutClass.mobile;
    final roles =
        context.watch<ClinicCubit>().state.activeMembership?.roles ??
        const <String>{};
    final canRead =
        roles.contains('owner') ||
        roles.contains('dentist') ||
        roles.contains('assistant');
    final canEdit = roles.contains('dentist');
    final patient = context
        .watch<PatientCubit>()
        .state
        .patients
        .where((item) => item.id == widget.patientId)
        .firstOrNull;
    if (!canRead) return const _DentalChartUnavailable();
    if (patient == null) {
      return Scaffold(body: _DentalChartMessage(l.dentalChartUnavailable));
    }
    final clinic = context.watch<ClinicCubit>().state.activeClinic;
    if (_loadedPatientId != widget.patientId) {
      _loadedPatientId = widget.patientId;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        context.read<OdontogramCubit>().load(widget.patientId);
        if (clinic != null) {
          try {
            context
                .read<TreatmentPlanCubit>()
                .loadPatient(clinic.id, widget.patientId);
          } catch (_) {}
        }
      });
    }
    return Scaffold(
      appBar: AppBar(
        title: Text(l.dentalChartTitle),
        leading: IconButton(
          onPressed: () => context.go('/patients/${widget.patientId}'),
          icon: const Icon(Icons.arrow_back),
          tooltip: l.backToPatientProfile,
        ),
      ),
      body: BlocConsumer<OdontogramCubit, OdontogramState>(
        listener: (context, state) {
          final message = state.issue == null
              ? null
              : _issueMessage(state.issue!, l);
          if (message != null) {
            ScaffoldMessenger.of(context)
              ..hideCurrentSnackBar()
              ..showSnackBar(SnackBar(content: Text(message)));
          }
        },
        builder: (context, state) {
          TreatmentPlanState treatmentState = const TreatmentPlanState();
          try {
            treatmentState = context.watch<TreatmentPlanCubit>().state;
          } catch (_) {}
          final toothTreatmentItems = _selectedTooth == null
              ? const <TreatmentPlanItem>[]
              : treatmentState.items
                  .where((item) => item.toothNumber == _selectedTooth)
                  .toList(growable: false);

          return ListView(
            padding: AppInsets.page(AppBreakpoints.of(context)),
            children: [
              _PatientHeader(patient: patient),
              const SizedBox(height: 12),
              PatientMedicalAlertBanner(patientId: widget.patientId),
              const SizedBox(height: 16),
              if (mobile)
                DropdownButtonFormField<Dentition>(
                  key: const ValueKey('dentition-selector'),
                  isExpanded: true,
                  initialValue: _dentition,
                  decoration: InputDecoration(labelText: l.dentitionLabel),
                  items: [
                    DropdownMenuItem(
                      value: Dentition.permanent,
                      child: Text(l.permanentTeethLabel),
                    ),
                    DropdownMenuItem(
                      value: Dentition.primary,
                      child: Text(l.primaryTeethLabel),
                    ),
                  ],
                  onChanged: (value) => setState(() {
                    _dentition = value!;
                    _selectedTooth = null;
                  }),
                )
              else
                SegmentedButton<Dentition>(
                  segments: [
                    ButtonSegment(
                      value: Dentition.permanent,
                      label: Text(l.permanentTeethLabel),
                    ),
                    ButtonSegment(
                      value: Dentition.primary,
                      label: Text(l.primaryTeethLabel),
                    ),
                  ],
                  selected: {_dentition},
                  onSelectionChanged: (selection) => setState(() {
                    _dentition = selection.first;
                    _selectedTooth = null;
                  }),
                ),
              const SizedBox(height: 12),
              SegmentedButton<JawView>(
                key: const ValueKey('jaw-view-selector'),
                segments: [
                  ButtonSegment(
                    value: JawView.both,
                    icon: const Icon(Icons.grid_view_rounded, size: 16),
                    label: Text(l.jawViewAll),
                  ),
                  ButtonSegment(
                    value: JawView.upper,
                    icon: const Icon(Icons.arrow_upward_rounded, size: 16),
                    label: Text(l.jawViewUpper),
                  ),
                  ButtonSegment(
                    value: JawView.lower,
                    icon: const Icon(Icons.arrow_downward_rounded, size: 16),
                    label: Text(l.jawViewLower),
                  ),
                ],
                selected: {_jawView},
                onSelectionChanged: (selection) => setState(() {
                  unawaited(HapticFeedback.lightImpact());
                  _jawView = selection.first;
                }),
              ),
              const SizedBox(height: 16),
              if (state.status == OdontogramLoadStatus.loading)
                const LinearProgressIndicator(),
              if (state.failure != null) ...[
                const SizedBox(height: 12),
                _DentalChartMessage(
                  failureMessage(state.failure!, AppLocalizations.of(context)),
                ),
              ],
              const SizedBox(height: 12),
              _ToothArch(
                dentition: _dentition,
                jawView: _jawView,
                selectedTooth: _selectedTooth,
                conditions: state.active,
                onSelected: (tooth) {
                  unawaited(HapticFeedback.lightImpact());
                  setState(() => _selectedTooth = tooth);
                },
              ),
              if (canEdit && _selectedTooth == null) ...[
                const SizedBox(height: 12),
                FilledButton.icon(
                  onPressed: null,
                  icon: const Icon(Icons.touch_app_outlined),
                  label: Text(l.selectToothToAdd),
                ),
              ],
              const SizedBox(height: 16),
              _SelectedToothPanel(
                toothNumber: _selectedTooth,
                currencyCode: context
                        .watch<ClinicCubit>()
                        .state
                        .activeClinic
                        ?.currencyCode ??
                    'USD',
                conditions: state.active
                    .where((condition) => condition.toothNumber == _selectedTooth)
                    .toList(growable: false),
                treatmentItems: toothTreatmentItems,
                procedures: treatmentState.procedures,
                canEdit: canEdit,
                mutating: state.mutating || treatmentState.mutating,
                onResolve: (condition) => _confirmResolve(context, condition),
                onMarkInError: (condition) =>
                    _showCorrectionReason(context, condition),
                onAddCondition: () => _showAddCondition(context, state),
                onAddTreatment: (procedure) => _showAddProcedureToPlan(
                  context,
                  procedure,
                  _selectedTooth!,
                ),
                onSelectProcedureFromCatalogue: () => _showProcedurePicker(
                  context,
                  _selectedTooth!,
                  treatmentState.procedures,
                ),
                onSchedule: ({procedureName, durationMinutes}) =>
                    _scheduleForTooth(
                  toothNumber: _selectedTooth!,
                  procedureName: procedureName,
                  durationMinutes: durationMinutes,
                ),
              ),
              const SizedBox(height: 16),
              _HistorySection(
                history: state.history,
                hasMore: state.historyHasMore,
                loadingMore: state.loadingMore,
                onLoadMore: () =>
                    context.read<OdontogramCubit>().loadMoreHistory(),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _showAddCondition(
    BuildContext context,
    OdontogramState state,
  ) async {
    final selectedTooth = _selectedTooth;
    if (selectedTooth == null) {
      final l = AppLocalizations.of(context);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(l.selectToothFirst)));
      return;
    }
    final notes = TextEditingController();
    var type = ToothConditionType.caries;
    var surface = ToothSurface.whole;
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (sheetContext) => StatefulBuilder(
        builder: (context, setSheetState) {
          final l = AppLocalizations.of(context);
          return Padding(
            padding: EdgeInsets.fromLTRB(
              24,
              24,
              24,
              MediaQuery.viewInsetsOf(context).bottom + 24,
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    l.addConditionTitle(selectedTooth),
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<ToothConditionType>(
                    isExpanded: true,
                    initialValue: type,
                    decoration: InputDecoration(labelText: l.conditionLabel),
                    items: ToothConditionType.values
                        .map(
                          (item) => DropdownMenuItem(
                            value: item,
                            child: Text(_conditionLabel(item, l)),
                          ),
                        )
                        .toList(growable: false),
                    onChanged: (value) => setSheetState(() {
                      type = value!;
                      if (type.wholeToothOnly) surface = ToothSurface.whole;
                    }),
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<ToothSurface>(
                    isExpanded: true,
                    initialValue: surface,
                    decoration: InputDecoration(labelText: l.surfaceLabel),
                    items: ToothSurface.values
                        .where(
                          (item) =>
                              !type.wholeToothOnly ||
                              item == ToothSurface.whole,
                        )
                        .map(
                          (item) => DropdownMenuItem(
                            value: item,
                            child: Text(_surfaceLabel(item, l)),
                          ),
                        )
                        .toList(growable: false),
                    onChanged: (value) => setSheetState(() => surface = value!),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: notes,
                    maxLength: 2000,
                    maxLines: 3,
                    decoration: InputDecoration(
                      labelText: l.clinicalNoteOptional,
                    ),
                  ),
                  const SizedBox(height: 12),
                  FilledButton(
                    onPressed: () async {
                      final succeeded = await context
                          .read<OdontogramCubit>()
                          .create(
                            patientId: widget.patientId,
                            draft: ToothConditionDraft(
                              toothNumber: selectedTooth,
                              surface: surface,
                              type: type,
                              notes: notes.text.trim().isEmpty
                                  ? null
                                  : notes.text.trim(),
                            ),
                          );
                      if (succeeded && context.mounted) Navigator.pop(context);
                    },
                    child: Text(l.saveConditionLabel),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
    notes.dispose();
  }

  Future<void> _confirmResolve(
    BuildContext context,
    ToothCondition condition,
  ) async {
    final l = AppLocalizations.of(context);
    final approved = await showSettledDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(l.resolveConditionQuestion),
        content: Text(
          l.resolveConditionExplanation(
            _conditionLabel(condition.type, l),
            condition.toothNumber,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: Text(l.cancelLabel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: Text(l.resolveLabel),
          ),
        ],
      ),
    );
    if (approved != true || !context.mounted) return;
    await context.read<OdontogramCubit>().resolve(
      patientId: widget.patientId,
      conditionId: condition.id,
    );
  }

  Future<void> _showCorrectionReason(
    BuildContext context,
    ToothCondition condition,
  ) async {
    final l = AppLocalizations.of(context);
    final reason = TextEditingController();
    await showSettledDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(l.markEntryErrorTitle),
        content: TextField(
          controller: reason,
          autofocus: true,
          maxLength: 1000,
          maxLines: 3,
          decoration: InputDecoration(labelText: l.entryErrorReasonLabel),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text(l.cancelLabel),
          ),
          FilledButton(
            onPressed: () async {
              if (reason.text.trim().isEmpty) return;
              final succeeded = await context
                  .read<OdontogramCubit>()
                  .markInError(
                    patientId: widget.patientId,
                    conditionId: condition.id,
                    reason: reason.text.trim(),
                  );
              if (succeeded && dialogContext.mounted) {
                Navigator.pop(dialogContext);
              }
            },
            child: Text(l.preserveAsErrorLabel),
          ),
        ],
      ),
    );
    reason.dispose();
  }

  void _scheduleForTooth({
    required int toothNumber,
    String? procedureName,
    int? durationMinutes,
  }) {
    final l = AppLocalizations.of(context);
    final toothTitle = l.toothNumberValue(toothNumber);
    final purpose = procedureName != null
        ? '$toothTitle - $procedureName'
        : toothTitle;
    context.go(
      Uri(
        path: '/appointments/new',
        queryParameters: {
          'patientId': widget.patientId,
          'purpose': purpose,
          if (durationMinutes != null && durationMinutes > 0)
            'duration': '$durationMinutes',
        },
      ).toString(),
    );
  }

  Future<void> _showAddProcedureToPlan(
    BuildContext context,
    ClinicProcedure procedure,
    int toothNumber,
  ) async {
    final currency =
        context.read<ClinicCubit>().state.activeClinic?.currencyCode ?? 'USD';
    final priceController = TextEditingController(
      text: procedure.defaultPrice.toDecimalString(),
    );
    final notesController = TextEditingController();
    final l = AppLocalizations.of(context);
    final theme = Theme.of(context);

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (sheetContext) => Padding(
        padding: EdgeInsets.fromLTRB(
          24,
          8,
          24,
          MediaQuery.viewInsetsOf(sheetContext).bottom + 24,
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                l.addTreatmentForTooth,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '${procedure.name} (${procedure.category}) - ${l.toothNumberValue(toothNumber)}',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: priceController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: InputDecoration(
                  labelText: l.estimatedPriceLabel,
                  suffixText: currency,
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: notesController,
                maxLength: 500,
                decoration: InputDecoration(
                  labelText: l.planNotesOptional,
                ),
              ),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: () async {
                  final price = Money.tryParseUserInput(priceController.text);
                  if (price == null) return;
                  final notes = notesController.text.trim();
                  Navigator.of(sheetContext).pop();
                  final planCubit = context.read<TreatmentPlanCubit>();
                  final membership =
                      context.read<ClinicCubit>().state.activeMembership;

                  var plan =
                      planCubit.state.selectedPlan ??
                      planCubit.state.plans.firstOrNull;
                  final memberId = membership?.memberId;
                  if (plan == null && memberId != null && memberId.isNotEmpty) {
                    await planCubit.createPlan(
                      patientId: widget.patientId,
                      dentistMemberId: memberId,
                    );
                    plan =
                        planCubit.state.selectedPlan ??
                        planCubit.state.plans.firstOrNull;
                  }
                  if (plan != null) {
                    final ok = await planCubit.addItem(
                      plan.id,
                      TreatmentPlanItemDraft(
                        procedureId: procedure.id,
                        toothNumber: toothNumber,
                        estimatedPrice: price,
                        description: notes.isEmpty ? null : notes,
                        assignedDentistId: membership?.memberId,
                      ),
                    );
                    if (ok && context.mounted) {
                      ScaffoldMessenger.of(context)
                        ..hideCurrentSnackBar()
                        ..showSnackBar(
                          SnackBar(content: Text(l.procedureAddedToPlan)),
                        );
                    }
                  }
                },
                child: Text(l.saveLabel),
              ),
            ],
          ),
        ),
      ),
    );
    priceController.dispose();
    notesController.dispose();
  }

  Future<void> _showProcedurePicker(
    BuildContext context,
    int toothNumber,
    List<ClinicProcedure> procedures,
  ) async {
    final l = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final currency =
        context.read<ClinicCubit>().state.activeClinic?.currencyCode ?? 'USD';
    final active = procedures.where((p) => p.active).toList(growable: false);
    String query = '';

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (sheetContext) => StatefulBuilder(
        builder: (context, setSheetState) {
          final filtered = query.trim().isEmpty
              ? active
              : active
                    .where(
                      (p) =>
                          p.name.toLowerCase().contains(query.toLowerCase()) ||
                          p.category.toLowerCase().contains(
                            query.toLowerCase(),
                          ),
                    )
                    .toList(growable: false);

          return SizedBox(
            height: MediaQuery.sizeOf(context).height * 0.7,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                children: [
                  Text(
                    l.selectProcedureToAdd,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    decoration: InputDecoration(
                      prefixIcon: const Icon(Icons.search),
                      hintText: l.searchProceduresPlaceholder,
                      contentPadding: EdgeInsets.zero,
                    ),
                    onChanged: (value) =>
                        setSheetState(() => query = value),
                  ),
                  const SizedBox(height: 12),
                  Expanded(
                    child: filtered.isEmpty
                        ? Center(
                            child: Text(
                              l.noMatchingProcedures,
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                          )
                        : ListView.separated(
                            itemCount: filtered.length,
                            separatorBuilder: (context, index) =>
                                const Divider(height: 1),
                            itemBuilder: (context, index) {
                              final p = filtered[index];
                              return ListTile(
                                leading: CircleAvatar(
                                  radius: 16,
                                  backgroundColor:
                                      theme.colorScheme.primaryContainer,
                                  child: Icon(
                                    Icons.medical_services_outlined,
                                    size: 16,
                                    color: theme.colorScheme.primary,
                                  ),
                                ),
                                title: Text(
                                  p.name,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                subtitle: Text(
                                  '${p.category} · ${p.durationMinutes} min',
                                ),
                                trailing: Text(
                                  '${p.defaultPrice.toDecimalString()} $currency',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: theme.colorScheme.primary,
                                  ),
                                ),
                                onTap: () {
                                  Navigator.of(sheetContext).pop();
                                  _showAddProcedureToPlan(
                                    context,
                                    p,
                                    toothNumber,
                                  );
                                },
                              );
                            },
                          ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  String _issueMessage(OdontogramOperationIssue issue, AppLocalizations l) =>
      switch (issue) {
        OdontogramOperationIssue.forbidden => l.odontogramForbiddenIssue,
        OdontogramOperationIssue.unavailable => l.odontogramUnavailableIssue,
        OdontogramOperationIssue.invalidInput => l.odontogramInvalidInputIssue,
        OdontogramOperationIssue.missingToothConflict =>
          l.missingToothConflictIssue,
        OdontogramOperationIssue.duplicateActiveCondition =>
          l.duplicateConditionIssue,
        OdontogramOperationIssue.conditionNotActive =>
          l.conditionNotActiveIssue,
      };
}

class _PatientHeader extends StatelessWidget {
  const _PatientHeader({required this.patient});
  final Patient patient;

  @override
  Widget build(BuildContext context) => Card(
    child: ListTile(
      leading: const Icon(Icons.person_outline),
      title: Text(patient.fullName),
      subtitle: Text(patient.patientNumber),
    ),
  );
}

class _ToothArch extends StatelessWidget {
  const _ToothArch({
    required this.dentition,
    required this.selectedTooth,
    required this.conditions,
    required this.onSelected,
    this.jawView = JawView.both,
  });
  final Dentition dentition;
  final int? selectedTooth;
  final List<ToothCondition> conditions;
  final ValueChanged<int> onSelected;
  final JawView jawView;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final isPermanent = dentition == Dentition.permanent;
    final upperRight = isPermanent
        ? const [18, 17, 16, 15, 14, 13, 12, 11]
        : const [55, 54, 53, 52, 51];
    final upperLeft = isPermanent
        ? const [21, 22, 23, 24, 25, 26, 27, 28]
        : const [61, 62, 63, 64, 65];
    final lowerRight = isPermanent
        ? const [48, 47, 46, 45, 44, 43, 42, 41]
        : const [85, 84, 83, 82, 81];
    final lowerLeft = isPermanent
        ? const [31, 32, 33, 34, 35, 36, 37, 38]
        : const [71, 72, 73, 74, 75];

    final showUpper = jawView == JawView.both || jawView == JawView.upper;
    final showLower = jawView == JawView.both || jawView == JawView.lower;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Directionality(
          textDirection: TextDirection.ltr,
          child: LayoutBuilder(
            builder: (context, constraints) {
              final contentWidth = constraints.maxWidth > 780
                  ? constraints.maxWidth
                  : 780.0;
              return SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: SizedBox(
                  width: contentWidth,
                  child: Column(
                    children: [
                      if (showUpper) ...[
                        _QuadrantHeader(
                          leftLabel: l.quadrantUpperRight,
                          rightLabel: l.quadrantUpperLeft,
                          midlineLabel: l.dentalMidline,
                        ),
                        const SizedBox(height: 6),
                        _ArchRow(
                          leftTeeth: upperRight,
                          rightTeeth: upperLeft,
                          isUpper: true,
                          selectedTooth: selectedTooth,
                          conditions: conditions,
                          onSelected: onSelected,
                        ),
                      ],
                      if (showUpper && showLower) ...[
                        const SizedBox(height: 8),
                        _JawDivider(
                          upperLabel: l.maxillaUpperJaw,
                          lowerLabel: l.mandibleLowerJaw,
                        ),
                        const SizedBox(height: 8),
                      ],
                      if (showLower) ...[
                        _ArchRow(
                          leftTeeth: lowerRight,
                          rightTeeth: lowerLeft,
                          isUpper: false,
                          selectedTooth: selectedTooth,
                          conditions: conditions,
                          onSelected: onSelected,
                        ),
                        const SizedBox(height: 6),
                        _QuadrantHeader(
                          leftLabel: l.quadrantLowerRight,
                          rightLabel: l.quadrantLowerLeft,
                          midlineLabel: l.dentalMidline,
                        ),
                      ],
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

class _QuadrantHeader extends StatelessWidget {
  const _QuadrantHeader({
    required this.leftLabel,
    required this.rightLabel,
    required this.midlineLabel,
  });

  final String leftLabel;
  final String rightLabel;
  final String midlineLabel;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Row(
        children: [
          Expanded(
            child: Text(
              leftLabel,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.labelMedium?.copyWith(
                fontWeight: FontWeight.w700,
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: theme.colorScheme.primaryContainer.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              midlineLabel,
              style: theme.textTheme.labelSmall?.copyWith(
                fontWeight: FontWeight.w700,
                color: theme.colorScheme.primary,
              ),
            ),
          ),
          Expanded(
            child: Text(
              rightLabel,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.right,
              style: theme.textTheme.labelMedium?.copyWith(
                fontWeight: FontWeight.w700,
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _JawDivider extends StatelessWidget {
  const _JawDivider({required this.upperLabel, required this.lowerLabel});

  final String upperLabel;
  final String lowerLabel;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      children: [
        Expanded(
          child: Container(
            height: 1.5,
            color: theme.colorScheme.outlineVariant.withValues(alpha: 0.6),
          ),
        ),
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 8),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
          decoration: BoxDecoration(
            color: theme.colorScheme.surfaceContainerHighest.withValues(
              alpha: 0.5,
            ),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: theme.colorScheme.outlineVariant.withValues(alpha: 0.4),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.arrow_upward,
                size: 11,
                color: theme.colorScheme.primary,
              ),
              const SizedBox(width: 4),
              Text(
                upperLabel,
                style: theme.textTheme.labelSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: theme.colorScheme.primary,
                ),
              ),
              const SizedBox(width: 6),
              Text(
                '·',
                style: theme.textTheme.labelSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(width: 6),
              Text(
                lowerLabel,
                style: theme.textTheme.labelSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: theme.colorScheme.secondary,
                ),
              ),
              const SizedBox(width: 4),
              Icon(
                Icons.arrow_downward,
                size: 11,
                color: theme.colorScheme.secondary,
              ),
            ],
          ),
        ),
        Expanded(
          child: Container(
            height: 1.5,
            color: theme.colorScheme.outlineVariant.withValues(alpha: 0.6),
          ),
        ),
      ],
    );
  }
}

class _ArchRow extends StatelessWidget {
  const _ArchRow({
    required this.leftTeeth,
    required this.rightTeeth,
    required this.isUpper,
    required this.selectedTooth,
    required this.conditions,
    required this.onSelected,
  });

  final List<int> leftTeeth;
  final List<int> rightTeeth;
  final bool isUpper;
  final int? selectedTooth;
  final List<ToothCondition> conditions;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        for (final tooth in leftTeeth) ...[
          _ToothButton(
            toothNumber: tooth,
            isUpper: isUpper,
            selected: tooth == selectedTooth,
            conditions: conditions
                .where((c) => c.toothNumber == tooth)
                .toList(growable: false),
            onTap: () => onSelected(tooth),
          ),
          if (tooth != leftTeeth.last) const SizedBox(width: 4),
        ],
        Container(
          width: 2,
          height: 64,
          margin: const EdgeInsets.symmetric(horizontal: 8),
          decoration: BoxDecoration(
            color: theme.colorScheme.primary.withValues(alpha: 0.45),
            borderRadius: BorderRadius.circular(1),
          ),
        ),
        for (final tooth in rightTeeth) ...[
          _ToothButton(
            toothNumber: tooth,
            isUpper: isUpper,
            selected: tooth == selectedTooth,
            conditions: conditions
                .where((c) => c.toothNumber == tooth)
                .toList(growable: false),
            onTap: () => onSelected(tooth),
          ),
          if (tooth != rightTeeth.last) const SizedBox(width: 4),
        ],
      ],
    );
  }
}

class _ToothButton extends StatelessWidget {
  const _ToothButton({
    required this.toothNumber,
    required this.isUpper,
    required this.selected,
    required this.conditions,
    required this.onTap,
  });

  final int toothNumber;
  final bool isUpper;
  final bool selected;
  final List<ToothCondition> conditions;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final theme = Theme.of(context);
    return Semantics(
      button: true,
      selected: selected,
      label: conditions.isEmpty
          ? l.toothHealthySemantics(toothNumber)
          : l.toothConditionsSemantics(toothNumber, conditions.length),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(6),
        child: Container(
          width: 44,
          constraints: const BoxConstraints(minHeight: 68),
          padding: const EdgeInsets.symmetric(vertical: 3, horizontal: 2),
          decoration: BoxDecoration(
            color: selected
                ? theme.colorScheme.primaryContainer.withValues(alpha: 0.35)
                : theme.colorScheme.surfaceContainerLow,
            borderRadius: BorderRadius.circular(6),
            border: Border.all(
              color: selected
                  ? theme.colorScheme.primary
                  : theme.colorScheme.outlineVariant.withValues(alpha: 0.6),
              width: selected ? 2 : 1,
            ),
          ),
          child: Stack(
            alignment: Alignment.center,
            children: [
              Column(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: isUpper
                    ? [
                        Text(
                          '$toothNumber',
                          textScaler: TextScaler.noScaling,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: selected
                                ? FontWeight.w800
                                : FontWeight.w700,
                            color: selected
                                ? theme.colorScheme.primary
                                : theme.colorScheme.onSurface,
                          ),
                        ),
                        const SizedBox(height: 2),
                        CustomPaint(
                          size: const Size(34, 34),
                          painter: _ToothSurfacePainter(
                            toothNumber: toothNumber,
                            isUpper: isUpper,
                            conditions: conditions,
                            colorScheme: theme.colorScheme,
                          ),
                        ),
                      ]
                    : [
                        CustomPaint(
                          size: const Size(34, 34),
                          painter: _ToothSurfacePainter(
                            toothNumber: toothNumber,
                            isUpper: isUpper,
                            conditions: conditions,
                            colorScheme: theme.colorScheme,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '$toothNumber',
                          textScaler: TextScaler.noScaling,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: selected
                                ? FontWeight.w800
                                : FontWeight.w700,
                            color: selected
                                ? theme.colorScheme.primary
                                : theme.colorScheme.onSurface,
                          ),
                        ),
                      ],
              ),
              if (conditions.length > 1)
                Positioned(
                  right: 0,
                  top: 0,
                  child: Container(
                    padding: const EdgeInsets.all(2),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primary,
                      shape: BoxShape.circle,
                    ),
                    constraints: const BoxConstraints(
                      minWidth: 14,
                      minHeight: 14,
                    ),
                    child: Center(
                      child: Text(
                        '${conditions.length}',
                        textScaler: TextScaler.noScaling,
                        style: TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.bold,
                          color: theme.colorScheme.onPrimary,
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ToothSurfacePainter extends CustomPainter {
  const _ToothSurfacePainter({
    required this.toothNumber,
    required this.isUpper,
    required this.conditions,
    required this.colorScheme,
  });

  final int toothNumber;
  final bool isUpper;
  final List<ToothCondition> conditions;
  final ColorScheme colorScheme;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    final isRightQuadrant =
        (toothNumber >= 11 && toothNumber <= 18) ||
        (toothNumber >= 41 && toothNumber <= 48) ||
        (toothNumber >= 51 && toothNumber <= 55) ||
        (toothNumber >= 81 && toothNumber <= 85);

    ToothCondition? occlusalCondition;
    ToothCondition? buccalCondition;
    ToothCondition? lingualCondition;
    ToothCondition? mesialCondition;
    ToothCondition? distalCondition;
    ToothCondition? wholeCondition;

    for (final c in conditions) {
      switch (c.surface) {
        case ToothSurface.occlusal:
          occlusalCondition ??= c;
        case ToothSurface.buccal:
          buccalCondition ??= c;
        case ToothSurface.lingual:
          lingualCondition ??= c;
        case ToothSurface.mesial:
          mesialCondition ??= c;
        case ToothSurface.distal:
          distalCondition ??= c;
        case ToothSurface.whole:
          wholeCondition ??= c;
      }
    }

    final topCondition = isUpper ? buccalCondition : lingualCondition;
    final bottomCondition = isUpper ? lingualCondition : buccalCondition;
    final leftCondition = isRightQuadrant ? distalCondition : mesialCondition;
    final rightCondition = isRightQuadrant ? mesialCondition : distalCondition;
    final centerCondition = occlusalCondition;

    final centerRect = Rect.fromCenter(
      center: Offset(w / 2, h / 2),
      width: w * 0.44,
      height: h * 0.44,
    );

    final defaultFill = colorScheme.surfaceContainerHighest.withValues(
      alpha: 0.5,
    );

    // Top trapezoid
    final topPath = Path()
      ..moveTo(0, 0)
      ..lineTo(w, 0)
      ..lineTo(centerRect.right, centerRect.top)
      ..lineTo(centerRect.left, centerRect.top)
      ..close();
    _drawSurface(canvas, topPath, topCondition, defaultFill);

    // Bottom trapezoid
    final bottomPath = Path()
      ..moveTo(centerRect.left, centerRect.bottom)
      ..lineTo(centerRect.right, centerRect.bottom)
      ..lineTo(w, h)
      ..lineTo(0, h)
      ..close();
    _drawSurface(canvas, bottomPath, bottomCondition, defaultFill);

    // Left trapezoid
    final leftPath = Path()
      ..moveTo(0, 0)
      ..lineTo(centerRect.left, centerRect.top)
      ..lineTo(centerRect.left, centerRect.bottom)
      ..lineTo(0, h)
      ..close();
    _drawSurface(canvas, leftPath, leftCondition, defaultFill);

    // Right trapezoid
    final rightPath = Path()
      ..moveTo(w, 0)
      ..lineTo(centerRect.right, centerRect.top)
      ..lineTo(centerRect.right, centerRect.bottom)
      ..lineTo(w, h)
      ..close();
    _drawSurface(canvas, rightPath, rightCondition, defaultFill);

    // Center surface (Occlusal / Incisal)
    final centerPath = Path()..addRect(centerRect);
    _drawSurface(canvas, centerPath, centerCondition, defaultFill);

    // Surface outlines
    final borderPaint = Paint()
      ..color = colorScheme.outlineVariant.withValues(alpha: 0.8)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(0, 0, w, h),
        const Radius.circular(3),
      ),
      borderPaint,
    );
    canvas.drawLine(const Offset(0, 0), centerRect.topLeft, borderPaint);
    canvas.drawLine(Offset(w, 0), centerRect.topRight, borderPaint);
    canvas.drawLine(Offset(0, h), centerRect.bottomLeft, borderPaint);
    canvas.drawLine(Offset(w, h), centerRect.bottomRight, borderPaint);
    canvas.drawRect(centerRect, borderPaint);

    // Whole tooth special indicators
    if (wholeCondition != null) {
      _drawWholeToothCondition(canvas, size, wholeCondition);
    }
  }

  void _drawSurface(
    Canvas canvas,
    Path path,
    ToothCondition? condition,
    Color defaultFill,
  ) {
    final paint = Paint()..style = PaintingStyle.fill;
    if (condition != null) {
      paint.color = _conditionColor(
        condition.type,
        colorScheme,
      ).withValues(alpha: 0.85);
    } else {
      paint.color = defaultFill;
    }
    canvas.drawPath(path, paint);
  }

  void _drawWholeToothCondition(
    Canvas canvas,
    Size size,
    ToothCondition condition,
  ) {
    final w = size.width;
    final h = size.height;
    switch (condition.type) {
      case ToothConditionType.missing:
        final crossPaint = Paint()
          ..color = Colors.grey.shade600
          ..strokeWidth = 2.5
          ..strokeCap = StrokeCap.round;
        canvas.drawLine(const Offset(2, 2), Offset(w - 2, h - 2), crossPaint);
        canvas.drawLine(Offset(w - 2, 2), Offset(2, h - 2), crossPaint);
      case ToothConditionType.extractionRequired:
        final crossPaint = Paint()
          ..color = Colors.red.shade900
          ..strokeWidth = 2.5
          ..strokeCap = StrokeCap.round;
        canvas.drawLine(const Offset(2, 2), Offset(w - 2, h - 2), crossPaint);
        canvas.drawLine(Offset(w - 2, 2), Offset(2, h - 2), crossPaint);
      case ToothConditionType.crown:
        final crownPaint = Paint()
          ..color = Colors.amber.shade800
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.5;
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromLTWH(1, 1, w - 2, h - 2),
            const Radius.circular(3),
          ),
          crownPaint,
        );
      case ToothConditionType.rootCanal:
        final canalPaint = Paint()
          ..color = Colors.deepPurple
          ..strokeWidth = 3.0
          ..strokeCap = StrokeCap.round;
        canvas.drawLine(Offset(w / 2, 2), Offset(w / 2, h - 2), canalPaint);
      case ToothConditionType.implant:
        final implantPaint = Paint()
          ..color = Colors.teal
          ..strokeWidth = 2.0
          ..style = PaintingStyle.stroke;
        canvas.drawCircle(Offset(w / 2, h / 2), 6, implantPaint);
      default:
        final fillPaint = Paint()
          ..color = _conditionColor(
            condition.type,
            colorScheme,
          ).withValues(alpha: 0.35)
          ..style = PaintingStyle.fill;
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromLTWH(0, 0, w, h),
            const Radius.circular(3),
          ),
          fillPaint,
        );
    }
  }

  @override
  bool shouldRepaint(covariant _ToothSurfacePainter oldDelegate) =>
      oldDelegate.toothNumber != toothNumber ||
      oldDelegate.isUpper != isUpper ||
      oldDelegate.conditions != conditions ||
      oldDelegate.colorScheme != colorScheme;
}

List<ClinicProcedure> _suggestedProcedures({
  required List<ToothCondition> conditions,
  required List<ClinicProcedure> procedures,
}) {
  final activeProcedures = procedures.where((p) => p.active).toList();
  if (conditions.isEmpty) {
    return activeProcedures
        .where((p) {
          final name = p.name.toLowerCase();
          final cat = p.category.toLowerCase();
          return name.contains('exam') ||
              name.contains('clean') ||
              name.contains('scaling') ||
              name.contains('فحص') ||
              name.contains('تنظيف') ||
              cat.contains('preventive') ||
              cat.contains('وقائي');
        })
        .take(3)
        .toList();
  }

  final suggestions = <ClinicProcedure>{};
  for (final cond in conditions) {
    switch (cond.type) {
      case ToothConditionType.caries:
        suggestions.addAll(
          activeProcedures.where((p) {
            final name = p.name.toLowerCase();
            final cat = p.category.toLowerCase();
            return name.contains('composite') ||
                name.contains('filling') ||
                name.contains('restor') ||
                name.contains('حشو') ||
                name.contains('ترميم') ||
                name.contains('пломб') ||
                cat.contains('restor') ||
                cat.contains('ترميم');
          }),
        );
      case ToothConditionType.rootCanal:
        suggestions.addAll(
          activeProcedures.where((p) {
            final name = p.name.toLowerCase();
            final cat = p.category.toLowerCase();
            return name.contains('root canal') ||
                name.contains('endo') ||
                name.contains('pulp') ||
                name.contains('عصب') ||
                name.contains('جذور') ||
                name.contains('пульп') ||
                name.contains('канал') ||
                cat.contains('endo') ||
                cat.contains('عصب');
          }),
        );
      case ToothConditionType.fracture:
      case ToothConditionType.crown:
        suggestions.addAll(
          activeProcedures.where((p) {
            final name = p.name.toLowerCase();
            final cat = p.category.toLowerCase();
            return name.contains('crown') ||
                name.contains('post') ||
                name.contains('core') ||
                name.contains('تاج') ||
                name.contains('تلبيس') ||
                name.contains('وتد') ||
                name.contains('коронк') ||
                cat.contains('prostho') ||
                cat.contains('تركيب');
          }),
        );
      case ToothConditionType.missing:
      case ToothConditionType.extractionRequired:
        suggestions.addAll(
          activeProcedures.where((p) {
            final name = p.name.toLowerCase();
            final cat = p.category.toLowerCase();
            return name.contains('extract') ||
                name.contains('implant') ||
                name.contains('surg') ||
                name.contains('خلع') ||
                name.contains('قلع') ||
                name.contains('زراع') ||
                name.contains('جراح') ||
                name.contains('удал') ||
                name.contains('имплант') ||
                cat.contains('surg') ||
                cat.contains('جراح');
          }),
        );
      case ToothConditionType.filling:
      case ToothConditionType.implant:
        break;
    }
  }
  return suggestions.take(4).toList();
}

class _SelectedToothPanel extends StatelessWidget {
  const _SelectedToothPanel({
    required this.toothNumber,
    required this.currencyCode,
    required this.conditions,
    required this.treatmentItems,
    required this.procedures,
    required this.canEdit,
    required this.mutating,
    required this.onResolve,
    required this.onMarkInError,
    required this.onAddCondition,
    required this.onAddTreatment,
    required this.onSelectProcedureFromCatalogue,
    required this.onSchedule,
  });

  final int? toothNumber;
  final String currencyCode;
  final List<ToothCondition> conditions;
  final List<TreatmentPlanItem> treatmentItems;
  final List<ClinicProcedure> procedures;
  final bool canEdit;
  final bool mutating;
  final ValueChanged<ToothCondition> onResolve;
  final ValueChanged<ToothCondition> onMarkInError;
  final VoidCallback onAddCondition;
  final ValueChanged<ClinicProcedure> onAddTreatment;
  final VoidCallback onSelectProcedureFromCatalogue;
  final void Function({String? procedureName, int? durationMinutes}) onSchedule;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final theme = Theme.of(context);

    if (toothNumber == null) {
      return _DentalChartMessage(l.selectToothReview);
    }

    final suggestions = _suggestedProcedures(
      conditions: conditions,
      procedures: procedures,
    );

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    Icons.medical_services_outlined,
                    color: theme.colorScheme.onPrimaryContainer,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l.toothNumberValue(toothNumber!),
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        conditions.isEmpty
                            ? l.healthyToothMessage(toothNumber!)
                            : '${conditions.length} ${l.conditionLabel.toLowerCase()}',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: conditions.isEmpty
                              ? Colors.green.shade700
                              : theme.colorScheme.error,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                FilledButton.tonalIcon(
                  onPressed: () => onSchedule(),
                  icon: const Icon(Icons.calendar_month, size: 18),
                  label: Text(l.scheduleAppointmentForTooth),
                  style: FilledButton.styleFrom(
                    visualDensity: VisualDensity.compact,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Divider(height: 1),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  l.conditionLabel,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.primary,
                  ),
                ),
                if (canEdit)
                  TextButton.icon(
                    onPressed: mutating ? null : onAddCondition,
                    icon: const Icon(Icons.add, size: 16),
                    label: Text(l.addConditionTitle(toothNumber!)),
                    style: TextButton.styleFrom(
                      visualDensity: VisualDensity.compact,
                    ),
                  ),
              ],
            ),
            if (conditions.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Row(
                  children: [
                    Icon(
                      Icons.check_circle_outline,
                      size: 18,
                      color: Colors.green.shade600,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        l.healthyToothMessage(toothNumber!),
                        style: TextStyle(color: Colors.green.shade800),
                      ),
                    ),
                  ],
                ),
              )
            else
              for (final condition in conditions)
                _ConditionTile(
                  condition: condition,
                  canEdit: canEdit,
                  enabled: !mutating,
                  onResolve: () => onResolve(condition),
                  onMarkInError: () => onMarkInError(condition),
                ),
            const SizedBox(height: 16),
            const Divider(height: 1),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  l.toothTreatmentsTitle(toothNumber!),
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.primary,
                  ),
                ),
                if (canEdit)
                  TextButton.icon(
                    onPressed: mutating ? null : onSelectProcedureFromCatalogue,
                    icon: const Icon(Icons.playlist_add, size: 16),
                    label: Text(l.addTreatmentForTooth),
                    style: TextButton.styleFrom(
                      visualDensity: VisualDensity.compact,
                    ),
                  ),
              ],
            ),
            if (treatmentItems.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Text(
                  l.noTreatmentsPlannedForTooth,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              )
            else
              for (final item in treatmentItems) ...[
                _ToothTreatmentItemTile(
                  item: item,
                  currencyCode: currencyCode,
                  procedure: procedures
                      .where((p) => p.id == item.procedureId)
                      .firstOrNull,
                  onSchedule: (name, duration) => onSchedule(
                    procedureName: name,
                    durationMinutes: duration,
                  ),
                ),
                const SizedBox(height: 6),
              ],
            if (suggestions.isNotEmpty && canEdit) ...[
              const SizedBox(height: 12),
              Text(
                l.suggestedTreatmentsTitle,
                style: theme.textTheme.labelMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final proc in suggestions)
                    ActionChip(
                      avatar: const Icon(Icons.add, size: 14),
                      label: Text(
                        '${proc.name} · ${proc.defaultPrice.toDecimalString()} $currencyCode',
                      ),
                      onPressed: mutating ? null : () => onAddTreatment(proc),
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

class _ToothTreatmentItemTile extends StatelessWidget {
  const _ToothTreatmentItemTile({
    required this.item,
    required this.currencyCode,
    required this.procedure,
    required this.onSchedule,
  });

  final TreatmentPlanItem item;
  final String currencyCode;
  final ClinicProcedure? procedure;
  final void Function(String name, int? duration) onSchedule;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final name = procedure?.name ?? item.description ?? l.procedureLabel;
    final duration = procedure?.durationMinutes;

    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: theme.colorScheme.outlineVariant.withValues(alpha: 0.6),
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.medical_information_outlined,
            size: 20,
            color: theme.colorScheme.primary,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                Text(
                  '${item.status.label} · ${item.estimatedPrice.toDecimalString()} $currencyCode',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          OutlinedButton.icon(
            onPressed: () => onSchedule(name, duration),
            icon: const Icon(Icons.event, size: 16),
            label: Text(l.scheduleThisProcedure),
            style: OutlinedButton.styleFrom(
              visualDensity: VisualDensity.compact,
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            ),
          ),
        ],
      ),
    );
  }
}

class _ConditionTile extends StatelessWidget {
  const _ConditionTile({
    required this.condition,
    required this.canEdit,
    required this.enabled,
    this.onResolve,
    this.onMarkInError,
  });
  final ToothCondition condition;
  final bool canEdit;
  final bool enabled;
  final VoidCallback? onResolve;
  final VoidCallback? onMarkInError;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Icon(
        Icons.circle,
        color: _conditionColor(condition.type, Theme.of(context).colorScheme),
      ),
      title: Text(
        '${_conditionLabel(condition.type, l)} · ${_surfaceLabel(condition.surface, l)}',
      ),
      subtitle: condition.notes == null || condition.notes!.isEmpty
          ? null
          : Text(condition.notes!),
      trailing: canEdit
          ? PopupMenuButton<String>(
              enabled: enabled,
              onSelected: (action) {
                if (action == 'resolve') onResolve?.call();
                if (action == 'error') onMarkInError?.call();
              },
              itemBuilder: (_) => [
                PopupMenuItem(value: 'resolve', child: Text(l.resolveLabel)),
                PopupMenuItem(value: 'error', child: Text(l.markAsErrorLabel)),
              ],
            )
          : null,
    );
  }
}

class _HistorySection extends StatelessWidget {
  const _HistorySection({
    required this.history,
    required this.hasMore,
    required this.loadingMore,
    required this.onLoadMore,
  });
  final List<ToothCondition> history;
  final bool hasMore;
  final bool loadingMore;
  final VoidCallback onLoadMore;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return Card(
      child: ExpansionTile(
        title: Text(l.conditionHistoryTitle),
        subtitle: Text(l.recordedItemsValue(history.length)),
        children: [
          if (history.isEmpty)
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(l.noDentalHistory),
            ),
          for (final condition in history)
            ListTile(
              leading: Icon(
                condition.status == ToothConditionStatus.active
                    ? Icons.circle
                    : condition.status == ToothConditionStatus.resolved
                    ? Icons.check_circle_outline
                    : Icons.error_outline,
                color: _conditionColor(
                  condition.type,
                  Theme.of(context).colorScheme,
                ),
              ),
              title: Text(
                '${l.toothNumberValue(condition.toothNumber)} · ${_conditionLabel(condition.type, l)}',
              ),
              subtitle: Text(_historyDescription(condition, l)),
            ),
          if (hasMore)
            Padding(
              padding: const EdgeInsets.all(12),
              child: OutlinedButton(
                onPressed: loadingMore ? null : onLoadMore,
                child: loadingMore
                    ? const SizedBox(
                        height: 18,
                        width: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Text(l.loadMoreHistoryLabel),
              ),
            ),
        ],
      ),
    );
  }
}

class _DentalChartUnavailable extends StatelessWidget {
  const _DentalChartUnavailable();

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(l.dentalChartTitle)),
      body: _DentalChartMessage(l.dentalRoleRestricted),
    );
  }
}

class _DentalChartMessage extends StatelessWidget {
  const _DentalChartMessage(this.message);
  final String message;

  @override
  Widget build(BuildContext context) =>
      Padding(padding: const EdgeInsets.all(16), child: Text(message));
}

Color _conditionColor(ToothConditionType? type, ColorScheme colors) =>
    switch (type) {
      ToothConditionType.caries => colors.error,
      ToothConditionType.filling => Colors.blue,
      ToothConditionType.crown => Colors.amber.shade800,
      ToothConditionType.rootCanal => Colors.deepPurple,
      ToothConditionType.fracture => Colors.orange.shade800,
      ToothConditionType.missing => Colors.grey,
      ToothConditionType.extractionRequired => Colors.red.shade900,
      ToothConditionType.implant => Colors.teal,
      null => colors.outline,
    };

String _historyDescription(ToothCondition condition, AppLocalizations l) {
  final date = DateFormat.yMMMd().format(condition.createdAt.toLocal());
  final status = _conditionStatusLabel(condition.status, l);
  final reason = condition.errorReason;
  return '${_surfaceLabel(condition.surface, l)} · $status · $date${reason == null ? '' : ' · $reason'}';
}

String _surfaceLabel(ToothSurface surface, AppLocalizations l) =>
    switch (surface) {
      ToothSurface.whole => l.surfaceWhole,
      ToothSurface.mesial => l.surfaceMesial,
      ToothSurface.distal => l.surfaceDistal,
      ToothSurface.occlusal => l.surfaceOcclusal,
      ToothSurface.buccal => l.surfaceBuccal,
      ToothSurface.lingual => l.surfaceLingual,
    };

String _conditionLabel(ToothConditionType type, AppLocalizations l) =>
    switch (type) {
      ToothConditionType.caries => l.conditionCaries,
      ToothConditionType.filling => l.conditionFilling,
      ToothConditionType.crown => l.conditionCrown,
      ToothConditionType.rootCanal => l.conditionRootCanal,
      ToothConditionType.fracture => l.conditionFracture,
      ToothConditionType.missing => l.conditionMissing,
      ToothConditionType.extractionRequired => l.conditionExtraction,
      ToothConditionType.implant => l.conditionImplant,
    };

String _conditionStatusLabel(ToothConditionStatus status, AppLocalizations l) =>
    switch (status) {
      ToothConditionStatus.active => l.conditionStatusActive,
      ToothConditionStatus.resolved => l.conditionStatusResolved,
      ToothConditionStatus.enteredInError => l.conditionStatusError,
    };

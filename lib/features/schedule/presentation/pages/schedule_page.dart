import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/localization/generated/app_localizations.dart';
import '../../../../app/theme/app_theme.dart';
import '../../../../core/error/failure_message.dart';
import '../../../../core/widgets/app_dialog.dart';
import '../../../clinic/presentation/clinic_cubit.dart';
import '../../domain/schedule_models.dart';
import '../../domain/schedule_validation.dart';
import '../schedule_cubit.dart';

class DoctorSchedulePage extends StatefulWidget {
  const DoctorSchedulePage({super.key});

  @override
  State<DoctorSchedulePage> createState() => _DoctorSchedulePageState();
}

class _DoctorSchedulePageState extends State<DoctorSchedulePage> {
  String? _loadedClinicId;
  String? _selectedDentistId;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final membership = context.watch<ClinicCubit>().state.activeMembership;
    if (membership == null) {
      return _ScheduleMessage(l.scheduleChooseClinic);
    }
    if (_loadedClinicId != membership.clinic.id) {
      _loadedClinicId = membership.clinic.id;
      WidgetsBinding.instance.addPostFrameCallback(
        (_) => context.read<ScheduleCubit>().load(membership.clinic.id),
      );
    }
    final canManage =
        membership.isOwner || membership.roles.contains('dentist');
    return Scaffold(
      appBar: AppBar(
        title: Text(l.doctorScheduleTitle),
        leading: IconButton(
          tooltip: l.backLabel,
          onPressed: () => context.go('/dashboard'),
          icon: const Icon(Icons.arrow_back),
        ),
      ),
      body: BlocBuilder<ScheduleCubit, ScheduleState>(
        builder: (context, state) {
          final dentists = state.dentists;
          final selfId = membership.memberId;
          final selectedId =
              _selectedDentistId ??
              (membership.roles.contains('dentist')
                  ? selfId
                  : dentists.firstOrNull?.memberId);
          if (_selectedDentistId == null && selectedId != null) {
            _selectedDentistId = selectedId;
          }
          final selectedVersions = state.versions
              .where((version) => version.dentistMemberId == selectedId)
              .toList(growable: false);
          final selectedExceptions = state.exceptions
              .where((exception) => exception.dentistMemberId == selectedId)
              .toList(growable: false);
          final selectedDentist = dentists
              .where((dentist) => dentist.memberId == selectedId)
              .firstOrNull;
          final today = _localDate(DateTime.now());
          final orderedVersions = [...selectedVersions]
            ..sort((a, b) => a.effectiveFrom.compareTo(b.effectiveFrom));
          DoctorScheduleVersion? activeVersion;
          DoctorScheduleVersion? upcomingVersion;
          for (final version in orderedVersions) {
            if (version.effectiveFrom.compareTo(today) <= 0) {
              activeVersion = version;
            } else {
              upcomingVersion ??= version;
            }
          }
          final visibleIds = {
            if (activeVersion != null) activeVersion.id,
            if (upcomingVersion != null) upcomingVersion.id,
          };
          final history = orderedVersions
              .where((version) => !visibleIds.contains(version.id))
              .toList(growable: false)
              .reversed
              .toList(growable: false);
          return Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(
                maxWidth: AppSpacing.wideContentWidth,
              ),
              child: RefreshIndicator(
                onRefresh: () =>
                    context.read<ScheduleCubit>().load(membership.clinic.id),
                child: ListView(
                  padding: AppInsets.page(AppBreakpoints.of(context)),
                  children: [
                    if (state.status == ScheduleStatus.loading)
                      const LinearProgressIndicator(),
                    if (state.status == ScheduleStatus.loading)
                      const SizedBox(height: AppSpacing.medium),
                    if (state.failure != null)
                      _ScheduleMessage(
                        failureMessage(
                          state.failure!,
                          AppLocalizations.of(context),
                        ),
                      ),
                    if (state.issue != null)
                      _ScheduleMessage(_issueText(state.issue!, l)),
                    _DoctorScheduleHeader(
                      clinicName: membership.clinic.name,
                      timeZone: membership.clinic.timeZone,
                      selectedDentist: selectedDentist,
                      dentists: dentists,
                      selectedId: selectedId,
                      onDentistChanged: (value) =>
                          setState(() => _selectedDentistId = value),
                    ),
                    const SizedBox(height: AppSpacing.medium),
                    if (canManage && selectedId != null)
                      _ScheduleActions(
                        mutating: state.mutating,
                        onEdit: () =>
                            _editWeekly(context, selectedId, selectedVersions),
                        onAddException: () =>
                            _addException(context, selectedId),
                      ),
                    const SizedBox(height: AppSpacing.large),
                    if (activeVersion == null && upcomingVersion == null)
                      _SectionCard(
                        title: l.weeklyHoursTitle,
                        child: Text(l.noWeeklyHours),
                      ),
                    if (activeVersion != null)
                      _ScheduleVersionCard(
                        version: activeVersion,
                        label: l.scheduleActiveLabel,
                        icon: Icons.check_circle_outline,
                      ),
                    if (activeVersion != null && upcomingVersion != null)
                      const SizedBox(height: AppSpacing.medium),
                    if (upcomingVersion != null)
                      _ScheduleVersionCard(
                        version: upcomingVersion,
                        label: l.scheduleUpcomingLabel,
                        icon: Icons.update_outlined,
                        highlighted: true,
                      ),
                    if (history.isNotEmpty) ...[
                      const SizedBox(height: AppSpacing.medium),
                      _ScheduleHistoryCard(versions: history),
                    ],
                    const SizedBox(height: AppSpacing.medium),
                    _SectionCard(
                      title: l.unavailablePeriodsTitle,
                      child: selectedExceptions.isEmpty
                          ? Text(l.noUnavailablePeriods)
                          : Column(
                              children: [
                                for (final exception in selectedExceptions)
                                  _ExceptionCard(
                                    exception: exception,
                                    onDelete: canManage && selectedId != null
                                        ? () => context
                                              .read<ScheduleCubit>()
                                              .deleteException(exception.id)
                                        : null,
                                  ),
                              ],
                            ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Future<void> _editWeekly(
    BuildContext context,
    String dentistMemberId,
    List<DoctorScheduleVersion> versions,
  ) async {
    final l = AppLocalizations.of(context);
    final existing = versions.isEmpty
        ? const <DoctorWorkingPeriod>[]
        : versions.first.workingPeriods;
    final result = await showSettledDialog<_WeeklyScheduleInput>(
      context: context,
      builder: (_) => _WeeklyScheduleDialog(existing: existing),
    );
    if (result == null || !context.mounted) return;
    final membership = context.read<ClinicCubit>().state.activeMembership;
    final preview = await context.read<ScheduleCubit>().previewWeeklyImpact(
      dentistMemberId: dentistMemberId,
      effectiveFrom: result.effectiveFrom,
      periods: result.periods,
    );
    if (!context.mounted) return;
    String? impactReason;
    if (preview != null && preview.count > 0) {
      if (membership?.isOwner != true) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l.scheduleConflictOwnerReview(preview.count))),
        );
        return;
      }
      impactReason = await showSettledDialog<String>(
        context: context,
        builder: (_) => _ScheduleImpactDialog(count: preview.count),
      );
      if (impactReason == null || !context.mounted) return;
    }
    final saved = await context.read<ScheduleCubit>().replaceWeeklySchedule(
      dentistMemberId: dentistMemberId,
      effectiveFrom: result.effectiveFrom,
      periods: result.periods,
      confirmAffectedAppointments: impactReason != null,
      appointmentImpactReason: impactReason,
    );
    if (saved && context.mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(l.scheduleSavedMessage)));
    }
  }

  Future<void> _addException(
    BuildContext context,
    String dentistMemberId,
  ) async {
    final l = AppLocalizations.of(context);
    final input = await showSettledDialog<_ExceptionInput>(
      context: context,
      builder: (_) => const _ExceptionDialog(),
    );
    if (input == null || !context.mounted) return;
    final membership = context.read<ClinicCubit>().state.activeMembership;
    final preview = await context.read<ScheduleCubit>().previewExceptionImpact(
      dentistMemberId: dentistMemberId,
      startsAt: input.startsAt,
      endsAt: input.endsAt,
    );
    if (!context.mounted) return;
    String? impactReason;
    if (preview != null && preview.count > 0) {
      if (membership?.isOwner != true) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l.scheduleConflictOwnerReview(preview.count))),
        );
        return;
      }
      impactReason = await showSettledDialog<String>(
        context: context,
        builder: (_) => _ScheduleImpactDialog(count: preview.count),
      );
      if (impactReason == null || !context.mounted) return;
    }
    await context.read<ScheduleCubit>().createException(
      dentistMemberId: dentistMemberId,
      kind: input.kind,
      startsAt: input.startsAt,
      endsAt: input.endsAt,
      reason: input.reason,
      confirmAffectedAppointments: impactReason != null,
      appointmentImpactReason: impactReason,
    );
  }
}

class _WeeklyScheduleDialog extends StatefulWidget {
  const _WeeklyScheduleDialog({required this.existing});
  final List<DoctorWorkingPeriod> existing;

  @override
  State<_WeeklyScheduleDialog> createState() => _WeeklyScheduleDialogState();
}

class _WeeklyScheduleDialogState extends State<_WeeklyScheduleDialog> {
  late Set<int> _days;
  late TimeOfDay _start;
  late TimeOfDay _end;
  late TimeOfDay _breakStart;
  late TimeOfDay _breakEnd;
  late DateTime _effectiveFrom;
  late bool _includeBreak;
  String? _inputError;

  @override
  void initState() {
    super.initState();
    final first = widget.existing.firstOrNull;
    final weekdays =
        widget.existing.map((period) => period.weekday).toSet().toList()
          ..sort();
    _days = weekdays.isEmpty ? {1, 2, 3, 4, 5} : weekdays.toSet();
    _start = _parseTime(first?.startsAt ?? '09:00');
    _end = _parseTime(first?.endsAt ?? '17:00');
    final existingBreak = first?.breaks.firstOrNull;
    _includeBreak = existingBreak != null || first == null;
    _breakStart = _parseTime(existingBreak?.startsAt ?? '13:00');
    _breakEnd = _parseTime(existingBreak?.endsAt ?? '14:00');
    _effectiveFrom = DateTime.now().add(const Duration(days: 1));
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return AlertDialog(
      scrollable: true,
      title: Text(l.editWeeklyHoursLabel),
      content: DialogBody(
        child: DialogFormColumn(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l.selectWorkingDaysHelp,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            Wrap(
              spacing: AppSpacing.small,
              runSpacing: AppSpacing.small,
              children: [
                for (var day = 1; day <= 7; day++)
                  FilterChip(
                    label: Text(_weekday(day, l)),
                    selected: _days.contains(day),
                    onSelected: (selected) => setState(() {
                      selected ? _days.add(day) : _days.remove(day);
                      _inputError = null;
                    }),
                  ),
              ],
            ),
            _ResponsivePickerPair(
              first: _SchedulePickerTile(
                icon: Icons.login,
                label: l.startsLabel,
                value: MaterialLocalizations.of(
                  context,
                ).formatTimeOfDay(_start),
                onTap: () => _pickTime(_start, (value) => _start = value),
              ),
              second: _SchedulePickerTile(
                icon: Icons.logout,
                label: l.endsLabel,
                value: MaterialLocalizations.of(context).formatTimeOfDay(_end),
                onTap: () => _pickTime(_end, (value) => _end = value),
              ),
            ),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              value: _includeBreak,
              title: Text(l.includeBreakLabel),
              secondary: const Icon(Icons.free_breakfast_outlined),
              onChanged: (value) => setState(() {
                _includeBreak = value;
                _inputError = null;
              }),
            ),
            if (_includeBreak)
              _ResponsivePickerPair(
                first: _SchedulePickerTile(
                  icon: Icons.pause_circle_outline,
                  label: l.breakStartOptional,
                  value: MaterialLocalizations.of(
                    context,
                  ).formatTimeOfDay(_breakStart),
                  onTap: () =>
                      _pickTime(_breakStart, (value) => _breakStart = value),
                ),
                second: _SchedulePickerTile(
                  icon: Icons.play_circle_outline,
                  label: l.breakEndOptional,
                  value: MaterialLocalizations.of(
                    context,
                  ).formatTimeOfDay(_breakEnd),
                  onTap: () =>
                      _pickTime(_breakEnd, (value) => _breakEnd = value),
                ),
              ),
            _SchedulePickerTile(
              icon: Icons.event_outlined,
              label: l.effectiveDateLabel,
              value: _localDate(_effectiveFrom),
              onTap: _pickEffectiveDate,
            ),
            _ScheduleSummary(
              days: _days,
              start: _start,
              end: _end,
              includeBreak: _includeBreak,
              breakStart: _breakStart,
              breakEnd: _breakEnd,
            ),
            if (_inputError != null)
              Text(
                _inputError!,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(l.cancelLabel),
        ),
        FilledButton(onPressed: _submit, child: Text(l.saveLabel)),
      ],
    );
  }

  Future<void> _pickTime(
    TimeOfDay initial,
    void Function(TimeOfDay value) update,
  ) async {
    final value = await showTimePicker(context: context, initialTime: initial);
    if (value == null || !mounted) return;
    setState(() {
      update(value);
      _inputError = null;
    });
  }

  Future<void> _pickEffectiveDate() async {
    final tomorrow = DateTime.now().add(const Duration(days: 1));
    final firstDate = DateTime(tomorrow.year, tomorrow.month, tomorrow.day);
    final value = await showDatePicker(
      context: context,
      firstDate: firstDate,
      lastDate: DateTime.now().add(const Duration(days: 3650)),
      initialDate: _effectiveFrom.isBefore(firstDate)
          ? firstDate
          : _effectiveFrom,
    );
    if (value == null || !mounted) return;
    setState(() {
      _effectiveFrom = value;
      _inputError = null;
    });
  }

  void _submit() {
    final l = AppLocalizations.of(context);
    if (_days.isEmpty) {
      setState(() => _inputError = l.scheduleInvalidInputMessage);
      return;
    }
    final weekdays = _days.toList()..sort();
    final periods = weekdays
        .map(
          (day) => DoctorWorkingPeriod(
            id: 'new',
            weekday: day,
            startsAt: _apiTime(_start),
            endsAt: _apiTime(_end),
            breaks: _includeBreak
                ? [
                    DoctorScheduleBreak(
                      id: 'new',
                      startsAt: _apiTime(_breakStart),
                      endsAt: _apiTime(_breakEnd),
                    ),
                  ]
                : const [],
          ),
        )
        .toList(growable: false);
    try {
      final effectiveFrom = ScheduleValidation.localDate(
        _localDate(_effectiveFrom),
      );
      ScheduleValidation.periods(periods);
      Navigator.pop(context, _WeeklyScheduleInput(effectiveFrom, periods));
    } on Object {
      setState(() => _inputError = l.scheduleInvalidInputMessage);
    }
  }
}

class _ExceptionDialog extends StatefulWidget {
  const _ExceptionDialog();
  @override
  State<_ExceptionDialog> createState() => _ExceptionDialogState();
}

class _ExceptionDialogState extends State<_ExceptionDialog> {
  ScheduleExceptionKind _kind = ScheduleExceptionKind.leave;
  late DateTime _startsAt = DateTime.now().add(const Duration(days: 1));
  late DateTime _endsAt = DateTime.now().add(const Duration(days: 2));
  final _reason = TextEditingController();

  @override
  void dispose() {
    _reason.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return AlertDialog(
      scrollable: true,
      title: Text(l.addUnavailableTimeTitle),
      content: DialogBody(
        child: DialogFormColumn(
          children: [
            DropdownButtonFormField(
              isExpanded: true,
              initialValue: _kind,
              decoration: InputDecoration(labelText: l.typeLabel),
              items: ScheduleExceptionKind.values
                  .map(
                    (kind) => DropdownMenuItem(
                      value: kind,
                      child: Text(
                        kind == ScheduleExceptionKind.leave
                            ? l.leaveLabel
                            : l.unavailableLabel,
                      ),
                    ),
                  )
                  .toList(),
              onChanged: (value) => setState(() => _kind = value!),
            ),
            ListTile(
              title: Text(l.startsLabel),
              subtitle: Text(_displayDateTime(_startsAt)),
              onTap: () => _pick(true),
            ),
            ListTile(
              title: Text(l.endsLabel),
              subtitle: Text(_displayDateTime(_endsAt)),
              onTap: () => _pick(false),
            ),
            TextField(
              controller: _reason,
              decoration: InputDecoration(labelText: l.reasonOptionalLabel),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(l.cancelLabel),
        ),
        FilledButton(
          onPressed: _endsAt.isAfter(_startsAt)
              ? () => Navigator.pop(
                  context,
                  _ExceptionInput(_kind, _startsAt, _endsAt, _reason.text),
                )
              : null,
          child: Text(l.saveLabel),
        ),
      ],
    );
  }

  Future<void> _pick(bool start) async {
    final current = start ? _startsAt : _endsAt;
    final date = await showDatePicker(
      context: context,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 3650)),
      initialDate: current,
    );
    if (date == null || !mounted) return;
    final clock = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(current),
    );
    if (clock == null || !mounted) return;
    final next = DateTime(
      date.year,
      date.month,
      date.day,
      clock.hour,
      clock.minute,
    );
    setState(() {
      if (start) {
        _startsAt = next;
      } else {
        _endsAt = next;
      }
    });
  }
}

class _DoctorScheduleHeader extends StatelessWidget {
  const _DoctorScheduleHeader({
    required this.clinicName,
    required this.timeZone,
    required this.selectedDentist,
    required this.dentists,
    required this.selectedId,
    required this.onDentistChanged,
  });

  final String clinicName;
  final String timeZone;
  final ScheduleDentist? selectedDentist;
  final List<ScheduleDentist> dentists;
  final String? selectedId;
  final ValueChanged<String?> onDentistChanged;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.large),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 26,
                  backgroundColor: scheme.primaryContainer,
                  foregroundColor: scheme.onPrimaryContainer,
                  child: const Icon(Icons.medical_services_outlined),
                ),
                const SizedBox(width: AppSpacing.medium),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l.scheduleForLabel,
                        style: Theme.of(
                          context,
                        ).textTheme.labelLarge?.copyWith(color: scheme.primary),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        selectedDentist?.displayName ?? l.noActiveDentist,
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 4),
                      Wrap(
                        spacing: AppSpacing.small,
                        runSpacing: 4,
                        children: [
                          _InfoBadge(
                            icon: Icons.local_hospital_outlined,
                            label: clinicName,
                          ),
                          _InfoBadge(icon: Icons.public, label: timeZone),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            if (dentists.length > 1) ...[
              const SizedBox(height: AppSpacing.large),
              DropdownButtonFormField<String>(
                isExpanded: true,
                initialValue: selectedId,
                decoration: InputDecoration(labelText: l.dentistLabel),
                items: dentists
                    .map(
                      (dentist) => DropdownMenuItem(
                        value: dentist.memberId,
                        child: Text(dentist.displayName),
                      ),
                    )
                    .toList(growable: false),
                onChanged: onDentistChanged,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _ScheduleActions extends StatelessWidget {
  const _ScheduleActions({
    required this.mutating,
    required this.onEdit,
    required this.onAddException,
  });

  final bool mutating;
  final VoidCallback onEdit;
  final VoidCallback onAddException;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final buttons = [
      FilledButton.icon(
        onPressed: mutating ? null : onEdit,
        icon: const Icon(Icons.edit_calendar_outlined),
        label: Text(
          l.editWeeklyHoursLabel,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          textAlign: TextAlign.center,
        ),
      ),
      OutlinedButton.icon(
        onPressed: mutating ? null : onAddException,
        icon: const Icon(Icons.event_busy),
        label: Text(
          l.addUnavailableTimeLabel,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          textAlign: TextAlign.center,
        ),
      ),
    ];
    if (AppBreakpoints.of(context) == AppLayoutClass.mobile) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          buttons.first,
          const SizedBox(height: AppSpacing.small),
          buttons.last,
        ],
      );
    }
    return Wrap(
      spacing: AppSpacing.medium,
      runSpacing: AppSpacing.small,
      children: buttons,
    );
  }
}

class _InfoBadge extends StatelessWidget {
  const _InfoBadge({required this.icon, required this.label});
  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) => Chip(
    avatar: Icon(icon, size: 16),
    label: Text(label),
    visualDensity: VisualDensity.compact,
  );
}

class _ScheduleVersionCard extends StatelessWidget {
  const _ScheduleVersionCard({
    required this.version,
    required this.label,
    required this.icon,
    this.highlighted = false,
  });

  final DoctorScheduleVersion version;
  final String label;
  final IconData icon;
  final bool highlighted;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;
    final periods = {
      for (final period in version.workingPeriods) period.weekday: period,
    };
    return Card(
      color: highlighted
          ? scheme.primaryContainer.withValues(alpha: 0.45)
          : null,
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.large),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            LayoutBuilder(
              builder: (context, constraints) {
                final title = Row(
                  children: [
                    Icon(icon, color: scheme.primary),
                    const SizedBox(width: AppSpacing.small),
                    Expanded(
                      child: Text(
                        label,
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                    ),
                  ],
                );
                final date = Chip(label: Text(version.effectiveFrom));

                if (constraints.maxWidth < 420) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      title,
                      const SizedBox(height: AppSpacing.small),
                      Align(
                        alignment: AlignmentDirectional.centerStart,
                        child: date,
                      ),
                    ],
                  );
                }

                return Row(
                  children: [
                    Expanded(child: title),
                    const SizedBox(width: AppSpacing.medium),
                    date,
                  ],
                );
              },
            ),
            const SizedBox(height: AppSpacing.medium),
            const Divider(height: 1),
            const SizedBox(height: AppSpacing.small),
            for (var day = 1; day <= 7; day++)
              _DayScheduleRow(day: day, period: periods[day], l: l),
          ],
        ),
      ),
    );
  }
}

class _DayScheduleRow extends StatelessWidget {
  const _DayScheduleRow({
    required this.day,
    required this.period,
    required this.l,
  });
  final int day;
  final DoctorWorkingPeriod? period;
  final AppLocalizations l;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final pause = period?.breaks.firstOrNull;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 7),
      child: Row(
        children: [
          SizedBox(
            width: 72,
            child: Text(
              _weekday(day, l),
              style: Theme.of(context).textTheme.labelLarge,
            ),
          ),
          Expanded(
            child: period == null
                ? Text(
                    l.closedLabel,
                    style: TextStyle(color: scheme.onSurfaceVariant),
                  )
                : Wrap(
                    spacing: AppSpacing.medium,
                    runSpacing: 4,
                    children: [
                      Text('${period!.startsAt} – ${period!.endsAt}'),
                      if (pause != null)
                        Text(
                          '${l.breakLabel} ${pause.startsAt} – ${pause.endsAt}',
                          style: TextStyle(color: scheme.onSurfaceVariant),
                        ),
                    ],
                  ),
          ),
        ],
      ),
    );
  }
}

class _ScheduleHistoryCard extends StatelessWidget {
  const _ScheduleHistoryCard({required this.versions});
  final List<DoctorScheduleVersion> versions;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return Card(
      child: ExpansionTile(
        leading: const Icon(Icons.history),
        title: Text(l.scheduleHistoryLabel),
        subtitle: Text(l.scheduleHistoryHelp),
        childrenPadding: const EdgeInsets.fromLTRB(
          AppSpacing.large,
          0,
          AppSpacing.large,
          AppSpacing.medium,
        ),
        children: [
          for (final version in versions) _VersionTile(version: version, l: l),
        ],
      ),
    );
  }
}

class _ExceptionCard extends StatelessWidget {
  const _ExceptionCard({required this.exception, this.onDelete});
  final DoctorScheduleException exception;
  final VoidCallback? onDelete;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final isLeave = exception.kind == ScheduleExceptionKind.leave;
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.small),
      child: ListTile(
        tileColor: Theme.of(context).colorScheme.surfaceContainerLowest,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radius),
        ),
        leading: Icon(isLeave ? Icons.beach_access_outlined : Icons.event_busy),
        title: Text(isLeave ? l.leaveLabel : l.unavailableLabel),
        subtitle: Text(
          '${_displayDateTime(exception.startsAt)} – ${_displayDateTime(exception.endsAt)}'
          '${exception.reason == null ? '' : '\n${exception.reason}'}',
        ),
        trailing: onDelete == null
            ? null
            : IconButton(
                tooltip: l.removeLabel,
                onPressed: onDelete,
                icon: const Icon(Icons.delete_outline),
              ),
      ),
    );
  }
}

class _ResponsivePickerPair extends StatelessWidget {
  const _ResponsivePickerPair({required this.first, required this.second});
  final Widget first;
  final Widget second;

  @override
  Widget build(BuildContext context) {
    if (MediaQuery.sizeOf(context).width < 600) {
      return Column(
        children: [
          first,
          const SizedBox(height: AppSpacing.small),
          second,
        ],
      );
    }
    return Row(
      children: [
        Expanded(child: first),
        const SizedBox(width: AppSpacing.small),
        Expanded(child: second),
      ],
    );
  }
}

class _SchedulePickerTile extends StatelessWidget {
  const _SchedulePickerTile({
    required this.icon,
    required this.label,
    required this.value,
    required this.onTap,
  });
  final IconData icon;
  final String label;
  final String value;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Material(
    color: Theme.of(context).colorScheme.surfaceContainerLowest,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(AppSpacing.radius),
      side: BorderSide(color: Theme.of(context).colorScheme.outlineVariant),
    ),
    child: ListTile(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppSpacing.radius),
      ),
      leading: Icon(icon),
      title: Text(label),
      subtitle: Text(value),
      trailing: const Icon(Icons.expand_more),
      onTap: onTap,
    ),
  );
}

class _ScheduleSummary extends StatelessWidget {
  const _ScheduleSummary({
    required this.days,
    required this.start,
    required this.end,
    required this.includeBreak,
    required this.breakStart,
    required this.breakEnd,
  });
  final Set<int> days;
  final TimeOfDay start;
  final TimeOfDay end;
  final bool includeBreak;
  final TimeOfDay breakStart;
  final TimeOfDay breakEnd;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final orderedDays = days.toList()..sort();
    final localizations = MaterialLocalizations.of(context);
    return Container(
      padding: const EdgeInsets.all(AppSpacing.medium),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(AppSpacing.radius),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.summarize_outlined),
          const SizedBox(width: AppSpacing.small),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l.scheduleSummaryLabel,
                  style: Theme.of(context).textTheme.labelLarge,
                ),
                const SizedBox(height: 4),
                Text(orderedDays.map((day) => _weekday(day, l)).join(', ')),
                Text(
                  '${localizations.formatTimeOfDay(start)} – ${localizations.formatTimeOfDay(end)}'
                  '${includeBreak ? ' · ${l.breakLabel} ${localizations.formatTimeOfDay(breakStart)} – ${localizations.formatTimeOfDay(breakEnd)}' : ''}',
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({required this.title, required this.child});
  final String title;
  final Widget child;
  @override
  Widget build(BuildContext context) => Card(
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 12),
          child,
        ],
      ),
    ),
  );
}

class _VersionTile extends StatelessWidget {
  const _VersionTile({required this.version, required this.l});
  final DoctorScheduleVersion version;
  final AppLocalizations l;
  @override
  Widget build(BuildContext context) => ListTile(
    contentPadding: EdgeInsets.zero,
    title: Text(l.effectiveFromValue(version.effectiveFrom)),
    subtitle: Text(
      version.workingPeriods.isEmpty
          ? l.noWorkingHours
          : version.workingPeriods
                .map(
                  (p) =>
                      '${_weekday(p.weekday, l)} ${p.startsAt}–${p.endsAt}${p.breaks.isEmpty ? '' : ' · ${l.breakLabel} ${p.breaks.map((b) => '${b.startsAt}–${b.endsAt}').join(', ')}'}',
                )
                .join('\n'),
    ),
  );
}

class _ScheduleMessage extends StatelessWidget {
  const _ScheduleMessage(this.message);
  final String message;
  @override
  Widget build(BuildContext context) => Card(
    child: Padding(padding: const EdgeInsets.all(16), child: Text(message)),
  );
}

class _WeeklyScheduleInput {
  const _WeeklyScheduleInput(this.effectiveFrom, this.periods);
  final String effectiveFrom;
  final List<DoctorWorkingPeriod> periods;
}

class _ExceptionInput {
  const _ExceptionInput(this.kind, this.startsAt, this.endsAt, this.reason);
  final ScheduleExceptionKind kind;
  final DateTime startsAt;
  final DateTime endsAt;
  final String reason;
}

class _ScheduleImpactDialog extends StatefulWidget {
  const _ScheduleImpactDialog({required this.count});
  final int count;
  @override
  State<_ScheduleImpactDialog> createState() => _ScheduleImpactDialogState();
}

class _ScheduleImpactDialogState extends State<_ScheduleImpactDialog> {
  final _reason = TextEditingController();
  @override
  void dispose() {
    _reason.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return AlertDialog(
      scrollable: true,
      title: Text(l.reviewAffectedAppointmentsTitle),
      content: DialogBody(
        child: DialogFormColumn(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(l.affectedAppointmentsExplanation(widget.count)),
            TextField(
              controller: _reason,
              maxLength: 1000,
              maxLines: 3,
              decoration: InputDecoration(
                labelText: l.ownerConfirmationReasonLabel,
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(l.cancelChangeLabel),
        ),
        FilledButton(
          onPressed: () {
            final value = _reason.text.trim();
            if (value.isNotEmpty) Navigator.pop(context, value);
          },
          child: Text(l.confirmAndFlagLabel),
        ),
      ],
    );
  }
}

TimeOfDay _parseTime(String value) {
  final parts = value.split(':');
  return TimeOfDay(hour: int.parse(parts[0]), minute: int.parse(parts[1]));
}

String _apiTime(TimeOfDay value) =>
    '${value.hour.toString().padLeft(2, '0')}:${value.minute.toString().padLeft(2, '0')}';

String _localDate(DateTime value) =>
    '${value.year.toString().padLeft(4, '0')}-${value.month.toString().padLeft(2, '0')}-${value.day.toString().padLeft(2, '0')}';

String _displayDateTime(DateTime value) =>
    value.toLocal().toString().substring(0, 16);
String _weekday(int value, AppLocalizations l) => [
  l.weekdayMon,
  l.weekdayTue,
  l.weekdayWed,
  l.weekdayThu,
  l.weekdayFri,
  l.weekdaySat,
  l.weekdaySun,
][value - 1];
String _issueText(
  ScheduleOperationIssue issue,
  AppLocalizations l,
) => switch (issue) {
  ScheduleOperationIssue.editForbidden => l.scheduleEditForbiddenIssue,
  ScheduleOperationIssue.activeDentistRequired => l.activeDentistRequiredIssue,
  ScheduleOperationIssue.effectiveDateInvalid => l.effectiveDateInvalidIssue,
  ScheduleOperationIssue.exceptionUnavailable => l.exceptionUnavailableIssue,
  ScheduleOperationIssue.affectedAppointments => l.affectedAppointmentsIssue,
  ScheduleOperationIssue.invalidInput => l.staffInvalidInputIssue,
};

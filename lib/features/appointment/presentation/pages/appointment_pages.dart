import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:timezone/data/latest.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

import '../../../../core/error/app_failure.dart';
import '../../../../core/error/failure_message.dart';
import '../../../../core/widgets/app_dialog.dart';
import '../../../../app/localization/generated/app_localizations.dart';
import '../../../../app/theme/app_theme.dart';
import '../../../../core/utils/communication_launcher.dart';
import '../../../clinic/presentation/clinic_cubit.dart';
import '../../../patient/domain/patient_models.dart';
import '../../../patient/presentation/patient_cubit.dart';
import '../../../schedule/domain/schedule_models.dart';
import '../../../schedule/presentation/schedule_cubit.dart';
import '../../domain/appointment_models.dart';
import '../appointment_cubit.dart';

class AppointmentCalendarPage extends StatefulWidget {
  const AppointmentCalendarPage({super.key});
  @override
  State<AppointmentCalendarPage> createState() =>
      _AppointmentCalendarPageState();
}

class _AppointmentCalendarPageState extends State<AppointmentCalendarPage> {
  String? _loadedRange;
  DateTime _anchor = DateTime.now();

  @override
  void initState() {
    super.initState();
    tz_data.initializeTimeZones();
  }

  @override
  Widget build(BuildContext context) {
    final clinicState = context.watch<ClinicCubit>().state;
    final clinic = clinicState.activeClinic;
    if (clinic == null) {
      return _AppointmentMessage(
        AppLocalizations.of(context).chooseClinicFirst,
      );
    }
    final location = tz.getLocation(clinic.timeZone);
    final anchor = tz.TZDateTime(
      location,
      _anchor.year,
      _anchor.month,
      _anchor.day,
    );
    final mobile = AppBreakpoints.of(context) == AppLayoutClass.mobile;
    final weekStart = anchor.subtract(Duration(days: anchor.weekday - 1));
    final rangeStart = mobile ? anchor : weekStart;
    final rangeEnd = rangeStart.add(Duration(days: mobile ? 1 : 7));
    final rangeKey = '${clinic.id}:${rangeStart.toIso8601String()}:$mobile';
    if (_loadedRange != rangeKey) {
      _loadedRange = rangeKey;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        context.read<AppointmentCubit>().load(
          clinicId: clinic.id,
          from: rangeStart.toUtc(),
          until: rangeEnd.toUtc(),
        );
        context.read<ScheduleCubit>().load(clinic.id);
        try {
          final patientCubit = context.read<PatientCubit>();
          if (patientCubit.state.clinicId != clinic.id) {
            patientCubit.load(clinic.id);
          }
        } catch (_) {}
      });
    }
    final roles = clinicState.activeMembership?.roles ?? const <String>{};
    final canCreate = roles.any(
      (role) => role == 'owner' || role == 'dentist' || role == 'receptionist',
    );
    final l = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(l.appointmentsWithTimeZone(clinic.timeZone)),
        leading: IconButton(
          onPressed: () => context.go('/dashboard'),
          icon: const Icon(Icons.arrow_back),
        ),
        actions: [
          IconButton(
            tooltip: l.previousWeekLabel,
            onPressed: () => setState(
              () => _anchor = _anchor.subtract(Duration(days: mobile ? 1 : 7)),
            ),
            icon: const Icon(Icons.chevron_left),
          ),
          IconButton(
            tooltip: l.todayLabel,
            onPressed: () => setState(() => _anchor = DateTime.now()),
            icon: const Icon(Icons.today_outlined),
          ),
          IconButton(
            tooltip: l.nextWeekLabel,
            onPressed: () => setState(
              () => _anchor = _anchor.add(Duration(days: mobile ? 1 : 7)),
            ),
            icon: const Icon(Icons.chevron_right),
          ),
        ],
      ),
      floatingActionButton: canCreate
          ? FloatingActionButton.extended(
              onPressed: () => context.go('/appointments/new'),
              icon: const Icon(Icons.add),
              label: Text(l.newAppointmentLabel),
            )
          : null,
      body: BlocBuilder<AppointmentCubit, AppointmentState>(
        builder: (context, state) => ListView(
          padding: AppInsets.page(AppBreakpoints.of(context)),
          children: [
            Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(
                  maxWidth: AppSpacing.wideContentWidth,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.baseline,
                      textBaseline: TextBaseline.alphabetic,
                      children: [
                        Expanded(
                          child: Text(
                            mobile
                                ? DateFormat.yMMMMd().format(anchor)
                                : '${DateFormat.MMMd().format(weekStart)} – ${DateFormat.yMMMd().format(rangeEnd.subtract(const Duration(days: 1)))}',
                            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                          ),
                        ),
                        if (state.status == AppointmentLoadStatus.ready) ...[
                          const SizedBox(width: AppSpacing.small),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: Theme.of(context).colorScheme.surfaceContainerHighest,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              l.appointmentsCount(state.appointments.length),
                              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                    fontWeight: FontWeight.w600,
                                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                                  ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: AppSpacing.medium),
                    if (state.status == AppointmentLoadStatus.loading) ...[
                      const LinearProgressIndicator(),
                      const SizedBox(height: AppSpacing.medium),
                    ],
                    if (state.failure != null)
                      _AppointmentMessage(
                        failureMessage(
                          state.failure!,
                          AppLocalizations.of(context),
                        ),
                      ),
                    if (state.issue != null)
                      _AppointmentMessage(_issueMessage(state.issue!, l)),
                    if (state.status == AppointmentLoadStatus.ready &&
                        state.appointments.isEmpty)
                      _AppointmentEmptyState(
                        message: mobile ? l.noAppointmentsDay : l.noAppointmentsWeek,
                        canCreate: canCreate,
                      ),
                    for (final appointment in state.appointments)
                      _AppointmentCard(
                        appointment: appointment,
                        location: location,
                        showDate: !mobile,
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class NewAppointmentPage extends StatefulWidget {
  const NewAppointmentPage({
    this.initialPatientId,
    this.initialPurpose,
    this.initialDurationMinutes,
    this.initialDentistMemberId,
    super.key,
  });

  final String? initialPatientId;
  final String? initialPurpose;
  final int? initialDurationMinutes;
  final String? initialDentistMemberId;

  @override
  State<NewAppointmentPage> createState() => _NewAppointmentPageState();
}

class _NewAppointmentPageState extends State<NewAppointmentPage> {
  final _purpose = TextEditingController();
  final _search = TextEditingController();
  final _overrideReason = TextEditingController();
  final _form = GlobalKey<FormState>();
  String? _patientId;
  String? _dentistMemberId;
  DateTime _date = DateTime.now();
  TimeOfDay _time = const TimeOfDay(hour: 9, minute: 0);
  int _duration = 30;
  String? _loadedClinicId;

  @override
  void initState() {
    super.initState();
    _patientId = widget.initialPatientId;
    if (widget.initialPurpose != null && widget.initialPurpose!.isNotEmpty) {
      _purpose.text = widget.initialPurpose!;
    }
    if (widget.initialDurationMinutes != null &&
        widget.initialDurationMinutes! > 0) {
      _duration = widget.initialDurationMinutes!;
    }
    _dentistMemberId = widget.initialDentistMemberId;
    tz_data.initializeTimeZones();
  }

  @override
  void dispose() {
    _purpose.dispose();
    _search.dispose();
    _overrideReason.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final clinic = context.watch<ClinicCubit>().state.activeClinic;
    if (clinic == null) {
      return _AppointmentMessage(l.chooseClinicFirst);
    }
    final appointmentState = context.watch<AppointmentCubit>().state;
    final patientState = context.watch<PatientCubit>().state;
    final scheduleState = context.watch<ScheduleCubit>().state;
    if (_loadedClinicId != clinic.id) {
      _loadedClinicId = clinic.id;
      _dentistMemberId = null;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          context.read<ScheduleCubit>().load(clinic.id);
          if (context.read<PatientCubit>().state.clinicId != clinic.id ||
              context.read<PatientCubit>().state.status ==
                  PatientStatus.initial) {
            context.read<PatientCubit>().load(clinic.id);
          }
        }
      });
    }
    final hasCurrentDentistDirectory = scheduleState.clinicId == clinic.id;
    final dentists = hasCurrentDentistDirectory
        ? scheduleState.dentists
        : const <ScheduleDentist>[];
    if (_dentistMemberId != null &&
        !dentists.any((dentist) => dentist.memberId == _dentistMemberId)) {
      _dentistMemberId = null;
    }
    if (_dentistMemberId == null && dentists.length == 1) {
      _dentistMemberId = dentists.single.memberId;
    }
    final dentistsLoading =
        !hasCurrentDentistDirectory ||
        scheduleState.status == ScheduleStatus.initial ||
        scheduleState.status == ScheduleStatus.loading;
    final dentistsFailed =
        hasCurrentDentistDirectory &&
        scheduleState.status == ScheduleStatus.failure;
    final roles =
        context.watch<ClinicCubit>().state.activeMembership?.roles ??
        const <String>{};
    final isOwner = roles.contains('owner');

    final activePatients = patientState.patients
        .where((item) => !item.isArchived)
        .toList(growable: false);
    final selectedPatient = _patientId == null
        ? null
        : activePatients.cast<Patient?>().firstWhere(
            (p) => p?.id == _patientId,
            orElse: () => null,
          );

    final searchQuery = _search.text.trim().toLowerCase();
    final matchingPatients = searchQuery.isEmpty
        ? activePatients
        : activePatients
              .where((p) {
                return p.fullName.toLowerCase().contains(searchQuery) ||
                    p.patientNumber.toLowerCase().contains(searchQuery) ||
                    (p.phone?.toLowerCase().contains(searchQuery) ?? false);
              })
              .toList(growable: false);

    return Scaffold(
      appBar: AppBar(
        title: Text(l.newAppointmentLabel),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            if (Navigator.of(context).canPop()) {
              Navigator.of(context).pop();
            } else {
              context.go('/appointments');
            }
          },
        ),
      ),
      body: ListView(
        padding: AppInsets.page(AppBreakpoints.of(context)),
        children: [
          Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(
                maxWidth: AppSpacing.contentWidth,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(l.clinicTimeZoneValue(clinic.timeZone)),
                  const SizedBox(height: AppSpacing.medium),
                  if (_patientId != null)
                    _SelectedPatientCard(
                      patient: selectedPatient,
                      fallbackPatientId: _patientId!,
                      onChangePatient: () => setState(() => _patientId = null),
                    )
                  else ...[
                    TextField(
                      controller: _search,
                      decoration: InputDecoration(
                        labelText: l.findPatientLabel,
                        prefixIcon: const Icon(Icons.search),
                        suffixIcon: _search.text.isNotEmpty
                            ? IconButton(
                                icon: const Icon(Icons.clear, size: 20),
                                onPressed: () {
                                  _search.clear();
                                  setState(() {});
                                  context.read<PatientCubit>().load(clinic.id);
                                },
                              )
                            : null,
                      ),
                      textInputAction: TextInputAction.search,
                      onChanged: (_) => setState(() {}),
                      onSubmitted: (value) => context.read<PatientCubit>().load(
                        clinic.id,
                        query: value,
                      ),
                    ),
                    if (patientState.status == PatientStatus.loading)
                      const Padding(
                        padding: EdgeInsets.only(top: AppSpacing.small),
                        child: LinearProgressIndicator(),
                      ),
                    if (matchingPatients.isEmpty &&
                        patientState.status != PatientStatus.loading)
                      Padding(
                        padding: const EdgeInsets.symmetric(
                          vertical: AppSpacing.medium,
                        ),
                        child: Column(
                          children: [
                            Text(
                              l.noPatientsFound,
                              textAlign: TextAlign.center,
                              style: Theme.of(context).textTheme.bodyMedium
                                  ?.copyWith(
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.onSurfaceVariant,
                                  ),
                            ),
                            const SizedBox(height: AppSpacing.small),
                            OutlinedButton.icon(
                              onPressed: () => context.push('/patients/new'),
                              icon: const Icon(
                                Icons.person_add_alt_1,
                                size: 18,
                              ),
                              label: Text(l.newPatientShortcut),
                            ),
                          ],
                        ),
                      )
                    else
                      for (final patient in matchingPatients.take(8))
                        Card(
                          elevation: 0,
                          margin: const EdgeInsets.only(top: AppSpacing.small),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                            side: BorderSide(
                              color: Theme.of(context)
                                  .colorScheme
                                  .outlineVariant
                                  .withValues(alpha: 0.5),
                            ),
                          ),
                          child: ListTile(
                            leading: CircleAvatar(
                              backgroundColor: Theme.of(
                                context,
                              ).colorScheme.primaryContainer,
                              foregroundColor: Theme.of(
                                context,
                              ).colorScheme.onPrimaryContainer,
                              child: const Icon(Icons.person_outline),
                            ),
                            title: Text(
                              patient.fullName,
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            subtitle: Text(
                              (patient.phone?.isNotEmpty ?? false)
                                  ? '${patient.patientNumber} · ${patient.phone}'
                                  : patient.patientNumber,
                            ),
                            trailing: const Icon(Icons.chevron_right, size: 20),
                            onTap: () =>
                                setState(() => _patientId = patient.id),
                          ),
                        ),
                  ],
                  const SizedBox(height: AppSpacing.medium),
                  const Divider(),
                  const SizedBox(height: AppSpacing.medium),
                  Form(
                    key: _form,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        DropdownButtonFormField<String>(
                          key: ValueKey(
                            '${clinic.id}:$_dentistMemberId:${dentists.length}',
                          ),
                          isExpanded: true,
                          initialValue: _dentistMemberId,
                          decoration: InputDecoration(
                            labelText: l.dentistLabel,
                          ),
                          items: dentists
                              .map(
                                (dentist) => DropdownMenuItem(
                                  value: dentist.memberId,
                                  child: Text(dentist.displayName),
                                ),
                              )
                              .toList(growable: false),
                          onChanged: dentistsLoading || dentistsFailed
                              ? null
                              : (value) =>
                                    setState(() => _dentistMemberId = value),
                          validator: (value) =>
                              value == null ? l.chooseDentistValidation : null,
                        ),
                        if (_dentistMemberId != null)
                          _DentistWorkingHoursBadge(
                            dentistMemberId: _dentistMemberId!,
                            date: _date,
                            time: _time,
                            duration: _duration,
                            scheduleState: scheduleState,
                          ),
                        if (dentistsLoading)
                          const Padding(
                            padding: EdgeInsets.only(top: AppSpacing.small),
                            child: LinearProgressIndicator(),
                          ),
                        if (dentistsFailed)
                          Padding(
                            padding: const EdgeInsets.only(
                              top: AppSpacing.small,
                            ),
                            child: _DentistDirectoryMessage(
                              message: failureMessage(
                                scheduleState.failure ?? UnknownFailure(),
                                l,
                              ),
                              actionLabel: l.retryLabel,
                              onRetry: () =>
                                  context.read<ScheduleCubit>().load(clinic.id),
                            ),
                          ),
                        if (!dentistsLoading &&
                            !dentistsFailed &&
                            dentists.isEmpty)
                          Padding(
                            padding: const EdgeInsets.only(
                              top: AppSpacing.small,
                            ),
                            child: _AppointmentMessage(l.noActiveDentist),
                          ),
                        const SizedBox(height: AppSpacing.medium),
                        _AppointmentFieldGrid(
                          children: [
                            Card(
                              margin: EdgeInsets.zero,
                              child: ListTile(
                                title: Text(l.dateLabel),
                                subtitle: Text(
                                  DateFormat.yMMMd().format(_date),
                                ),
                                trailing: const Icon(
                                  Icons.calendar_today_outlined,
                                ),
                                onTap: () async {
                                  final value = await showDatePicker(
                                    context: context,
                                    firstDate: DateTime.now().subtract(
                                      const Duration(days: 365),
                                    ),
                                    lastDate: DateTime.now().add(
                                      const Duration(days: 730),
                                    ),
                                    initialDate: _date,
                                  );
                                  if (value != null) {
                                    setState(() => _date = value);
                                  }
                                },
                              ),
                            ),
                            Card(
                              margin: EdgeInsets.zero,
                              child: ListTile(
                                title: Text(l.startTimeLabel),
                                subtitle: Text(_time.format(context)),
                                trailing: const Icon(Icons.schedule_outlined),
                                onTap: () async {
                                  final value = await showTimePicker(
                                    context: context,
                                    initialTime: _time,
                                  );
                                  if (value != null) {
                                    setState(() => _time = value);
                                  }
                                },
                              ),
                            ),
                            DropdownButtonFormField<int>(
                              isExpanded: true,
                              initialValue: _duration,
                              decoration: InputDecoration(
                                labelText: l.durationLabel,
                              ),
                              items: const [15, 30, 45, 60, 75, 90, 120]
                                  .map(
                                    (minutes) => DropdownMenuItem(
                                      value: minutes,
                                      child: Text(l.minutesValue(minutes)),
                                    ),
                                  )
                                  .toList(growable: false),
                              onChanged: (value) =>
                                  setState(() => _duration = value ?? 30),
                            ),
                          ],
                        ),
                        const SizedBox(height: AppSpacing.medium),
                        Text(
                          l.visitReasonLabel,
                          style: Theme.of(context).textTheme.titleSmall
                              ?.copyWith(fontWeight: FontWeight.w600),
                        ),
                        const SizedBox(height: AppSpacing.extraSmall),
                        Wrap(
                          spacing: AppSpacing.small,
                          runSpacing: AppSpacing.extraSmall,
                          children: [
                            _buildReasonChip(
                              l.quickReasonCheckup,
                              Icons.search_outlined,
                            ),
                            _buildReasonChip(
                              l.quickReasonCleaning,
                              Icons.cleaning_services_outlined,
                            ),
                            _buildReasonChip(
                              l.quickReasonToothache,
                              Icons.healing_outlined,
                            ),
                            _buildReasonChip(
                              l.quickReasonConsultation,
                              Icons.question_answer_outlined,
                            ),
                            _buildReasonChip(
                              l.quickReasonFollowUp,
                              Icons.replay_outlined,
                            ),
                          ],
                        ),
                        const SizedBox(height: AppSpacing.small),
                        TextFormField(
                          controller: _purpose,
                          maxLength: 240,
                          decoration: InputDecoration(
                            labelText: l.appointmentPurposeOptional,
                            alignLabelWithHint: true,
                          ),
                        ),
                        if (isOwner) ...[
                          const SizedBox(height: AppSpacing.small),
                          Theme(
                            data: Theme.of(
                              context,
                            ).copyWith(dividerColor: Colors.transparent),
                            child: ExpansionTile(
                              tilePadding: EdgeInsets.zero,
                              initiallyExpanded:
                                  _overrideReason.text.isNotEmpty ||
                                  appointmentState.issue != null,
                              leading: const Icon(
                                Icons.admin_panel_settings_outlined,
                                size: 20,
                              ),
                              title: Text(
                                l.overrideScheduleQuestion,
                                style: Theme.of(context).textTheme.bodySmall
                                    ?.copyWith(
                                      color: Theme.of(
                                        context,
                                      ).colorScheme.onSurfaceVariant,
                                    ),
                              ),
                              children: [
                                Padding(
                                  padding: const EdgeInsets.only(
                                    bottom: AppSpacing.small,
                                  ),
                                  child: TextFormField(
                                    controller: _overrideReason,
                                    maxLength: 1000,
                                    decoration: InputDecoration(
                                      labelText: l.ownerOverrideOptional,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                        if (appointmentState.issue != null)
                          _AppointmentMessage(
                            _issueMessage(appointmentState.issue!, l),
                          ),
                        if (appointmentState.failure != null)
                          _AppointmentMessage(
                            failureMessage(
                              appointmentState.failure!,
                              AppLocalizations.of(context),
                            ),
                          ),
                        const SizedBox(height: AppSpacing.medium),
                        FilledButton(
                          onPressed:
                              appointmentState.mutating ||
                                  dentistsLoading ||
                                  dentistsFailed ||
                                  _patientId == null ||
                                  _dentistMemberId == null
                              ? null
                              : () => _create(context, clinic.timeZone),
                          child: appointmentState.mutating
                              ? const CircularProgressIndicator()
                              : Text(l.createAppointmentLabel),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReasonChip(String text, IconData icon) {
    final isSelected = _purpose.text == text;
    final theme = Theme.of(context);
    return ActionChip(
      avatar: Icon(
        icon,
        size: 16,
        color: isSelected
            ? theme.colorScheme.onPrimaryContainer
            : theme.colorScheme.primary,
      ),
      label: Text(text),
      backgroundColor: isSelected
          ? theme.colorScheme.primaryContainer
          : theme.colorScheme.surfaceContainerLow,
      side: BorderSide(
        color: isSelected
            ? theme.colorScheme.primary
            : theme.colorScheme.outlineVariant,
      ),
      onPressed: () {
        setState(() {
          if (_purpose.text == text) {
            _purpose.clear();
          } else {
            _purpose.text = text;
          }
        });
      },
    );
  }

  Future<void> _create(BuildContext context, String timeZone) async {
    if (!(_form.currentState?.validate() ?? false) || _patientId == null) {
      return;
    }
    final location = tz.getLocation(timeZone);
    final start = tz.TZDateTime(
      location,
      _date.year,
      _date.month,
      _date.day,
      _time.hour,
      _time.minute,
    );
    final succeeded = await context.read<AppointmentCubit>().create(
      AppointmentDraft(
        clinicId: context.read<ClinicCubit>().state.activeClinic!.id,
        patientId: _patientId!,
        dentistMemberId: _dentistMemberId!,
        startsAt: start.toUtc(),
        endsAt: start.add(Duration(minutes: _duration)).toUtc(),
        purpose: _purpose.text.trim().isEmpty ? null : _purpose.text.trim(),
        overrideReason: _overrideReason.text.trim().isEmpty
            ? null
            : _overrideReason.text.trim(),
      ),
    );
    if (succeeded && context.mounted) context.go('/appointments');
  }
}

class _SelectedPatientCard extends StatelessWidget {
  const _SelectedPatientCard({
    required this.patient,
    required this.fallbackPatientId,
    required this.onChangePatient,
  });

  final Patient? patient;
  final String fallbackPatientId;
  final VoidCallback onChangePatient;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final theme = Theme.of(context);

    return Card(
      elevation: 0,
      color: theme.colorScheme.primaryContainer.withValues(alpha: 0.25),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: theme.colorScheme.primary.withValues(alpha: 0.3),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.medium),
        child: Row(
          children: [
            CircleAvatar(
              radius: 20,
              backgroundColor: theme.colorScheme.primary,
              foregroundColor: theme.colorScheme.onPrimary,
              child: const Icon(Icons.person, size: 22),
            ),
            const SizedBox(width: AppSpacing.medium),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    patient?.fullName ??
                        l.patientSelectedValue(fallbackPatientId),
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  if (patient != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      (patient!.phone?.isNotEmpty ?? false)
                          ? '${patient!.patientNumber} · ${patient!.phone}'
                          : patient!.patientNumber,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            OutlinedButton.icon(
              onPressed: onChangePatient,
              icon: const Icon(Icons.swap_horiz, size: 16),
              label: Text(l.changePatientLabel),
              style: OutlinedButton.styleFrom(
                visualDensity: VisualDensity.compact,
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DentistWorkingHoursBadge extends StatelessWidget {
  const _DentistWorkingHoursBadge({
    required this.dentistMemberId,
    required this.date,
    required this.time,
    required this.duration,
    required this.scheduleState,
  });

  final String dentistMemberId;
  final DateTime date;
  final TimeOfDay time;
  final int duration;
  final ScheduleState scheduleState;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final theme = Theme.of(context);

    final dateStart = DateTime(date.year, date.month, date.day);
    final dateEnd = DateTime(date.year, date.month, date.day, 23, 59, 59);

    final matchingExceptions = scheduleState.exceptions
        .where((e) {
          if (e.dentistMemberId != dentistMemberId) return false;
          return !(e.endsAt.isBefore(dateStart) || e.startsAt.isAfter(dateEnd));
        })
        .toList(growable: false);

    if (matchingExceptions.isNotEmpty) {
      final exc = matchingExceptions.first;
      final isLeave = exc.kind == ScheduleExceptionKind.leave;
      final message = isLeave ? l.doctorOnLeave : l.doctorOffDuty;
      final fullMessage = exc.reason != null && exc.reason!.trim().isNotEmpty
          ? '$message (${exc.reason!.trim()})'
          : message;

      return Container(
        margin: const EdgeInsets.only(top: AppSpacing.small),
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.medium,
          vertical: AppSpacing.small,
        ),
        decoration: BoxDecoration(
          color: theme.colorScheme.errorContainer.withValues(alpha: 0.7),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: theme.colorScheme.error.withValues(alpha: 0.35),
          ),
        ),
        child: Row(
          children: [
            Icon(Icons.event_busy, size: 20, color: theme.colorScheme.error),
            const SizedBox(width: AppSpacing.small),
            Expanded(
              child: Text(
                fullMessage,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onErrorContainer,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      );
    }

    final dentistVersions = scheduleState.versions
        .where((v) => v.dentistMemberId == dentistMemberId)
        .toList(growable: false);

    if (dentistVersions.isEmpty) {
      return Container(
        margin: const EdgeInsets.only(top: AppSpacing.small),
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.medium,
          vertical: AppSpacing.small,
        ),
        decoration: BoxDecoration(
          color: theme.colorScheme.errorContainer.withValues(alpha: 0.7),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: theme.colorScheme.error.withValues(alpha: 0.35),
          ),
        ),
        child: Row(
          children: [
            Icon(
              Icons.warning_amber_rounded,
              size: 20,
              color: theme.colorScheme.error,
            ),
            const SizedBox(width: AppSpacing.small),
            Expanded(
              child: Text(
                l.doctorNoScheduleConfigured,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onErrorContainer,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      );
    }

    final dateIso = DateFormat('yyyy-MM-dd').format(date);
    final sorted = [...dentistVersions]
      ..sort((a, b) => b.effectiveFrom.compareTo(a.effectiveFrom));

    DoctorScheduleVersion? activeVersion;
    for (final v in sorted) {
      if (v.effectiveFrom.compareTo(dateIso) <= 0) {
        activeVersion = v;
        break;
      }
    }
    activeVersion ??= sorted.last;

    final weekday = date.weekday;
    final period = activeVersion.workingPeriods
        .cast<DoctorWorkingPeriod?>()
        .firstWhere((p) => p?.weekday == weekday, orElse: () => null);

    if (period == null) {
      return Container(
        margin: const EdgeInsets.only(top: AppSpacing.small),
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.medium,
          vertical: AppSpacing.small,
        ),
        decoration: BoxDecoration(
          color: theme.colorScheme.errorContainer.withValues(alpha: 0.7),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: theme.colorScheme.error.withValues(alpha: 0.35),
          ),
        ),
        child: Row(
          children: [
            Icon(Icons.event_busy, size: 20, color: theme.colorScheme.error),
            const SizedBox(width: AppSpacing.small),
            Expanded(
              child: Text(
                l.doctorOffDuty,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onErrorContainer,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      );
    }

    int parseMinutes(String timeStr) {
      final parts = timeStr.split(':');
      if (parts.length < 2) return 0;
      return (int.tryParse(parts[0]) ?? 0) * 60 + (int.tryParse(parts[1]) ?? 0);
    }

    final periodStart = parseMinutes(period.startsAt);
    final periodEnd = parseMinutes(period.endsAt);
    final selectedStart = time.hour * 60 + time.minute;
    final selectedEnd = selectedStart + duration;

    final hours = '${period.startsAt} – ${period.endsAt}';

    if (selectedStart < periodStart || selectedEnd > periodEnd) {
      return Container(
        margin: const EdgeInsets.only(top: AppSpacing.small),
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.medium,
          vertical: AppSpacing.small,
        ),
        decoration: BoxDecoration(
          color: theme.colorScheme.errorContainer.withValues(alpha: 0.7),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: theme.colorScheme.error.withValues(alpha: 0.35),
          ),
        ),
        child: Row(
          children: [
            Icon(
              Icons.schedule_outlined,
              size: 20,
              color: theme.colorScheme.error,
            ),
            const SizedBox(width: AppSpacing.small),
            Expanded(
              child: Text(
                l.timeOutsideWorkingHours(time.format(context), hours),
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onErrorContainer,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      margin: const EdgeInsets.only(top: AppSpacing.small),
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.medium,
        vertical: AppSpacing.small,
      ),
      decoration: BoxDecoration(
        color: theme.colorScheme.primaryContainer.withValues(alpha: 0.45),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: theme.colorScheme.primary.withValues(alpha: 0.25),
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.access_time_filled,
            size: 18,
            color: theme.colorScheme.primary,
          ),
          const SizedBox(width: AppSpacing.small),
          Expanded(
            child: Text(
              l.doctorWorkingHours(hours),
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onPrimaryContainer,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AppointmentCard extends StatelessWidget {
  const _AppointmentCard({
    required this.appointment,
    required this.location,
    this.showDate = false,
  });

  final Appointment appointment;
  final tz.Location location;
  final bool showDate;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l = AppLocalizations.of(context);
    final roles =
        context.watch<ClinicCubit>().state.activeMembership?.roles ??
        const <String>{};
    final localStart = tz.TZDateTime.from(appointment.startsAt, location);
    final localEnd = tz.TZDateTime.from(appointment.endsAt, location);
    final durationMinutes = appointment.duration.inMinutes;

    final canConfirm =
        roles.contains('owner') || roles.contains('receptionist');
    final canReschedule =
        canConfirm &&
        (appointment.status == AppointmentStatus.scheduled ||
            appointment.status == AppointmentStatus.confirmed);
    final canDentistAct = roles.contains('owner') || roles.contains('dentist');
    final canCancel =
        roles.contains('owner') ||
        roles.contains('dentist') ||
        roles.contains('receptionist');
    final canNoShow = canCancel;
    final canPrepare =
        roles.contains('owner') ||
        roles.contains('dentist') ||
        roles.contains('assistant');
    final canOpenSession =
        (roles.contains('dentist') || roles.contains('assistant')) &&
        appointment.status != AppointmentStatus.cancelled &&
        appointment.status != AppointmentStatus.noShow;

    final (statusColor, statusBg, statusIcon) = _statusStyle(appointment.status, theme);

    final timeLabel = showDate
        ? '${DateFormat.E().format(localStart)}, ${DateFormat.jm().format(localStart)} – ${DateFormat.jm().format(localEnd)}'
        : '${DateFormat.jm().format(localStart)} – ${DateFormat.jm().format(localEnd)}';

    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: AppSpacing.medium),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: appointment.status == AppointmentStatus.inProgress
              ? statusColor
              : theme.colorScheme.outlineVariant.withValues(alpha: 0.6),
          width: appointment.status == AppointmentStatus.inProgress ? 1.5 : 1.0,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.medium),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Wrap(
              alignment: WrapAlignment.spaceBetween,
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: AppSpacing.small,
              runSpacing: AppSpacing.small,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.6),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Wrap(
                    crossAxisAlignment: WrapCrossAlignment.center,
                    spacing: 6,
                    runSpacing: 2,
                    children: [
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.access_time_rounded,
                            size: 14,
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                          const SizedBox(width: 5),
                          Text(
                            timeLabel,
                            style: theme.textTheme.labelMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                      if (durationMinutes > 0)
                        Text(
                          '· ${l.durationMinutes(durationMinutes)}',
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                    ],
                  ),
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                      decoration: BoxDecoration(
                        color: statusBg,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(statusIcon, size: 14, color: statusColor),
                          const SizedBox(width: 4),
                          Text(
                            _statusLabel(appointment.status, l),
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: statusColor,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 2),
                    PopupMenuButton<String>(
                      icon: const Icon(Icons.more_vert, size: 20),
                      tooltip: MaterialLocalizations.of(context).moreButtonTooltip,
                      onSelected: (action) => _onMenu(context, action),
                      itemBuilder: (_) => [
                        PopupMenuItem(
                          value: 'whatsapp_reminder',
                          child: Row(
                            children: [
                              const Icon(
                                Icons.chat_bubble_outline_rounded,
                                size: 18,
                                color: Color(0xFF25D366),
                              ),
                              const SizedBox(width: 8),
                              Text(l.sendWhatsAppReminder),
                            ],
                          ),
                        ),
                        if (canReschedule)
                          PopupMenuItem(
                            value: 'reschedule',
                            child: Text(l.rescheduleLabel),
                          ),
                        if (appointment.status == AppointmentStatus.scheduled && canConfirm)
                          PopupMenuItem(value: 'confirmed', child: Text(l.confirmLabel)),
                        if ((appointment.status == AppointmentStatus.scheduled ||
                                appointment.status == AppointmentStatus.confirmed) &&
                            canDentistAct)
                          PopupMenuItem(value: 'in_progress', child: Text(l.startLabel)),
                        if (appointment.status == AppointmentStatus.inProgress &&
                            canDentistAct)
                          PopupMenuItem(value: 'completed', child: Text(l.completeLabel)),
                        if ((appointment.status == AppointmentStatus.scheduled ||
                                appointment.status == AppointmentStatus.confirmed) &&
                            canNoShow)
                          PopupMenuItem(value: 'no_show', child: Text(l.markNoShowLabel)),
                        if ((appointment.status == AppointmentStatus.scheduled ||
                                appointment.status == AppointmentStatus.confirmed ||
                                appointment.status == AppointmentStatus.inProgress) &&
                            canCancel)
                          PopupMenuItem(value: 'cancelled', child: Text(l.cancelLabel)),
                        if (canPrepare)
                          PopupMenuItem(
                            value: 'preparation',
                            child: Text(l.preparationNoteLabel),
                          ),
                        if (canOpenSession)
                          PopupMenuItem(
                            value: 'clinical_session',
                            child: Text(
                              l.openClinicalSessionLabel,
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.medium),
            InkWell(
              borderRadius: BorderRadius.circular(10),
              onTap: () => context.go('/patients/${appointment.patientId}'),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 20,
                      backgroundColor: theme.colorScheme.primaryContainer,
                      foregroundColor: theme.colorScheme.onPrimaryContainer,
                      child: Text(
                        appointment.patientName.trim().isNotEmpty
                            ? appointment.patientName.trim()[0].toUpperCase()
                            : 'P',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.medium),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Wrap(
                            crossAxisAlignment: WrapCrossAlignment.center,
                            spacing: 6,
                            runSpacing: 2,
                            children: [
                              Text(
                                appointment.patientName,
                                style: theme.textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: theme.colorScheme.surfaceContainerHighest,
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  appointment.patientNumber,
                                  style: theme.textTheme.labelSmall?.copyWith(
                                    fontFamily: 'monospace',
                                    color: theme.colorScheme.onSurfaceVariant,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 3),
                          Row(
                            children: [
                              Icon(
                                Icons.badge_outlined,
                                size: 14,
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Text(
                                  appointment.dentistName,
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: theme.colorScheme.onSurfaceVariant,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    Icon(
                      Icons.chevron_right_rounded,
                      color: theme.colorScheme.onSurfaceVariant,
                      size: 20,
                    ),
                  ],
                ),
              ),
            ),
            if (appointment.purpose != null && appointment.purpose!.trim().isNotEmpty) ...[
              const SizedBox(height: AppSpacing.small),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceContainerLow,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.notes_rounded,
                      size: 14,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        appointment.purpose!,
                        style: theme.textTheme.bodySmall,
                        overflow: TextOverflow.ellipsis,
                        maxLines: 2,
                      ),
                    ),
                  ],
                ),
              ),
            ],
            if (appointment.preparationNote != null &&
                appointment.preparationNote!.trim().isNotEmpty) ...[
              const SizedBox(height: AppSpacing.small),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.amber.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.amber.withValues(alpha: 0.3)),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.info_outline_rounded, size: 15, color: Colors.amber.shade900),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        '${l.preparationNoteBadge}: ${appointment.preparationNote!}',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: Colors.amber.shade900,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            if (appointment.overrideReason != null &&
                appointment.overrideReason!.trim().isNotEmpty) ...[
              const SizedBox(height: AppSpacing.small),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: theme.colorScheme.errorContainer.withValues(alpha: 0.25),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(Icons.warning_amber_rounded, size: 14, color: theme.colorScheme.error),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        '${l.overrideBadge}: ${appointment.overrideReason!}',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.error,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: AppSpacing.medium),
            Wrap(
              spacing: AppSpacing.small,
              runSpacing: AppSpacing.small,
              alignment: WrapAlignment.end,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                IconButton(
                  onPressed: () => _sendWhatsAppReminder(context),
                  icon: const Icon(Icons.chat_bubble_outline_rounded, size: 18),
                  tooltip: l.sendWhatsAppReminder,
                  style: IconButton.styleFrom(
                    foregroundColor: const Color(0xFF25D366),
                    visualDensity: VisualDensity.compact,
                  ),
                ),
                OutlinedButton.icon(
                  onPressed: () => context.go('/patients/${appointment.patientId}'),
                  icon: const Icon(Icons.person_outline, size: 16),
                  label: Text(l.viewProfileLabel),
                  style: OutlinedButton.styleFrom(
                    visualDensity: VisualDensity.compact,
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
                ),
                if (appointment.status == AppointmentStatus.scheduled && canConfirm)
                  FilledButton.tonalIcon(
                    onPressed: () => _transition(context, AppointmentStatus.confirmed),
                    icon: const Icon(Icons.check_circle_outline, size: 16),
                    label: Text(l.confirmLabel),
                    style: FilledButton.styleFrom(
                      visualDensity: VisualDensity.compact,
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    ),
                  ),
                if ((appointment.status == AppointmentStatus.scheduled ||
                        appointment.status == AppointmentStatus.confirmed) &&
                    canDentistAct)
                  FilledButton.tonalIcon(
                    onPressed: () => _transition(context, AppointmentStatus.inProgress),
                    icon: const Icon(Icons.play_arrow_rounded, size: 16),
                    label: Text(l.startLabel),
                    style: FilledButton.styleFrom(
                      visualDensity: VisualDensity.compact,
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    ),
                  ),
                if (appointment.status == AppointmentStatus.inProgress && canOpenSession)
                  FilledButton.tonalIcon(
                    onPressed: () => context.go(
                      '/patients/${appointment.patientId}/visits?appointmentId=${appointment.id}',
                    ),
                    icon: const Icon(Icons.assignment_outlined, size: 16),
                    label: Text(l.openClinicalSessionLabel),
                    style: FilledButton.styleFrom(
                      visualDensity: VisualDensity.compact,
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    ),
                  ),
                if (appointment.status == AppointmentStatus.inProgress && canDentistAct)
                  FilledButton.tonalIcon(
                    onPressed: () => _transition(context, AppointmentStatus.completed),
                    icon: const Icon(Icons.task_alt_rounded, size: 16),
                    label: Text(l.completeLabel),
                    style: FilledButton.styleFrom(
                      visualDensity: VisualDensity.compact,
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _onMenu(BuildContext context, String action) async {
    if (action == 'whatsapp_reminder') {
      return _sendWhatsAppReminder(context);
    }
    if (action == 'reschedule') return _reschedule(context);
    if (action == 'clinical_session') {
      context.go(
        '/patients/${appointment.patientId}/visits?appointmentId=${appointment.id}',
      );
      return;
    }
    if (action == 'preparation') {
      return _transition(context, AppointmentStatus.scheduled);
    }
    final status = switch (action) {
      'confirmed' => AppointmentStatus.confirmed,
      'in_progress' => AppointmentStatus.inProgress,
      'completed' => AppointmentStatus.completed,
      'cancelled' => AppointmentStatus.cancelled,
      'no_show' => AppointmentStatus.noShow,
      _ => null,
    };
    if (status != null) await _transition(context, status);
  }

  Future<void> _reschedule(BuildContext context) async {
    final l = AppLocalizations.of(context);
    final local = tz.TZDateTime.from(appointment.startsAt, location);
    final date = await showDatePicker(
      context: context,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 730)),
      initialDate: DateTime(local.year, local.month, local.day),
    );
    if (date == null || !context.mounted) return;
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(hour: local.hour, minute: local.minute),
    );
    if (time == null || !context.mounted) return;
    final roles =
        context.read<ClinicCubit>().state.activeMembership?.roles ??
        const <String>{};
    String? overrideReason;
    if (roles.contains('owner')) {
      final controller = TextEditingController();
      overrideReason = await showSettledDialog<String>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: Text(l.ownerOverrideReasonTitle),
          content: TextField(
            controller: controller,
            maxLength: 1000,
            decoration: InputDecoration(labelText: l.overrideConflictHelp),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, ''),
              child: Text(l.continueLabel),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(dialogContext, controller.text),
              child: Text(l.useReasonLabel),
            ),
          ],
        ),
      );
      controller.dispose();
      if (overrideReason == null || !context.mounted) return;
    }
    final start = tz.TZDateTime(
      location,
      date.year,
      date.month,
      date.day,
      time.hour,
      time.minute,
    );
    await context.read<AppointmentCubit>().reschedule(
      appointmentId: appointment.id,
      startsAt: start.toUtc(),
      endsAt: start.add(appointment.duration).toUtc(),
      overrideReason: overrideReason?.trim().isEmpty ?? true
          ? null
          : overrideReason!.trim(),
    );
  }

  Future<void> _transition(
    BuildContext context,
    AppointmentStatus status,
  ) async {
    final l = AppLocalizations.of(context);
    if (status == AppointmentStatus.scheduled) {
      final controller = TextEditingController(
        text: appointment.preparationNote ?? '',
      );
      final note = await showSettledDialog<String>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: Text(l.operationalPreparationNoteTitle),
          content: TextField(
            controller: controller,
            maxLines: 4,
            maxLength: 2000,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: Text(l.cancelLabel),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(dialogContext, controller.text),
              child: Text(l.saveLabel),
            ),
          ],
        ),
      );
      controller.dispose();
      if (note?.trim().isNotEmpty ?? false) {
        if (!context.mounted) return;
        await context.read<AppointmentCubit>().savePreparationNote(
          appointmentId: appointment.id,
          note: note!.trim(),
        );
      }
      return;
    }
    String? cancellationReason;
    if (status == AppointmentStatus.cancelled) {
      final controller = TextEditingController();
      cancellationReason = await showSettledDialog<String>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: Text(l.cancellationReasonTitle),
          content: TextField(
            controller: controller,
            maxLines: 3,
            maxLength: 1000,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: Text(l.cancelLabel),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(dialogContext, controller.text),
              child: Text(l.saveLabel),
            ),
          ],
        ),
      );
      controller.dispose();
      if (cancellationReason?.trim().isEmpty ?? true) return;
    }
    if (!context.mounted) return;
    await context.read<AppointmentCubit>().transition(
      appointmentId: appointment.id,
      status: status,
      cancellationReason: cancellationReason?.trim(),
    );
  }

  Future<void> _sendWhatsAppReminder(BuildContext context) async {
    final l = AppLocalizations.of(context);
    PatientCubit? patientCubit;
    try {
      patientCubit = context.read<PatientCubit>();
    } catch (_) {
      patientCubit = null;
    }
    final patient = patientCubit?.state.patients
        .where((p) => p.id == appointment.patientId)
        .firstOrNull;
    final phone = patient?.phone;
    if (phone == null || phone.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l.noPhoneForPatient),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    final clinic = context
        .read<ClinicCubit>()
        .state
        .memberships
        .where((m) => m.clinic.id == appointment.clinicId)
        .firstOrNull
        ?.clinic;
    final clinicName = (clinic != null && clinic.name.trim().isNotEmpty)
        ? clinic.name
        : l.clinicSectionTitle;

    final localStart = tz.TZDateTime.from(appointment.startsAt, location);
    final dateStr = DateFormat.yMMMMEEEEd().format(localStart);
    final timeStr = DateFormat.jm().format(localStart);

    final message = l.reminderMessageTemplate(
      appointment.patientName,
      clinicName,
      appointment.dentistName,
      dateStr,
      timeStr,
    );

    final success = await CommunicationLauncher.launchWhatsApp(
      phone: phone,
      message: message,
    );
    if (!success && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l.communicationLaunchFailed),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }
}

class _AppointmentMessage extends StatelessWidget {
  const _AppointmentMessage(this.message);
  final String message;
  @override
  Widget build(BuildContext context) => Card(
    child: Padding(padding: const EdgeInsets.all(16), child: Text(message)),
  );
}

class _DentistDirectoryMessage extends StatelessWidget {
  const _DentistDirectoryMessage({
    required this.message,
    required this.actionLabel,
    required this.onRetry,
  });

  final String message;
  final String actionLabel;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) => Card(
    child: Padding(
      padding: const EdgeInsets.all(AppSpacing.medium),
      child: Wrap(
        alignment: WrapAlignment.spaceBetween,
        crossAxisAlignment: WrapCrossAlignment.center,
        spacing: AppSpacing.medium,
        runSpacing: AppSpacing.small,
        children: [
          Text(message),
          OutlinedButton(onPressed: onRetry, child: Text(actionLabel)),
        ],
      ),
    ),
  );
}

class _AppointmentFieldGrid extends StatelessWidget {
  const _AppointmentFieldGrid({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final columns = constraints.maxWidth >= 840
          ? 3
          : constraints.maxWidth >= 560
          ? 2
          : 1;
      final width =
          (constraints.maxWidth - AppSpacing.medium * (columns - 1)) / columns;
      return Wrap(
        spacing: AppSpacing.medium,
        runSpacing: AppSpacing.medium,
        children: [
          for (final child in children) SizedBox(width: width, child: child),
        ],
      );
    },
  );
}

String _issueMessage(
  AppointmentOperationIssue issue,
  AppLocalizations l,
) => switch (issue) {
  AppointmentOperationIssue.unavailable => l.appointmentUnavailableIssue,
  AppointmentOperationIssue.forbidden => l.appointmentForbiddenIssue,
  AppointmentOperationIssue.patientOverlap => l.appointmentPatientOverlapIssue,
  AppointmentOperationIssue.dentistOverlap => l.appointmentDentistOverlapIssue,
  AppointmentOperationIssue.workingHours => l.appointmentWorkingHoursIssue,
  AppointmentOperationIssue.leave => l.appointmentLeaveIssue,
  AppointmentOperationIssue.unavailablePeriod =>
    l.appointmentUnavailablePeriodIssue,
  AppointmentOperationIssue.overrideReasonRequired =>
    l.appointmentConflictExplanation,
  AppointmentOperationIssue.invalidTransition =>
    l.appointmentInvalidTransitionIssue,
};

String _statusLabel(AppointmentStatus status, AppLocalizations l) =>
    switch (status) {
      AppointmentStatus.scheduled => l.appointmentStatusScheduled,
      AppointmentStatus.confirmed => l.appointmentStatusConfirmed,
      AppointmentStatus.inProgress => l.appointmentStatusInProgress,
      AppointmentStatus.completed => l.appointmentStatusCompleted,
      AppointmentStatus.noShow => l.appointmentStatusNoShow,
      AppointmentStatus.cancelled => l.appointmentStatusCancelled,
    };

(Color, Color, IconData) _statusStyle(
  AppointmentStatus status,
  ThemeData theme,
) => switch (status) {
  AppointmentStatus.scheduled => (
    theme.colorScheme.primary,
    theme.colorScheme.primaryContainer.withValues(alpha: 0.35),
    Icons.schedule_rounded,
  ),
  AppointmentStatus.confirmed => (
    Colors.teal.shade700,
    Colors.teal.withValues(alpha: 0.14),
    Icons.check_circle_outline_rounded,
  ),
  AppointmentStatus.inProgress => (
    Colors.deepOrange.shade700,
    Colors.deepOrange.withValues(alpha: 0.14),
    Icons.play_circle_outline_rounded,
  ),
  AppointmentStatus.completed => (
    Colors.blueGrey.shade700,
    Colors.blueGrey.withValues(alpha: 0.14),
    Icons.task_alt_rounded,
  ),
  AppointmentStatus.noShow => (
    theme.colorScheme.error,
    theme.colorScheme.errorContainer.withValues(alpha: 0.3),
    Icons.person_off_outlined,
  ),
  AppointmentStatus.cancelled => (
    theme.colorScheme.outline,
    theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.6),
    Icons.cancel_outlined,
  ),
};

class _AppointmentEmptyState extends StatelessWidget {
  const _AppointmentEmptyState({
    required this.message,
    required this.canCreate,
  });

  final String message;
  final bool canCreate;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l = AppLocalizations.of(context);
    return Card(
      elevation: 0,
      color: theme.colorScheme.surfaceContainerLow,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 36),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: theme.colorScheme.primaryContainer.withValues(alpha: 0.4),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.event_available_rounded,
                size: 36,
                color: theme.colorScheme.primary,
              ),
            ),
            const SizedBox(height: AppSpacing.medium),
            Text(
              l.emptyCalendarTitle,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 6),
            Text(
              message,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
            if (canCreate) ...[
              const SizedBox(height: AppSpacing.large),
              FilledButton.tonalIcon(
                onPressed: () => context.go('/appointments/new'),
                icon: const Icon(Icons.add, size: 18),
                label: Text(l.newAppointmentLabel),
              ),
            ],
          ],
        ),
      ),
    );
  }
}


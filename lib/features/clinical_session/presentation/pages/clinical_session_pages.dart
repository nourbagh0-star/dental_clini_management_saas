import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:timezone/data/latest.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

import '../../../../app/localization/generated/app_localizations.dart';
import '../../../../core/error/failure_message.dart';
import '../../../../core/widgets/app_dialog.dart';
import '../../../clinic/presentation/clinic_cubit.dart';
import '../../../patient/domain/patient_models.dart';
import '../../../patient/presentation/patient_cubit.dart';
import '../../../staff/domain/staff_models.dart';
import '../../../staff/presentation/staff_cubit.dart';
import '../../domain/clinical_session_models.dart';
import '../clinical_session_cubit.dart';

class ClinicalSessionsPage extends StatefulWidget {
  const ClinicalSessionsPage({
    required this.patientId,
    this.initialAppointmentId,
    super.key,
  });

  final String patientId;
  final String? initialAppointmentId;

  @override
  State<ClinicalSessionsPage> createState() => _ClinicalSessionsPageState();
}

class _ClinicalSessionsPageState extends State<ClinicalSessionsPage> {
  String? _loadedKey;
  bool _handledInitialAppointment = false;

  @override
  void initState() {
    super.initState();
    tz_data.initializeTimeZones();
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final clinicState = context.watch<ClinicCubit>().state;
    final clinic = clinicState.activeClinic;
    final roles = clinicState.activeMembership?.roles ?? const <String>{};
    final canRead = roles.any(
      (role) => role == 'owner' || role == 'dentist' || role == 'assistant',
    );
    final canCreate = roles.contains('dentist') || roles.contains('assistant');
    final patient = context
        .watch<PatientCubit>()
        .state
        .patients
        .where((item) => item.id == widget.patientId)
        .firstOrNull;
    if (!canRead || clinic == null || patient == null) {
      return Scaffold(
        appBar: AppBar(title: Text(l.visitsTitle)),
        body: Center(child: Text(l.sessionUnavailableMessage)),
      );
    }
    final loadKey = '${clinic.id}:${widget.patientId}';
    if (_loadedKey != loadKey) {
      _loadedKey = loadKey;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        context.read<ClinicalSessionCubit>().load(widget.patientId);
        context.read<StaffCubit>().load(clinic.id);
      });
    }
    final staff = context.watch<StaffCubit>().state.members;
    final dentists = staff
        .where(
          (member) =>
              member.isActive && member.roles.contains(StaffRole.dentist),
        )
        .toList(growable: false);
    return Scaffold(
      appBar: AppBar(
        title: Text(l.visitsTitle),
        leading: IconButton(
          onPressed: () => context.go('/patients/${widget.patientId}'),
          icon: const Icon(Icons.arrow_back),
        ),
      ),
      floatingActionButton: canCreate
          ? FloatingActionButton.extended(
              onPressed: () => _showCreateSession(
                context,
                patient,
                dentists,
                clinic.timeZone,
              ),
              icon: const Icon(Icons.note_add_outlined),
              label: Text(l.newSessionLabel),
            )
          : null,
      body: BlocConsumer<ClinicalSessionCubit, ClinicalSessionState>(
        listener: (context, state) {
          if (state.issue != null) {
            _showMessage(context, _issueMessage(l, state.issue!));
          }
        },
        builder: (context, state) {
          _handleInitialAppointment(
            context,
            state,
            patient,
            dentists,
            clinic.timeZone,
            canCreate,
          );
          return LayoutBuilder(
            builder: (context, constraints) {
              final list = _VisitList(state: state, timeZone: clinic.timeZone);
              final detail = state.selectedSession == null
                  ? _MessageCard(message: l.noVisitsMessage)
                  : _SessionDetail(
                      key: ValueKey(
                        '${state.selectedSession!.id}:${state.selectedSession!.revision}',
                      ),
                      session: state.selectedSession!,
                      amendments: state.amendments,
                      staff: staff,
                      timeZone: clinic.timeZone,
                      roles: roles,
                      currentMemberId: clinicState.activeMembership?.memberId,
                      mutating: state.mutating,
                    );
              final body = constraints.maxWidth >= 900
                  ? Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox(width: 340, child: list),
                        const SizedBox(width: 16),
                        Expanded(child: detail),
                      ],
                    )
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [list, const SizedBox(height: 16), detail],
                    );
              return ListView(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 88),
                children: [
                  Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 1200),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          _PatientHeader(patient: patient),
                          if (!canCreate)
                            Padding(
                              padding: const EdgeInsets.only(top: 8),
                              child: Text(l.clinicalViewOnly),
                            ),
                          const SizedBox(height: 16),
                          if (state.status ==
                                  ClinicalSessionLoadStatus.loading ||
                              state.mutating)
                            const LinearProgressIndicator(),
                          if (state.failure != null)
                            _MessageCard(
                              message: failureMessage(state.failure!, l),
                            ),
                          if (state.issue ==
                              ClinicalSessionOperationIssue.revisionConflict)
                            Card(
                              child: Padding(
                                padding: const EdgeInsets.all(16),
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.stretch,
                                  children: [
                                    Text(l.revisionConflictMessage),
                                    const SizedBox(height: 8),
                                    OutlinedButton(
                                      onPressed: () => context
                                          .read<ClinicalSessionCubit>()
                                          .load(
                                            widget.patientId,
                                            preferredSessionId:
                                                state.selectedSessionId,
                                          ),
                                      child: Text(l.reloadLatestLabel),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          body,
                        ],
                      ),
                    ),
                  ),
                ],
              );
            },
          );
        },
      ),
    );
  }

  void _handleInitialAppointment(
    BuildContext context,
    ClinicalSessionState state,
    Patient patient,
    List<StaffMember> dentists,
    String timeZone,
    bool canCreate,
  ) {
    final appointmentId = widget.initialAppointmentId;
    if (_handledInitialAppointment ||
        appointmentId == null ||
        state.status != ClinicalSessionLoadStatus.ready) {
      return;
    }
    _handledInitialAppointment = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      for (final session in state.sessions) {
        if (session.appointmentId == appointmentId) {
          context.read<ClinicalSessionCubit>().select(session.id);
          return;
        }
      }
      if (canCreate &&
          state.eligibleAppointments.any((item) => item.id == appointmentId)) {
        _showCreateSession(
          context,
          patient,
          dentists,
          timeZone,
          initialAppointmentId: appointmentId,
        );
      }
    });
  }

  Future<void> _showCreateSession(
    BuildContext context,
    Patient patient,
    List<StaffMember> dentists,
    String timeZone, {
    String? initialAppointmentId,
  }) async {
    final l = AppLocalizations.of(context);
    final state = context.read<ClinicalSessionCubit>().state;
    final usedAppointments = state.sessions
        .map((item) => item.appointmentId)
        .whereType<String>()
        .toSet();
    final appointments = state.eligibleAppointments
        .where((item) => !usedAppointments.contains(item.id))
        .toList(growable: false);
    var walkIn = initialAppointmentId == null;
    String? appointmentId = initialAppointmentId;
    String? dentistId = dentists.firstOrNull?.id;
    final location = tz.getLocation(timeZone);
    var localDate = tz.TZDateTime.now(location);
    final submitted = await showSettledDialog<bool>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text(l.selectVisitTypeTitle),
          content: SizedBox(
            width: 520,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(patient.fullName),
                  const SizedBox(height: 12),
                  SegmentedButton<bool>(
                    segments: [
                      ButtonSegment(
                        value: false,
                        label: Text(l.appointmentSessionLabel),
                        icon: const Icon(Icons.event_available_outlined),
                      ),
                      ButtonSegment(
                        value: true,
                        label: Text(l.walkInLabel),
                        icon: const Icon(Icons.directions_walk),
                      ),
                    ],
                    selected: {walkIn},
                    onSelectionChanged: (value) => setDialogState(() {
                      walkIn = value.first;
                      appointmentId = null;
                    }),
                  ),
                  const SizedBox(height: 16),
                  if (!walkIn)
                    DropdownButtonFormField<String>(
                      isExpanded: true,
                      initialValue: appointmentId,
                      decoration: InputDecoration(
                        labelText: l.chooseAppointmentLabel,
                      ),
                      items: appointments
                          .map(
                            (item) => DropdownMenuItem(
                              value: item.id,
                              child: Text(
                                '${_formatDateTime(context, item.startsAt, timeZone)}'
                                '${item.purpose == null ? '' : ' · ${item.purpose}'}',
                              ),
                            ),
                          )
                          .toList(growable: false),
                      onChanged: (value) =>
                          setDialogState(() => appointmentId = value),
                    )
                  else ...[
                    DropdownButtonFormField<String>(
                      isExpanded: true,
                      initialValue: dentistId,
                      decoration: InputDecoration(
                        labelText: l.chooseDentistLabel,
                      ),
                      items: dentists
                          .map(
                            (item) => DropdownMenuItem(
                              value: item.id,
                              child: Text(item.email),
                            ),
                          )
                          .toList(growable: false),
                      onChanged: (value) =>
                          setDialogState(() => dentistId = value),
                    ),
                    const SizedBox(height: 8),
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(l.visitDateTimeLabel),
                      subtitle: Text(
                        DateFormat.yMMMd(
                          Localizations.localeOf(context).toLanguageTag(),
                        ).add_jm().format(localDate),
                      ),
                      onTap: () async {
                        final date = await showDatePicker(
                          context: context,
                          firstDate: DateTime(2000),
                          lastDate: DateTime.now(),
                          initialDate: DateTime(
                            localDate.year,
                            localDate.month,
                            localDate.day,
                          ),
                        );
                        if (date == null || !context.mounted) return;
                        final time = await showTimePicker(
                          context: context,
                          initialTime: TimeOfDay(
                            hour: localDate.hour,
                            minute: localDate.minute,
                          ),
                        );
                        if (time == null) return;
                        setDialogState(() {
                          localDate = tz.TZDateTime(
                            location,
                            date.year,
                            date.month,
                            date.day,
                            time.hour,
                            time.minute,
                          );
                        });
                      },
                    ),
                  ],
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: Text(l.cancelLabel),
            ),
            FilledButton(
              onPressed:
                  (walkIn && dentistId != null) ||
                      (!walkIn && appointmentId != null)
                  ? () => Navigator.pop(dialogContext, true)
                  : null,
              child: Text(l.createDraftLabel),
            ),
          ],
        ),
      ),
    );
    if (submitted == true && context.mounted) {
      await context.read<ClinicalSessionCubit>().create(
        ClinicalSessionDraft(
          patientId: widget.patientId,
          appointmentId: walkIn ? null : appointmentId,
          dentistMemberId: walkIn ? dentistId : null,
          sessionDate: walkIn ? localDate.toUtc() : null,
        ),
      );
    }
  }
}

class _VisitList extends StatelessWidget {
  const _VisitList({required this.state, required this.timeZone});
  final ClinicalSessionState state;
  final String timeZone;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(l.visitsTitle, style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 8),
            if (state.status == ClinicalSessionLoadStatus.ready &&
                state.sessions.isEmpty)
              Text(l.noVisitsMessage),
            for (final session in state.sessions)
              ListTile(
                selected: session.id == state.selectedSessionId,
                leading: Icon(_statusIcon(session.status)),
                title: Text(_statusLabel(l, session.status)),
                subtitle: Text(
                  _formatDateTime(context, session.sessionDate, timeZone),
                ),
                onTap: () =>
                    context.read<ClinicalSessionCubit>().select(session.id),
              ),
            if (state.hasMore)
              TextButton(
                onPressed: state.loadingMore
                    ? null
                    : () => context.read<ClinicalSessionCubit>().loadMore(),
                child: Text(l.loadMoreLabel),
              ),
          ],
        ),
      ),
    );
  }
}

class _SessionDetail extends StatefulWidget {
  const _SessionDetail({
    required this.session,
    required this.amendments,
    required this.staff,
    required this.timeZone,
    required this.roles,
    required this.currentMemberId,
    required this.mutating,
    super.key,
  });

  final ClinicalSession session;
  final List<ClinicalSessionAmendment> amendments;
  final List<StaffMember> staff;
  final String timeZone;
  final Set<String> roles;
  final String? currentMemberId;
  final bool mutating;

  @override
  State<_SessionDetail> createState() => _SessionDetailState();
}

class _SessionDetailState extends State<_SessionDetail> {
  late final TextEditingController _notes;
  late final TextEditingController _recommendations;

  @override
  void initState() {
    super.initState();
    _notes = TextEditingController(text: widget.session.clinicalNotes);
    _recommendations = TextEditingController(
      text: widget.session.recommendations,
    );
  }

  @override
  void dispose() {
    _notes.dispose();
    _recommendations.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final session = widget.session;
    final draft = session.status == ClinicalSessionStatus.draft;
    final canEdit =
        draft &&
        (widget.roles.contains('dentist') ||
            widget.roles.contains('assistant'));
    final canFinalize =
        canEdit &&
        widget.roles.contains('dentist') &&
        widget.currentMemberId == session.dentistMemberId;
    final canAmend =
        session.status == ClinicalSessionStatus.finalized &&
        widget.roles.contains('dentist');
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Wrap(
              alignment: WrapAlignment.spaceBetween,
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: 8,
              children: [
                Text(
                  session.status == ClinicalSessionStatus.finalized
                      ? l.originalRecordTitle
                      : _statusLabel(l, session.status),
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                Chip(label: Text(_statusLabel(l, session.status))),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              '${l.sessionDateLabel}: ${_formatDateTime(context, session.sessionDate, widget.timeZone)}',
            ),
            Text(
              '${l.assignedDentistLabel}: ${_memberLabel(widget.staff, session.dentistMemberId)}',
            ),
            Text(
              session.appointmentId == null
                  ? l.walkInLabel
                  : l.linkedAppointmentLabel,
            ),
            Text(
              '${l.lastSavedLabel}: ${_formatDateTime(context, session.updatedAt, widget.timeZone)}',
            ),
            const Divider(height: 28),
            if (canEdit) ...[
              TextField(
                controller: _notes,
                maxLength: 20000,
                minLines: 5,
                maxLines: 12,
                decoration: InputDecoration(labelText: l.clinicalNotesLabel),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _recommendations,
                maxLength: 5000,
                minLines: 3,
                maxLines: 8,
                decoration: InputDecoration(labelText: l.recommendationsLabel),
              ),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  FilledButton.icon(
                    onPressed: widget.mutating ? null : _save,
                    icon: const Icon(Icons.save_outlined),
                    label: Text(l.saveDraftLabel),
                  ),
                  if (canFinalize)
                    FilledButton.tonalIcon(
                      onPressed: widget.mutating ? null : _finalize,
                      icon: const Icon(Icons.lock_outline),
                      label: Text(l.finalizeSessionLabel),
                    ),
                  TextButton(
                    onPressed: widget.mutating ? null : _markInError,
                    child: Text(l.markInErrorLabel),
                  ),
                ],
              ),
            ] else ...[
              _ReadSection(
                title: l.clinicalNotesLabel,
                body: session.clinicalNotes,
              ),
              const SizedBox(height: 16),
              _ReadSection(
                title: l.recommendationsLabel,
                body: session.recommendations,
              ),
            ],
            if (session.status == ClinicalSessionStatus.enteredInError) ...[
              const Divider(height: 28),
              Text(
                '${l.reasonLabel}: ${session.errorReason ?? ''}',
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            ],
            if (session.status == ClinicalSessionStatus.finalized) ...[
              const Divider(height: 28),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    l.amendmentsTitle,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  if (canAmend)
                    TextButton.icon(
                      onPressed: widget.mutating ? null : _addAmendment,
                      icon: const Icon(Icons.add),
                      label: Text(l.addAmendmentLabel),
                    ),
                ],
              ),
              for (final amendment in widget.amendments)
                Card.outlined(
                  child: ListTile(
                    title: Text(amendment.amendmentText),
                    subtitle: Text(
                      '${l.reasonLabel}: ${amendment.reason}\n'
                      '${_userLabel(widget.staff, amendment.amendedBy)} · '
                      '${_formatDateTime(context, amendment.amendedAt, widget.timeZone)}',
                    ),
                    isThreeLine: true,
                  ),
                ),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _save() async {
    await context.read<ClinicalSessionCubit>().saveDraft(
      sessionId: widget.session.id,
      clinicalNotes: _optional(_notes.text),
      recommendations: _optional(_recommendations.text),
      expectedRevision: widget.session.revision,
    );
  }

  Future<void> _finalize() async {
    final l = AppLocalizations.of(context);
    if (_notes.text.trim().isEmpty) {
      _showMessage(context, l.requiredField);
      return;
    }
    final saved = await context.read<ClinicalSessionCubit>().saveDraft(
      sessionId: widget.session.id,
      clinicalNotes: _optional(_notes.text),
      recommendations: _optional(_recommendations.text),
      expectedRevision: widget.session.revision,
    );
    if (!saved || !mounted) return;
    final latest = context.read<ClinicalSessionCubit>().state.selectedSession;
    if (latest == null) return;
    final approved = await showSettledDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(l.finalizeSessionLabel),
        content: Text(l.finalizeWarning),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: Text(l.cancelLabel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: Text(l.finalizeSessionLabel),
          ),
        ],
      ),
    );
    if (approved == true && mounted) {
      await context.read<ClinicalSessionCubit>().finalize(
        latest.id,
        latest.revision,
      );
    }
  }

  Future<void> _markInError() async {
    final l = AppLocalizations.of(context);
    final reason = await _textDialog(
      context,
      title: l.markInErrorLabel,
      label: l.reasonLabel,
      maxLength: 1000,
    );
    if (reason != null && mounted) {
      await context.read<ClinicalSessionCubit>().markInError(
        sessionId: widget.session.id,
        expectedRevision: widget.session.revision,
        reason: reason,
      );
    }
  }

  Future<void> _addAmendment() async {
    final l = AppLocalizations.of(context);
    final form = GlobalKey<FormState>();
    final text = TextEditingController();
    final reason = TextEditingController();
    final submitted = await showSettledDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(l.addAmendmentLabel),
        content: SizedBox(
          width: 520,
          child: Form(
            key: form,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: text,
                  maxLength: 10000,
                  maxLines: 5,
                  decoration: InputDecoration(labelText: l.amendmentTextLabel),
                  validator: (value) => value == null || value.trim().isEmpty
                      ? l.requiredField
                      : null,
                ),
                TextFormField(
                  controller: reason,
                  maxLength: 1000,
                  maxLines: 3,
                  decoration: InputDecoration(labelText: l.reasonLabel),
                  validator: (value) => value == null || value.trim().isEmpty
                      ? l.requiredField
                      : null,
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: Text(l.cancelLabel),
          ),
          FilledButton(
            onPressed: () {
              if (form.currentState?.validate() ?? false) {
                Navigator.pop(dialogContext, true);
              }
            },
            child: Text(l.addAmendmentLabel),
          ),
        ],
      ),
    );
    if (submitted == true && mounted) {
      await context.read<ClinicalSessionCubit>().addAmendment(
        sessionId: widget.session.id,
        amendmentText: text.text.trim(),
        reason: reason.text.trim(),
      );
    }
    text.dispose();
    reason.dispose();
  }
}

class _ReadSection extends StatelessWidget {
  const _ReadSection({required this.title, required this.body});
  final String title;
  final String? body;
  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(title, style: Theme.of(context).textTheme.titleMedium),
      const SizedBox(height: 4),
      SelectableText(body ?? '—'),
    ],
  );
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

class _MessageCard extends StatelessWidget {
  const _MessageCard({required this.message});
  final String message;
  @override
  Widget build(BuildContext context) => Card(
    child: Padding(padding: const EdgeInsets.all(16), child: Text(message)),
  );
}

IconData _statusIcon(ClinicalSessionStatus status) => switch (status) {
  ClinicalSessionStatus.draft => Icons.edit_note,
  ClinicalSessionStatus.finalized => Icons.verified_outlined,
  ClinicalSessionStatus.enteredInError => Icons.error_outline,
};

String _statusLabel(AppLocalizations l, ClinicalSessionStatus status) =>
    switch (status) {
      ClinicalSessionStatus.draft => l.draftStatus,
      ClinicalSessionStatus.finalized => l.finalizedStatus,
      ClinicalSessionStatus.enteredInError => l.enteredInErrorStatus,
    };

String _memberLabel(List<StaffMember> staff, String memberId) {
  for (final member in staff) {
    if (member.id == memberId) return member.email;
  }
  return '—';
}

String _userLabel(List<StaffMember> staff, String userId) {
  for (final member in staff) {
    if (member.userId == userId) return member.email;
  }
  return '—';
}

String _formatDateTime(BuildContext context, DateTime value, String timeZone) {
  final local = tz.TZDateTime.from(value, tz.getLocation(timeZone));
  return DateFormat.yMMMd(
    Localizations.localeOf(context).toLanguageTag(),
  ).add_jm().format(local);
}

String? _optional(String value) {
  final normalized = value.trim();
  return normalized.isEmpty ? null : normalized;
}

Future<String?> _textDialog(
  BuildContext context, {
  required String title,
  required String label,
  required int maxLength,
}) async {
  final form = GlobalKey<FormState>();
  final controller = TextEditingController();
  final result = await showSettledDialog<String>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: Text(title),
      content: Form(
        key: form,
        child: TextFormField(
          controller: controller,
          maxLength: maxLength,
          maxLines: 4,
          decoration: InputDecoration(labelText: label),
          validator: (value) => value == null || value.trim().isEmpty
              ? AppLocalizations.of(context).requiredField
              : null,
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(dialogContext),
          child: Text(AppLocalizations.of(context).cancelLabel),
        ),
        FilledButton(
          onPressed: () {
            if (form.currentState?.validate() ?? false) {
              Navigator.pop(dialogContext, controller.text.trim());
            }
          },
          child: Text(AppLocalizations.of(context).saveDraftLabel),
        ),
      ],
    ),
  );
  controller.dispose();
  return result;
}

void _showMessage(BuildContext context, String message) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(content: Text(message)));
}

String _issueMessage(AppLocalizations l, ClinicalSessionOperationIssue issue) =>
    switch (issue) {
      ClinicalSessionOperationIssue.revisionConflict =>
        l.revisionConflictMessage,
      ClinicalSessionOperationIssue.unavailable => l.sessionUnavailableMessage,
      ClinicalSessionOperationIssue.notesRequired => l.requiredField,
      _ => l.clinicalActionFailedMessage,
    };

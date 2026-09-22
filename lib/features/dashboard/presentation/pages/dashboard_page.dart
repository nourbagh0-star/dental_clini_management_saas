import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart' hide TextDirection;
import 'package:timezone/data/latest.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

import '../../../../app/localization/generated/app_localizations.dart';
import '../../../../app/theme/app_theme.dart';
import '../../../../core/error/failure_message.dart';
import '../../../../core/value/money.dart';
import '../../../appointment/domain/appointment_models.dart';
import '../../../clinic/domain/clinic_models.dart';
import '../../../clinic/presentation/clinic_cubit.dart';
import '../../domain/dashboard_models.dart';
import '../dashboard_cubit.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  @override
  void initState() {
    super.initState();
    tz_data.initializeTimeZones();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadActiveClinic());
  }

  void _loadActiveClinic() {
    if (!mounted) return;
    final clinicId = context.read<ClinicCubit>().state.activeClinicId;
    if (clinicId != null) context.read<DashboardCubit>().load(clinicId);
  }

  @override
  Widget build(BuildContext context) => BlocListener<ClinicCubit, ClinicState>(
    listenWhen: (previous, current) =>
        previous.activeClinicId != current.activeClinicId,
    listener: (context, state) {
      final clinicId = state.activeClinicId;
      if (clinicId == null) {
        context.read<DashboardCubit>().clear();
        context.go('/clinic-gate');
      } else {
        context.read<DashboardCubit>().load(clinicId);
      }
    },
    child: BlocBuilder<ClinicCubit, ClinicState>(
      builder: (context, clinicState) {
        final clinic = clinicState.activeClinic;
        if (clinic == null) {
          return Scaffold(
            appBar: AppBar(
              title: Text(AppLocalizations.of(context).dashboardTitle),
            ),
            body: _NoClinic(onChoose: () => context.go('/clinic-gate')),
          );
        }
        return BlocConsumer<DashboardCubit, DashboardState>(
          listenWhen: (previous, current) =>
              previous.refreshFailure != current.refreshFailure &&
              current.refreshFailure != null,
          listener: (context, state) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  AppLocalizations.of(context).dashboardRefreshFailed,
                ),
              ),
            );
          },
          builder: (context, state) => Scaffold(
            appBar: AppBar(
              title: Text(AppLocalizations.of(context).dashboardTitle),
              actions: [
                if (clinicState.activeMembership?.isOwner ?? false)
                  IconButton(
                    tooltip: AppLocalizations.of(context).auditOpen,
                    onPressed: () => context.go('/audit'),
                    icon: const Icon(Icons.policy_outlined),
                  ),
                if (clinicState.memberships.length > 1)
                  IconButton(
                    tooltip: AppLocalizations.of(context).switchClinicLabel,
                    onPressed: () => context.go('/clinics/select'),
                    icon: const Icon(Icons.swap_horiz),
                  ),
                IconButton(
                  tooltip: AppLocalizations.of(context).dashboardRefresh,
                  onPressed: state.snapshot == null || state.refreshing
                      ? null
                      : context.read<DashboardCubit>().refresh,
                  icon: const Icon(Icons.refresh),
                ),
              ],
            ),
            body: _body(context, clinic, state),
          ),
        );
      },
    ),
  );

  Widget _body(BuildContext context, Clinic clinic, DashboardState state) {
    if (state.status == DashboardLoadStatus.loading ||
        state.status == DashboardLoadStatus.initial) {
      return const _DashboardLoading();
    }
    if (state.status == DashboardLoadStatus.failure || state.snapshot == null) {
      final l10n = AppLocalizations.of(context);
      return Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 480),
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.large),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.dashboard_outlined, size: 48),
                const SizedBox(height: AppSpacing.medium),
                Text(
                  state.failure == null
                      ? l10n.dashboardUnavailable
                      : failureMessage(state.failure!, l10n),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: AppSpacing.medium),
                FilledButton.icon(
                  onPressed: () =>
                      context.read<DashboardCubit>().load(clinic.id),
                  icon: const Icon(Icons.refresh),
                  label: Text(l10n.retryLabel),
                ),
              ],
            ),
          ),
        ),
      );
    }
    return _DashboardContent(
      clinic: clinic,
      snapshot: state.snapshot!,
      refreshing: state.refreshing,
    );
  }
}

class _NoClinic extends StatelessWidget {
  const _NoClinic({required this.onChoose});

  final VoidCallback onChoose;

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(AppSpacing.large),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            AppLocalizations.of(context).dashboardNoActiveClinic,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSpacing.medium),
          FilledButton(
            onPressed: onChoose,
            child: Text(AppLocalizations.of(context).selectClinicTitle),
          ),
        ],
      ),
    ),
  );
}

class _DashboardLoading extends StatelessWidget {
  const _DashboardLoading();

  @override
  Widget build(BuildContext context) => ListView(
    padding: const EdgeInsets.all(AppSpacing.large),
    children: const [
      LinearProgressIndicator(),
      SizedBox(height: AppSpacing.large),
      _LoadingCard(height: 120),
      SizedBox(height: AppSpacing.medium),
      _LoadingCard(height: 120),
      SizedBox(height: AppSpacing.large),
      _LoadingCard(height: 260),
    ],
  );
}

class _LoadingCard extends StatelessWidget {
  const _LoadingCard({required this.height});

  final double height;

  @override
  Widget build(BuildContext context) => ExcludeSemantics(
    child: Card(child: SizedBox(height: height)),
  );
}

class _DashboardContent extends StatelessWidget {
  const _DashboardContent({
    required this.clinic,
    required this.snapshot,
    required this.refreshing,
  });

  final Clinic clinic;
  final DashboardSnapshot snapshot;
  final bool refreshing;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final locale = Localizations.localeOf(context).toLanguageTag();
    final location = tz.getLocation(snapshot.clinicTimeZone);
    final generated = tz.TZDateTime.from(snapshot.generatedAt, location);
    final inProgressAppt = snapshot.todayAppointments.items
        .where((a) => a.status == AppointmentStatus.inProgress)
        .firstOrNull;
    final nextUpcomingAppt = inProgressAppt != null
        ? null
        : snapshot.todayAppointments.items
            .where((a) =>
                a.status == AppointmentStatus.scheduled ||
                a.status == AppointmentStatus.confirmed)
            .firstOrNull;
    final featuredAppt = inProgressAppt ?? nextUpcomingAppt;
    final isInChair = inProgressAppt != null;
    return RefreshIndicator(
      onRefresh: context.read<DashboardCubit>().refresh,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(AppSpacing.large),
        children: [
          Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1200),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    clinic.name,
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: AppSpacing.small),
                  Wrap(
                    spacing: AppSpacing.medium,
                    runSpacing: AppSpacing.small,
                    children: [
                      Text(l10n.dashboardTimeZone(snapshot.clinicTimeZone)),
                      Text(
                        l10n.dashboardLastUpdated(
                          DateFormat.yMMMd(locale).add_jm().format(generated),
                        ),
                      ),
                    ],
                  ),
                  if (refreshing) ...[
                    const SizedBox(height: AppSpacing.small),
                    const LinearProgressIndicator(),
                  ],
                  if (featuredAppt != null) ...[
                    const SizedBox(height: AppSpacing.large),
                    _InChairOrNextHeroCard(
                      appointment: featuredAppt,
                      timeZone: snapshot.clinicTimeZone,
                      isInChair: isInChair,
                    ),
                  ],
                  const SizedBox(height: AppSpacing.large),
                  _MetricGrid(snapshot: snapshot),
                  const SizedBox(height: AppSpacing.large),
                  LayoutBuilder(
                    builder: (context, constraints) {
                      final today = _AppointmentPanel(
                        title: l10n.dashboardTodayAppointments,
                        subtitle: DateFormat.yMMMMd(locale).format(
                          tz.TZDateTime.from(
                            snapshot.period.todayStart,
                            location,
                          ),
                        ),
                        section: snapshot.todayAppointments,
                        timeZone: snapshot.clinicTimeZone,
                        emptyMessage: l10n.dashboardNoTodayAppointments,
                        enableFilter: true,
                      );
                      final upcoming = _AppointmentPanel(
                        title: l10n.dashboardUpcomingAppointments,
                        subtitle: l10n.dashboardNextSevenDays,
                        section: snapshot.upcomingAppointments,
                        timeZone: snapshot.clinicTimeZone,
                        emptyMessage: l10n.dashboardNoUpcomingAppointments,
                      );
                      if (constraints.maxWidth > 900) {
                        return Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(child: today),
                            const SizedBox(width: AppSpacing.medium),
                            Expanded(child: upcoming),
                          ],
                        );
                      }
                      return Column(
                        children: [
                          today,
                          const SizedBox(height: AppSpacing.medium),
                          upcoming,
                        ],
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MetricGrid extends StatelessWidget {
  const _MetricGrid({required this.snapshot});

  final DashboardSnapshot snapshot;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final metrics = snapshot.metrics;
    final cards = <Widget>[
      _MetricCard(
        icon: Icons.people_outline,
        label: l10n.dashboardActivePatients,
        value: '${metrics.totalPatients}',
        actionLabel: l10n.dashboardOpenPatients,
        onTap: () => context.go('/patients'),
      ),
      _MetricCard(
        icon: Icons.date_range_outlined,
        label: l10n.dashboardAppointmentsThisWeek,
        value: '${metrics.appointmentsThisWeek}',
        actionLabel: l10n.dashboardViewAllAppointments,
        onTap: () => context.go('/appointments'),
      ),
      if (metrics.completedTreatmentsThisMonth case final completed?)
        _MetricCard(
          icon: Icons.task_alt,
          label: l10n.dashboardCompletedThisMonth,
          value: '$completed',
          actionLabel: l10n.dashboardOpenTreatments,
          onTap: () => context.go('/procedures'),
        ),
      if (metrics.financial case final financial?)
        _MetricCard(
          icon: Icons.account_balance_wallet_outlined,
          label: l10n.dashboardOutstandingPayments,
          value: _money(
            context,
            financial.outstandingAmount,
            financial.currencyCode,
          ),
          detail: l10n.dashboardOutstandingInvoices(
            financial.outstandingInvoiceCount,
          ),
          actionLabel: l10n.dashboardOpenBilling,
          onTap: () => context.go('/billing'),
        ),
    ];
    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth > 900
            ? 3
            : constraints.maxWidth >= 520
            ? 2
            : 1;
        final width =
            (constraints.maxWidth - AppSpacing.medium * (columns - 1)) /
            columns;
        return Wrap(
          spacing: AppSpacing.medium,
          runSpacing: AppSpacing.medium,
          children: [
            for (final card in cards) SizedBox(width: width, child: card),
          ],
        );
      },
    );
  }

  String _money(BuildContext context, Money amount, String currency) {
    final locale = Localizations.localeOf(context).toLanguageTag();
    return NumberFormat.currency(
      locale: locale,
      name: currency,
      symbol: '$currency ',
      decimalDigits: 2,
    ).format(amount.minorUnits / 100);
  }
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.actionLabel,
    required this.onTap,
    this.detail,
  });

  final IconData icon;
  final String label;
  final String value;
  final String? detail;
  final String actionLabel;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Semantics(
    button: true,
    label: '$label: $value${detail == null ? '' : '. $detail'}',
    child: Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(AppSpacing.radius),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.medium),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon),
              const SizedBox(height: AppSpacing.medium),
              Text(label, style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: AppSpacing.small),
              Directionality(
                textDirection: TextDirection.ltr,
                child: Text(
                  value,
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
              ),
              if (detail != null) ...[
                const SizedBox(height: AppSpacing.small),
                Text(detail!),
              ],
              const SizedBox(height: AppSpacing.small),
              Text(
                actionLabel,
                style: TextStyle(color: Theme.of(context).colorScheme.primary),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}

class _InChairOrNextHeroCard extends StatelessWidget {
  const _InChairOrNextHeroCard({
    required this.appointment,
    required this.timeZone,
    required this.isInChair,
  });

  final DashboardAppointmentPreview appointment;
  final String timeZone;
  final bool isInChair;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);
    final locale = Localizations.localeOf(context).toLanguageTag();
    final local = tz.TZDateTime.from(
      appointment.startsAt,
      tz.getLocation(timeZone),
    );
    final initial = appointment.patientName.trim().isNotEmpty
        ? appointment.patientName.trim().characters.first.toUpperCase()
        : '?';

    final borderColor = isInChair
        ? theme.colorScheme.primary
        : theme.colorScheme.outlineVariant.withValues(alpha: 0.6);
    final bgColor = isInChair
        ? theme.colorScheme.primaryContainer.withValues(alpha: 0.15)
        : theme.colorScheme.surfaceContainerLow;

    return Container(
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor, width: isInChair ? 1.5 : 1),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.medium),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: isInChair
                        ? const Color(0xFFFFF3E0)
                        : theme.colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        isInChair
                            ? Icons.play_circle_filled_rounded
                            : Icons.schedule_rounded,
                        size: 16,
                        color: isInChair
                            ? const Color(0xFFE65100)
                            : theme.colorScheme.primary,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        isInChair ? l10n.inChairPatient : l10n.nextPatient,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: isInChair
                              ? const Color(0xFFE65100)
                              : theme.colorScheme.primary,
                        ),
                      ),
                    ],
                  ),
                ),
                const Spacer(),
                Text(
                  DateFormat.jm(locale).format(local),
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.primary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                CircleAvatar(
                  radius: 22,
                  backgroundColor: theme.colorScheme.primaryContainer,
                  foregroundColor: theme.colorScheme.onPrimaryContainer,
                  child: Text(
                    initial,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        appointment.patientName,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '#${appointment.patientNumber} · ${appointment.dentistLabel}',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                if (isInChair)
                  FilledButton.icon(
                    onPressed: () {
                      unawaited(HapticFeedback.lightImpact());
                      context.go(
                        '/patients/${appointment.patientId}/visits?appointmentId=${appointment.id}',
                      );
                    },
                    icon: const Icon(Icons.medical_services_outlined, size: 18),
                    label: Text(l10n.openClinicalSession),
                  ),
                OutlinedButton.icon(
                  onPressed: () {
                    unawaited(HapticFeedback.lightImpact());
                    context.go('/patients/${appointment.patientId}');
                  },
                  icon: const Icon(Icons.person_outline_rounded, size: 18),
                  label: Text(l10n.patientProfileTitle),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _AppointmentPanel extends StatefulWidget {
  const _AppointmentPanel({
    required this.title,
    required this.subtitle,
    required this.section,
    required this.timeZone,
    required this.emptyMessage,
    this.enableFilter = false,
  });

  final String title;
  final String subtitle;
  final DashboardAppointmentSection section;
  final String timeZone;
  final String emptyMessage;
  final bool enableFilter;

  @override
  State<_AppointmentPanel> createState() => _AppointmentPanelState();
}

class _AppointmentPanelState extends State<_AppointmentPanel> {
  AppointmentStatus? _statusFilter;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final items = _statusFilter == null
        ? widget.section.items
        : widget.section.items
            .where((item) => item.status == _statusFilter)
            .toList(growable: false);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.medium),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(widget.title, style: Theme.of(context).textTheme.titleLarge),
                      const SizedBox(height: 4),
                      Text('${widget.subtitle} · ${widget.section.totalCount}'),
                    ],
                  ),
                ),
              ],
            ),
            if (widget.enableFilter && widget.section.items.isNotEmpty) ...[
              const SizedBox(height: AppSpacing.small),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    FilterChip(
                      label: Text(l10n.filterAll),
                      selected: _statusFilter == null,
                      onSelected: (_) => setState(() => _statusFilter = null),
                    ),
                    const SizedBox(width: 8),
                    FilterChip(
                      label: Text(l10n.filterScheduled),
                      selected: _statusFilter == AppointmentStatus.scheduled,
                      onSelected: (val) => setState(() => _statusFilter = val ? AppointmentStatus.scheduled : null),
                    ),
                    const SizedBox(width: 8),
                    FilterChip(
                      label: Text(l10n.filterConfirmed),
                      selected: _statusFilter == AppointmentStatus.confirmed,
                      onSelected: (val) => setState(() => _statusFilter = val ? AppointmentStatus.confirmed : null),
                    ),
                    const SizedBox(width: 8),
                    FilterChip(
                      label: Text(l10n.filterInProgress),
                      selected: _statusFilter == AppointmentStatus.inProgress,
                      onSelected: (val) => setState(() => _statusFilter = val ? AppointmentStatus.inProgress : null),
                    ),
                    const SizedBox(width: 8),
                    FilterChip(
                      label: Text(l10n.filterCompleted),
                      selected: _statusFilter == AppointmentStatus.completed,
                      onSelected: (val) => setState(() => _statusFilter = val ? AppointmentStatus.completed : null),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: AppSpacing.medium),
            if (items.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: AppSpacing.large),
                child: Text(widget.emptyMessage, textAlign: TextAlign.center),
              )
            else
              for (final appointment in items)
                _AppointmentRow(appointment: appointment, timeZone: widget.timeZone),
            const SizedBox(height: AppSpacing.small),
            TextButton.icon(
              onPressed: () => context.go('/appointments'),
              icon: const Icon(Icons.arrow_forward),
              label: Text(l10n.dashboardViewAllAppointments),
            ),
          ],
        ),
      ),
    );
  }
}

class _AppointmentRow extends StatelessWidget {
  const _AppointmentRow({required this.appointment, required this.timeZone});

  final DashboardAppointmentPreview appointment;
  final String timeZone;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final locale = Localizations.localeOf(context).toLanguageTag();
    final local = tz.TZDateTime.from(
      appointment.startsAt,
      tz.getLocation(timeZone),
    );
    final status = _status(AppLocalizations.of(context), appointment.status);
    final initial = appointment.patientName.trim().isNotEmpty
        ? appointment.patientName.trim().characters.first.toUpperCase()
        : '?';

    final (statusBg, statusFg, statusIcon) = switch (appointment.status) {
      AppointmentStatus.scheduled => (
          theme.colorScheme.primaryContainer.withValues(alpha: 0.6),
          theme.colorScheme.primary,
          Icons.schedule_rounded,
        ),
      AppointmentStatus.confirmed => (
          const Color(0xFFE8F5E9),
          const Color(0xFF2E7D32),
          Icons.check_circle_outline_rounded,
        ),
      AppointmentStatus.inProgress => (
          const Color(0xFFFFF3E0),
          const Color(0xFFE65100),
          Icons.play_circle_outline_rounded,
        ),
      AppointmentStatus.completed => (
          theme.colorScheme.surfaceContainerHighest,
          theme.colorScheme.onSurfaceVariant,
          Icons.task_alt_rounded,
        ),
      AppointmentStatus.cancelled => (
          theme.colorScheme.surfaceContainerLow,
          theme.colorScheme.outline,
          Icons.cancel_outlined,
        ),
      AppointmentStatus.noShow => (
          theme.colorScheme.errorContainer,
          theme.colorScheme.error,
          Icons.person_off_outlined,
        ),
    };

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: theme.colorScheme.outlineVariant.withValues(alpha: 0.4),
        ),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        leading: CircleAvatar(
          backgroundColor: theme.colorScheme.primaryContainer,
          foregroundColor: theme.colorScheme.onPrimaryContainer,
          child: Text(
            initial,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
        title: Text(
          appointment.patientName,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Text(
          '${DateFormat.jm(locale).format(local)} · ${appointment.patientNumber} · ${appointment.dentistLabel}',
        ),
        trailing: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: statusBg,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(statusIcon, size: 14, color: statusFg),
              const SizedBox(width: 4),
              Text(
                status,
                style: TextStyle(
                  color: statusFg,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
        onTap: () {
          unawaited(HapticFeedback.lightImpact());
          context.go('/patients/${appointment.patientId}');
        },
      ),
    );
  }

  String _status(AppLocalizations l10n, AppointmentStatus status) =>
      switch (status) {
        AppointmentStatus.scheduled => l10n.appointmentStatusScheduled,
        AppointmentStatus.confirmed => l10n.appointmentStatusConfirmed,
        AppointmentStatus.inProgress => l10n.appointmentStatusInProgress,
        AppointmentStatus.completed => l10n.appointmentStatusCompleted,
        AppointmentStatus.cancelled => l10n.appointmentStatusCancelled,
        AppointmentStatus.noShow => l10n.appointmentStatusNoShow,
      };
}

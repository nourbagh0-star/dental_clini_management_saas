import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:timezone/data/latest.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

import '../../../../app/localization/generated/app_localizations.dart';
import '../../../../app/theme/app_theme.dart';
import '../../../../core/error/failure_message.dart';
import '../../../clinic/domain/clinic_models.dart';
import '../../../clinic/presentation/clinic_cubit.dart';
import '../../domain/audit_models.dart';
import '../audit_cubit.dart';

class AuditLogPage extends StatefulWidget {
  const AuditLogPage({super.key});

  @override
  State<AuditLogPage> createState() => _AuditLogPageState();
}

class _AuditLogPageState extends State<AuditLogPage> {
  @override
  void initState() {
    super.initState();
    tz_data.initializeTimeZones();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  AuditFilter _defaultFilter(Clinic clinic) {
    final now = tz.TZDateTime.now(tz.getLocation(clinic.timeZone));
    final today = DateTime(now.year, now.month, now.day);
    return AuditFilter(
      fromDate: today.subtract(const Duration(days: 29)),
      toDateExclusive: today.add(const Duration(days: 1)),
    );
  }

  void _load() {
    if (!mounted) return;
    final clinicState = context.read<ClinicCubit>().state;
    final clinic = clinicState.activeClinic;
    if (clinic != null && (clinicState.activeMembership?.isOwner ?? false)) {
      context.read<AuditCubit>().load(clinic.id, _defaultFilter(clinic));
    }
  }

  @override
  Widget build(BuildContext context) => BlocListener<ClinicCubit, ClinicState>(
    listenWhen: (before, after) =>
        before.activeClinicId != after.activeClinicId ||
        before.activeMembership?.roles != after.activeMembership?.roles,
    listener: (context, state) {
      context.read<AuditCubit>().clear();
      final clinic = state.activeClinic;
      if (clinic != null && (state.activeMembership?.isOwner ?? false)) {
        context.read<AuditCubit>().load(clinic.id, _defaultFilter(clinic));
      }
    },
    child: BlocBuilder<ClinicCubit, ClinicState>(
      builder: (context, clinicState) {
        final l = AppLocalizations.of(context);
        final clinic = clinicState.activeClinic;
        final isOwner = clinicState.activeMembership?.isOwner ?? false;
        return Scaffold(
          appBar: AppBar(
            title: Text(l.auditTitle),
            leading: IconButton(
              onPressed: () {
                if (Navigator.of(context).canPop()) {
                  Navigator.of(context).pop();
                } else {
                  context.go('/dashboard');
                }
              },
              icon: const Icon(Icons.arrow_back),
            ),
            actions: [
              if (clinicState.memberships.length > 1)
                IconButton(
                  tooltip: l.switchClinicLabel,
                  onPressed: () => context.go('/clinics/select'),
                  icon: const Icon(Icons.swap_horiz),
                ),
              if (clinic != null && isOwner)
                BlocBuilder<AuditCubit, AuditState>(
                  builder: (context, state) => IconButton(
                    tooltip: l.auditRefresh,
                    onPressed: state.page == null || state.refreshing
                        ? null
                        : context.read<AuditCubit>().refresh,
                    icon: const Icon(Icons.refresh),
                  ),
                ),
            ],
          ),
          body: clinic == null
              ? Center(child: Text(l.dashboardNoActiveClinic))
              : !isOwner
              ? _OwnerOnly(message: l.auditOwnerOnly)
              : _AuditBody(clinic: clinic),
        );
      },
    ),
  );
}

class _OwnerOnly extends StatelessWidget {
  const _OwnerOnly({required this.message});
  final String message;

  @override
  Widget build(BuildContext context) => Center(
    child: ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 460),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.large),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.lock_outline, size: 48),
            const SizedBox(height: AppSpacing.medium),
            Text(message, textAlign: TextAlign.center),
            const SizedBox(height: AppSpacing.medium),
            FilledButton(
              onPressed: () => context.go('/dashboard'),
              child: Text(AppLocalizations.of(context).dashboardTitle),
            ),
          ],
        ),
      ),
    ),
  );
}

class _AuditBody extends StatelessWidget {
  const _AuditBody({required this.clinic});
  final Clinic clinic;

  @override
  Widget build(BuildContext context) => BlocConsumer<AuditCubit, AuditState>(
    listenWhen: (before, after) =>
        before.secondaryFailure != after.secondaryFailure &&
        after.secondaryFailure != null,
    listener: (context, state) => ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(AppLocalizations.of(context).auditRefreshFailed)),
    ),
    builder: (context, state) {
      if (state.status == AuditLoadStatus.initial ||
          state.status == AuditLoadStatus.loading) {
        return const Center(child: CircularProgressIndicator());
      }
      if (state.status == AuditLoadStatus.failure || state.page == null) {
        final l = AppLocalizations.of(context);
        return Center(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.large),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.shield_outlined, size: 48),
                const SizedBox(height: AppSpacing.medium),
                Text(
                  state.failure == null
                      ? l.auditUnavailable
                      : failureMessage(state.failure!, l),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: AppSpacing.medium),
                FilledButton.icon(
                  onPressed: () => context.read<AuditCubit>().load(
                    clinic.id,
                    state.filter ?? _fallbackFilter(),
                  ),
                  icon: const Icon(Icons.refresh),
                  label: Text(l.retryLabel),
                ),
              ],
            ),
          ),
        );
      }
      return _AuditResults(clinic: clinic, state: state);
    },
  );

  AuditFilter _fallbackFilter() {
    final today = DateTime.now();
    return AuditFilter(
      fromDate: DateTime(
        today.year,
        today.month,
        today.day,
      ).subtract(const Duration(days: 29)),
      toDateExclusive: DateTime(today.year, today.month, today.day + 1),
    );
  }
}

class _AuditResults extends StatelessWidget {
  const _AuditResults({required this.clinic, required this.state});

  final Clinic clinic;
  final AuditState state;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final page = state.page!;
    final filter = state.filter!;
    final locale = Localizations.localeOf(context).toLanguageTag();
    final shownTo = filter.toDateExclusive.subtract(const Duration(days: 1));
    return RefreshIndicator(
      onRefresh: context.read<AuditCubit>().refresh,
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
                  Text(
                    l.auditShowingRange(
                      DateFormat.yMMMd(locale).format(filter.fromDate),
                      DateFormat.yMMMd(locale).format(shownTo),
                      page.clinicTimeZone,
                    ),
                  ),
                  if (state.refreshing) ...[
                    const SizedBox(height: AppSpacing.small),
                    const LinearProgressIndicator(),
                  ],
                  const SizedBox(height: AppSpacing.medium),
                  _FilterBar(filter: filter, page: page),
                  const SizedBox(height: AppSpacing.medium),
                  if (page.items.isEmpty)
                    _EmptyAudit(filtered: filter.appliedCount > 0)
                  else
                    LayoutBuilder(
                      builder: (context, constraints) =>
                          constraints.maxWidth >= 760
                          ? _AuditTable(
                              items: page.items,
                              timeZone: page.clinicTimeZone,
                            )
                          : _AuditCards(
                              items: page.items,
                              timeZone: page.clinicTimeZone,
                            ),
                    ),
                  if (page.hasMore) ...[
                    const SizedBox(height: AppSpacing.medium),
                    Center(
                      child: FilledButton.tonalIcon(
                        onPressed: state.loadingMore
                            ? null
                            : context.read<AuditCubit>().loadMore,
                        icon: state.loadingMore
                            ? const SizedBox.square(
                                dimension: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : const Icon(Icons.expand_more),
                        label: Text(l.auditLoadMore),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _FilterBar extends StatelessWidget {
  const _FilterBar({required this.filter, required this.page});

  final AuditFilter filter;
  final AuditPage page;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return Wrap(
      spacing: AppSpacing.small,
      runSpacing: AppSpacing.small,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        FilledButton.tonalIcon(
          onPressed: () => _openFilters(context),
          icon: const Icon(Icons.filter_list),
          label: Text(
            filter.appliedCount == 0
                ? l.auditFilters
                : '${l.auditFilters} (${filter.appliedCount})',
          ),
        ),
        if (filter.appliedCount > 0)
          TextButton(
            onPressed: () => context.read<AuditCubit>().applyFilter(
              AuditFilter(
                fromDate: filter.fromDate,
                toDateExclusive: filter.toDateExclusive,
              ),
            ),
            child: Text(l.auditClearFilters),
          ),
      ],
    );
  }

  Future<void> _openFilters(BuildContext context) async {
    final next = await showModalBottomSheet<AuditFilter>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => _AuditFilterSheet(filter: filter, page: page),
    );
    if (next != null && context.mounted) {
      await context.read<AuditCubit>().applyFilter(next);
    }
  }
}

class _AuditFilterSheet extends StatefulWidget {
  const _AuditFilterSheet({required this.filter, required this.page});
  final AuditFilter filter;
  final AuditPage page;

  @override
  State<_AuditFilterSheet> createState() => _AuditFilterSheetState();
}

class _AuditFilterSheetState extends State<_AuditFilterSheet> {
  late DateTimeRange _range;
  String? _actor;
  AuditCategory? _category;
  String? _eventType;
  String? _subjectType;

  @override
  void initState() {
    super.initState();
    _range = DateTimeRange(
      start: widget.filter.fromDate,
      end: widget.filter.toDateExclusive.subtract(const Duration(days: 1)),
    );
    _actor = widget.filter.actorUserId;
    _category = widget.filter.category;
    _eventType = widget.filter.eventType;
    _subjectType = widget.filter.subjectType;
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final locale = Localizations.localeOf(context).toLanguageTag();
    final eventTypes =
        widget.page.items.map((e) => e.eventType).toSet().toList()..sort();
    final subjectTypes =
        widget.page.items.map((e) => e.subjectType).toSet().toList()..sort();
    return Padding(
      padding: EdgeInsets.fromLTRB(
        AppSpacing.large,
        AppSpacing.large,
        AppSpacing.large,
        MediaQuery.viewInsetsOf(context).bottom + AppSpacing.large,
      ),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              l.auditFilters,
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: AppSpacing.medium),
            OutlinedButton.icon(
              onPressed: _pickRange,
              icon: const Icon(Icons.date_range),
              label: Text(
                '${DateFormat.yMMMd(locale).format(_range.start)} – '
                '${DateFormat.yMMMd(locale).format(_range.end)}',
              ),
            ),
            const SizedBox(height: AppSpacing.medium),
            DropdownButtonFormField<String>(
              isExpanded: true,
              initialValue: _actor,
              decoration: InputDecoration(labelText: l.auditEmployee),
              items: [
                DropdownMenuItem(value: null, child: Text(l.auditAllEmployees)),
                for (final actor in widget.page.actors)
                  DropdownMenuItem(
                    value: actor.userId,
                    child: Text(actor.email),
                  ),
              ],
              onChanged: (value) => setState(() => _actor = value),
            ),
            const SizedBox(height: AppSpacing.medium),
            DropdownButtonFormField<AuditCategory>(
              isExpanded: true,
              initialValue: _category,
              decoration: InputDecoration(labelText: l.auditCategory),
              items: [
                DropdownMenuItem(
                  value: null,
                  child: Text(l.auditAllCategories),
                ),
                for (final category in AuditCategory.values)
                  DropdownMenuItem(
                    value: category,
                    child: Text(_categoryLabel(l, category)),
                  ),
              ],
              onChanged: (value) => setState(() => _category = value),
            ),
            if (eventTypes.isNotEmpty) ...[
              const SizedBox(height: AppSpacing.medium),
              DropdownButtonFormField<String>(
                isExpanded: true,
                initialValue: _eventType,
                decoration: InputDecoration(labelText: l.auditAction),
                items: [
                  DropdownMenuItem(
                    value: null,
                    child: Text(l.auditOtherAction),
                  ),
                  for (final value in eventTypes)
                    DropdownMenuItem(
                      value: value,
                      child: Text(value.replaceAll('_', ' ')),
                    ),
                ],
                onChanged: (value) => setState(() => _eventType = value),
              ),
            ],
            if (subjectTypes.isNotEmpty) ...[
              const SizedBox(height: AppSpacing.medium),
              DropdownButtonFormField<String>(
                isExpanded: true,
                initialValue: _subjectType,
                decoration: InputDecoration(labelText: l.auditEntityType),
                items: [
                  DropdownMenuItem(
                    value: null,
                    child: Text(l.auditAllEntities),
                  ),
                  for (final value in subjectTypes)
                    DropdownMenuItem(
                      value: value,
                      child: Text(value.replaceAll('_', ' ')),
                    ),
                ],
                onChanged: (value) => setState(() => _subjectType = value),
              ),
            ],
            const SizedBox(height: AppSpacing.large),
            FilledButton(
              onPressed: () => Navigator.pop(
                context,
                AuditFilter(
                  fromDate: _range.start,
                  toDateExclusive: _range.end.add(const Duration(days: 1)),
                  actorUserId: _actor,
                  category: _category,
                  eventType: _eventType,
                  subjectType: _subjectType,
                ),
              ),
              child: Text(l.auditApplyFilters),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickRange() async {
    final next = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 1)),
      initialDateRange: _range,
    );
    if (next == null) return;
    final days = next.end.difference(next.start).inDays + 1;
    if (days <= 90) setState(() => _range = next);
  }
}

class _AuditTable extends StatelessWidget {
  const _AuditTable({required this.items, required this.timeZone});
  final List<AuditEvent> items;
  final String timeZone;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return Card(
      clipBehavior: Clip.antiAlias,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: DataTable(
          columns: [
            DataColumn(label: Text(l.auditOccurredAt)),
            DataColumn(label: Text(l.auditEmployee)),
            DataColumn(label: Text(l.auditCategory)),
            DataColumn(label: Text(l.auditAction)),
            DataColumn(label: Text(l.auditEntity)),
          ],
          rows: [
            for (final event in items)
              DataRow(
                onSelectChanged: (_) => _showDetails(context, event, timeZone),
                cells: [
                  DataCell(Text(_time(context, event.occurredAt, timeZone))),
                  DataCell(Text(event.actorEmail ?? l.auditFormerActor)),
                  DataCell(Text(_categoryLabel(l, event.category))),
                  DataCell(Text(_actionLabel(l, event.category))),
                  DataCell(Text(event.subjectType.replaceAll('_', ' '))),
                ],
              ),
          ],
        ),
      ),
    );
  }
}

class _AuditCards extends StatelessWidget {
  const _AuditCards({required this.items, required this.timeZone});
  final List<AuditEvent> items;
  final String timeZone;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return Column(
      children: [
        for (final event in items)
          Card(
            child: ListTile(
              contentPadding: const EdgeInsets.all(AppSpacing.medium),
              leading: Icon(_categoryIcon(event.category)),
              title: Text(_actionLabel(l, event.category)),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 4),
                  Text(event.actorEmail ?? l.auditFormerActor),
                  Text(_time(context, event.occurredAt, timeZone)),
                  Text(_categoryLabel(l, event.category)),
                ],
              ),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => _showDetails(context, event, timeZone),
            ),
          ),
      ],
    );
  }
}

class _EmptyAudit extends StatelessWidget {
  const _EmptyAudit({required this.filtered});
  final bool filtered;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.large),
        child: Column(
          children: [
            const Icon(Icons.history_toggle_off, size: 48),
            const SizedBox(height: AppSpacing.medium),
            Text(
              filtered ? l.auditNoFilterResults : l.auditNoEvents,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

Future<void> _showDetails(
  BuildContext context,
  AuditEvent event,
  String timeZone,
) => showModalBottomSheet<void>(
  context: context,
  isScrollControlled: true,
  useSafeArea: true,
  builder: (_) => _AuditDetails(event: event, timeZone: timeZone),
);

class _AuditDetails extends StatelessWidget {
  const _AuditDetails({required this.event, required this.timeZone});
  final AuditEvent event;
  final String timeZone;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final relatedPatient =
        event.context.patientId ??
        (event.subjectType == 'patient' ? event.subjectId : null);
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.large),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              l.auditDetails,
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: AppSpacing.large),
            _Detail(
              label: l.auditOccurredAt,
              value: _time(context, event.occurredAt, timeZone),
            ),
            _Detail(
              label: l.auditEmployee,
              value: event.actorEmail ?? l.auditFormerActor,
            ),
            _Detail(
              label: l.auditActorRoles,
              value: event.actorRoles.map((r) => _roleLabel(l, r)).join(', '),
            ),
            _Detail(
              label: l.auditCategory,
              value: _categoryLabel(l, event.category),
            ),
            _Detail(
              label: l.auditAction,
              value: _actionLabel(l, event.category),
            ),
            _Detail(
              label: l.auditEntity,
              value: '${event.subjectType} · ${event.subjectId}',
            ),
            _Detail(
              label: l.auditReason,
              value: event.reason ?? l.auditNoReason,
            ),
            if (event.context.amount != null)
              _Detail(
                label: l.dashboardOutstandingPayments,
                value:
                    '${event.context.currency ?? ''} ${event.context.amount}',
              ),
            if (event.context.resultCount != null)
              _Detail(
                label: l.auditResultCount,
                value: '${event.context.resultCount}',
              ),
            if (relatedPatient != null) ...[
              const SizedBox(height: AppSpacing.medium),
              FilledButton.icon(
                onPressed: () {
                  Navigator.pop(context);
                  context.go('/patients/$relatedPatient');
                },
                icon: const Icon(Icons.open_in_new),
                label: Text(l.auditOpenRecord),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _Detail extends StatelessWidget {
  const _Detail({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: AppSpacing.medium),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: Theme.of(context).textTheme.labelLarge),
        const SizedBox(height: 2),
        SelectableText(value),
      ],
    ),
  );
}

String _time(BuildContext context, DateTime value, String timeZone) {
  final locale = Localizations.localeOf(context).toLanguageTag();
  final local = tz.TZDateTime.from(value, tz.getLocation(timeZone));
  return DateFormat.yMMMd(locale).add_jm().format(local);
}

String _categoryLabel(AppLocalizations l, AuditCategory category) =>
    switch (category) {
      AuditCategory.access => l.auditCategoryAccess,
      AuditCategory.patientAdministration => l.auditCategoryPatient,
      AuditCategory.scheduling => l.auditCategoryScheduling,
      AuditCategory.clinical => l.auditCategoryClinical,
      AuditCategory.financial => l.auditCategoryFinancial,
      AuditCategory.staffSecurity => l.auditCategoryStaff,
    };

String _actionLabel(AppLocalizations l, AuditCategory category) =>
    switch (category) {
      AuditCategory.access => l.auditActionAccess,
      AuditCategory.patientAdministration => l.auditActionPatient,
      AuditCategory.scheduling => l.auditActionScheduling,
      AuditCategory.clinical => l.auditActionClinical,
      AuditCategory.financial => l.auditActionFinancial,
      AuditCategory.staffSecurity => l.auditActionStaff,
    };

IconData _categoryIcon(AuditCategory category) => switch (category) {
  AuditCategory.access => Icons.visibility_outlined,
  AuditCategory.patientAdministration => Icons.person_outline,
  AuditCategory.scheduling => Icons.event_outlined,
  AuditCategory.clinical => Icons.medical_information_outlined,
  AuditCategory.financial => Icons.account_balance_wallet_outlined,
  AuditCategory.staffSecurity => Icons.admin_panel_settings_outlined,
};

String _roleLabel(AppLocalizations l, String role) => switch (role) {
  'owner' => l.roleOwner,
  'dentist' => l.roleDentist,
  'assistant' => l.roleAssistant,
  'receptionist' => l.roleReceptionist,
  _ => role,
};

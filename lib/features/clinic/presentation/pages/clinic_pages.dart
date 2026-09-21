import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/localization/generated/app_localizations.dart';
import '../../../../app/theme/app_theme.dart';
import '../../../../core/error/failure_message.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../../auth/presentation/widgets/auth_appearance_actions.dart';
import '../../domain/clinic_models.dart';
import '../clinic_cubit.dart';
import '../device_time_zone.dart';

class ClinicGatePage extends StatefulWidget {
  const ClinicGatePage({super.key});

  @override
  State<ClinicGatePage> createState() => _ClinicGatePageState();
}

class _ClinicGatePageState extends State<ClinicGatePage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final state = context.read<ClinicCubit>().state;
      if (state.status == ClinicStatus.ready && state.activeClinic != null) {
        context.go('/dashboard');
      }
    });
  }

  @override
  Widget build(BuildContext context) => _ClinicScaffold(
    child: BlocConsumer<ClinicCubit, ClinicState>(
      listener: (context, state) {
        if (state.status == ClinicStatus.ready && state.activeClinic != null) {
          context.go('/dashboard');
        }
      },
      builder: (context, state) {
        final l = AppLocalizations.of(context);
        return switch (state.status) {
          ClinicStatus.initial ||
          ClinicStatus.loading => _ProgressCard(title: l.clinicLoadTitle),
          ClinicStatus.failure => _FailureCard(
            onRetry: context.read<ClinicCubit>().load,
          ),
          ClinicStatus.empty => _NoClinicsCard(
            onCreate: () => context.go('/clinics/create'),
          ),
          ClinicStatus.ready when state.activeClinic != null =>
            _ActiveClinicCard(
              membership: state.activeMembership!,
              hasMultiple: state.memberships.length > 1,
            ),
          ClinicStatus.ready => _ClinicSelector(
            memberships: state.memberships,
            onSelect: (id) async {
              await context.read<ClinicCubit>().selectClinic(id);
              if (context.mounted) context.go('/dashboard');
            },
            onCreate: () => context.go('/clinics/create'),
          ),
        };
      },
    ),
  );
}

class ClinicSelectorPage extends StatelessWidget {
  const ClinicSelectorPage({super.key});

  @override
  Widget build(BuildContext context) => _ClinicScaffold(
    child: BlocBuilder<ClinicCubit, ClinicState>(
      builder: (context, state) {
        if (state.status == ClinicStatus.failure) {
          return _FailureCard(onRetry: context.read<ClinicCubit>().load);
        }
        if (state.status != ClinicStatus.ready) {
          return _ProgressCard(
            title: AppLocalizations.of(context).clinicLoadTitle,
          );
        }
        if (state.memberships.isEmpty) {
          return _NoClinicsCard(onCreate: () => context.go('/clinics/create'));
        }
        return _ClinicSelector(
          memberships: state.memberships,
          onSelect: (id) async {
            await context.read<ClinicCubit>().selectClinic(id);
            if (context.mounted) context.go('/dashboard');
          },
          onCreate: () => context.go('/clinics/create'),
        );
      },
    ),
  );
}

class CreateClinicPage extends StatefulWidget {
  const CreateClinicPage({required this.timeZone, super.key});
  final DeviceTimeZone timeZone;

  @override
  State<CreateClinicPage> createState() => _CreateClinicPageState();
}

class _CreateClinicPageState extends State<CreateClinicPage> {
  final _form = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _ownerName = TextEditingController();
  final _timeZone = TextEditingController();
  String _currency = 'RUB';
  bool _timeZoneLoaded = false;

  @override
  void initState() {
    super.initState();
    _loadTimeZone();
  }

  Future<void> _loadTimeZone() async {
    final value = await widget.timeZone.current();
    if (!mounted || _timeZone.text.isNotEmpty) return;
    setState(() {
      _timeZone.text = value;
      _timeZoneLoaded = true;
    });
  }

  @override
  void dispose() {
    _name.dispose();
    _ownerName.dispose();
    _timeZone.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => _ClinicScaffold(
    child: BlocConsumer<ClinicCubit, ClinicState>(
      listenWhen: (previous, current) =>
          previous.creating && !current.creating && current.failure == null,
      listener: (_, state) {
        if (state.activeClinic != null) context.go('/dashboard');
      },
      builder: (context, state) {
        final l = AppLocalizations.of(context);
        void submit() {
          if (state.creating || !(_form.currentState?.validate() ?? false)) {
            return;
          }
          context.read<ClinicCubit>().createClinic(
            name: _name.text,
            ownerDisplayName: _ownerName.text,
            currencyCode: _currency,
            timeZone: _timeZone.text.trim(),
          );
        }

        return _ContentCard(
          title: l.clinicSetupTitle,
          child: Form(
            key: _form,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(l.clinicSetupBody),
                const SizedBox(height: AppSpacing.large),
                if (state.failure != null) ...[
                  Semantics(
                    liveRegion: true,
                    child: Text(failureMessage(state.failure!, l)),
                  ),
                  const SizedBox(height: AppSpacing.medium),
                ],
                TextFormField(
                  key: const ValueKey('clinic-name'),
                  controller: _name,
                  enabled: !state.creating,
                  autofocus: true,
                  textCapitalization: TextCapitalization.words,
                  maxLength: 120,
                  decoration: InputDecoration(
                    labelText: l.clinicNameLabel,
                    helperText: l.clinicNameHelp,
                  ),
                  validator: (value) {
                    final name = value?.trim() ?? '';
                    if (name.length < 2 || name.length > 120) {
                      return l.validationFailure;
                    }
                    return null;
                  },
                ),
                const SizedBox(height: AppSpacing.medium),
                TextFormField(
                  key: const ValueKey('clinic-owner-name'),
                  controller: _ownerName,
                  enabled: !state.creating,
                  textCapitalization: TextCapitalization.words,
                  maxLength: 120,
                  decoration: InputDecoration(labelText: l.nameLabel),
                  validator: (value) {
                    final ownerName = value?.trim() ?? '';
                    return ownerName.length >= 2 && ownerName.length <= 120
                        ? null
                        : l.validationFailure;
                  },
                ),
                const SizedBox(height: AppSpacing.medium),
                DropdownButtonFormField<String>(
                  key: const ValueKey('clinic-currency'),
                  initialValue: _currency,
                  decoration: InputDecoration(labelText: l.currencyLabel),
                  items: const [
                    DropdownMenuItem(value: 'RUB', child: Text('RUB')),
                    DropdownMenuItem(value: 'USD', child: Text('USD')),
                    DropdownMenuItem(value: 'EUR', child: Text('EUR')),
                  ],
                  onChanged: state.creating
                      ? null
                      : (value) => setState(() => _currency = value!),
                ),
                const SizedBox(height: AppSpacing.medium),
                TextFormField(
                  key: const ValueKey('clinic-time-zone'),
                  controller: _timeZone,
                  enabled: !state.creating,
                  decoration: InputDecoration(
                    labelText: l.timeZoneLabel,
                    helperText: _timeZoneLoaded
                        ? l.timeZoneHelp
                        : '${l.timeZoneHelp} ${l.clinicLoadTitle}',
                  ),
                  validator: (value) {
                    final zone = value?.trim() ?? '';
                    return RegExp(
                          r'^(?:[A-Za-z_]+/[A-Za-z_]+|Etc/UTC)$',
                        ).hasMatch(zone)
                        ? null
                        : l.validationFailure;
                  },
                  textInputAction: TextInputAction.done,
                  onFieldSubmitted: (_) => submit(),
                ),
                const SizedBox(height: AppSpacing.large),
                FilledButton(
                  key: const ValueKey('clinic-submit'),
                  onPressed: state.creating ? null : submit,
                  child: state.creating
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Text(l.createClinicLabel),
                ),
              ],
            ),
          ),
        );
      },
    ),
  );
}

class _ClinicScaffold extends StatelessWidget {
  const _ClinicScaffold({required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(l.appTitle),
        actions: [
          const AuthAppearanceActions(),
          IconButton(
            tooltip: l.logoutLabel,
            onPressed: () =>
                context.read<AuthBloc>().add(AuthLogoutRequested()),
            icon: const Icon(Icons.logout),
          ),
        ],
      ),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) => SingleChildScrollView(
            padding: EdgeInsets.all(
              constraints.maxWidth < 600 ? AppSpacing.medium : AppSpacing.large,
            ),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 600),
                child: child,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ContentCard extends StatelessWidget {
  const _ContentCard({required this.title, required this.child});
  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) => Card(
    child: Padding(
      padding: const EdgeInsets.all(AppSpacing.large),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Semantics(
            header: true,
            child: Text(
              title,
              style: Theme.of(context).textTheme.headlineSmall,
            ),
          ),
          const SizedBox(height: AppSpacing.medium),
          child,
        ],
      ),
    ),
  );
}

class _ProgressCard extends StatelessWidget {
  const _ProgressCard({required this.title});
  final String title;
  @override
  Widget build(BuildContext context) => _ContentCard(
    title: title,
    child: const Center(child: CircularProgressIndicator()),
  );
}

class _FailureCard extends StatelessWidget {
  const _FailureCard({required this.onRetry});
  final Future<void> Function() onRetry;
  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return _ContentCard(
      title: l.clinicLoadFailed,
      child: FilledButton(
        onPressed: () => onRetry(),
        child: Text(l.retryLabel),
      ),
    );
  }
}

class _NoClinicsCard extends StatelessWidget {
  const _NoClinicsCard({required this.onCreate});
  final VoidCallback onCreate;
  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return _ContentCard(
      title: l.clinicSetupTitle,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(l.clinicSetupBody),
          const SizedBox(height: AppSpacing.large),
          FilledButton(onPressed: onCreate, child: Text(l.createClinicLabel)),
        ],
      ),
    );
  }
}

class _ClinicSelector extends StatelessWidget {
  const _ClinicSelector({
    required this.memberships,
    required this.onSelect,
    required this.onCreate,
  });
  final List<ClinicMembership> memberships;
  final Future<void> Function(String id) onSelect;
  final VoidCallback onCreate;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return _ContentCard(
      title: l.selectClinicTitle,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(l.selectClinicBody),
          const SizedBox(height: AppSpacing.medium),
          for (final membership in memberships) ...[
            ListTile(
              key: ValueKey('clinic-select-${membership.clinic.id}'),
              contentPadding: EdgeInsets.zero,
              title: Text(membership.clinic.name),
              subtitle: Text(
                '${membership.clinic.currencyCode} · ${membership.clinic.timeZone}',
              ),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => onSelect(membership.clinic.id),
            ),
            const Divider(),
          ],
          const SizedBox(height: AppSpacing.small),
          OutlinedButton.icon(
            onPressed: onCreate,
            icon: const Icon(Icons.add),
            label: Text(l.addClinicLabel),
          ),
        ],
      ),
    );
  }
}

class _ActiveClinicCard extends StatelessWidget {
  const _ActiveClinicCard({
    required this.membership,
    required this.hasMultiple,
  });
  final ClinicMembership membership;
  final bool hasMultiple;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final clinic = membership.clinic;
    final theme = Theme.of(context);
    return _ContentCard(
      title: l.currentClinicTitle,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            l.currentClinicBody(clinic.name),
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: AppSpacing.medium),
          Container(
            padding: const EdgeInsets.all(AppSpacing.medium),
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerHighest.withValues(
                alpha: 0.4,
              ),
              borderRadius: BorderRadius.circular(AppSizing.controlRadius),
              border: Border.all(
                color: theme.colorScheme.outlineVariant.withValues(alpha: 0.6),
              ),
            ),
            child: Row(
              children: [
                CircleAvatar(
                  backgroundColor: theme.colorScheme.primaryContainer,
                  child: Icon(
                    Icons.local_hospital_rounded,
                    color: theme.colorScheme.primary,
                  ),
                ),
                const SizedBox(width: AppSpacing.medium),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        clinic.name,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        '${clinic.currencyCode} · ${clinic.timeZone}',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.large),
          FilledButton.icon(
            onPressed: () => context.go('/dashboard'),
            icon: const Icon(Icons.dashboard_rounded),
            label: Text(l.dashboardTitle),
            style: FilledButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 14),
            ),
          ),
          const SizedBox(height: AppSpacing.medium),
          Wrap(
            spacing: AppSpacing.small,
            runSpacing: AppSpacing.small,
            children: [
              OutlinedButton.icon(
                onPressed: () => context.go('/patients'),
                icon: const Icon(Icons.people_outline),
                label: Text(l.patientsTitle),
              ),
              OutlinedButton.icon(
                onPressed: () => context.go('/appointments'),
                icon: const Icon(Icons.event_available_outlined),
                label: Text(l.appointmentsTitle),
              ),
              OutlinedButton.icon(
                onPressed: () => context.go('/procedures'),
                icon: const Icon(Icons.medical_services_outlined),
                label: Text(l.procedureCatalogueTitle),
              ),
              if (membership.roles.any(
                (role) =>
                    role == 'owner' ||
                    role == 'dentist' ||
                    role == 'receptionist',
              ))
                OutlinedButton.icon(
                  onPressed: () => context.go('/billing'),
                  icon: const Icon(Icons.receipt_long_outlined),
                  label: Text(l.billingTitle),
                ),
              if (membership.isOwner || membership.roles.contains('dentist'))
                OutlinedButton.icon(
                  key: const ValueKey('open-schedule'),
                  onPressed: () => context.go('/schedule'),
                  icon: const Icon(Icons.calendar_month_outlined),
                  label: Text(l.doctorScheduleTitle),
                ),
              if (membership.isOwner)
                OutlinedButton.icon(
                  key: const ValueKey('open-staff'),
                  onPressed: () => context.go('/staff'),
                  icon: const Icon(Icons.group_outlined),
                  label: Text(l.staffTitle),
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.large),
          const Divider(),
          const SizedBox(height: AppSpacing.small),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              if (hasMultiple)
                TextButton.icon(
                  onPressed: () => context.go('/clinics/select'),
                  icon: const Icon(Icons.swap_horiz_rounded),
                  label: Text(l.switchClinicLabel),
                )
              else
                const SizedBox.shrink(),
              TextButton.icon(
                onPressed: () => context.go('/clinics/create'),
                icon: const Icon(Icons.add_rounded),
                label: Text(l.addClinicLabel),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

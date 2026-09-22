import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/presentation/bloc/auth_bloc.dart';
import '../../features/clinic/domain/clinic_models.dart';
import '../../features/clinic/presentation/clinic_cubit.dart';
import '../localization/generated/app_localizations.dart';
import '../theme/app_theme.dart';
import 'workspace_destination.dart';

class WorkspaceShell extends StatefulWidget {
  const WorkspaceShell({
    required this.location,
    required this.child,
    super.key,
  });

  final String location;
  final Widget child;

  @override
  State<WorkspaceShell> createState() => _WorkspaceShellState();
}

class _WorkspaceShellState extends State<WorkspaceShell> {
  final List<String> _history = [];
  DateTime? _lastBackPress;

  @override
  void didUpdateWidget(covariant WorkspaceShell oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.location != widget.location) {
      if (_history.isEmpty || _history.last != oldWidget.location) {
        _history.add(oldWidget.location);
        if (_history.length > 30) {
          _history.removeAt(0);
        }
      }
    }
  }

  void _handleBack() {
    if (Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
      return;
    }
    if (widget.location != '/dashboard') {
      while (_history.isNotEmpty && _history.last == widget.location) {
        _history.removeLast();
      }
      final previous =
          _history.isNotEmpty ? _history.removeLast() : '/dashboard';
      context.go(previous);
      return;
    }
    final now = DateTime.now();
    if (_lastBackPress != null &&
        now.difference(_lastBackPress!) < const Duration(seconds: 2)) {
      SystemNavigator.pop();
    } else {
      _lastBackPress = now;
      final l = AppLocalizations.of(context);
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            content: Text(l.pressBackAgainToExit),
            duration: const Duration(seconds: 2),
          ),
        );
    }
  }

  @override
  Widget build(BuildContext context) => PopScope(
    canPop: false,
    onPopInvokedWithResult: (didPop, _) {
      if (didPop) return;
      _handleBack();
    },
    child: BlocBuilder<ClinicCubit, ClinicState>(
      builder: (context, clinicState) {
        final membership = clinicState.activeMembership;
        if (membership == null) return widget.child;
        final authState = context.watch<AuthBloc>().state;
        return WorkspaceNavigation(
          location: widget.location,
          membership: membership,
          email: authState.identity?.email ?? authState.email,
          onNavigate: context.go,
          onSwitchClinic: clinicState.memberships.length > 1
              ? () => context.go('/clinics/select')
              : null,
          onLock: () => context.read<AuthBloc>().add(AuthLockRequested()),
          onSignOut: () => context.read<AuthBloc>().add(AuthLogoutRequested()),
          child: widget.child,
        );
      },
    ),
  );
}

class WorkspaceNavigation extends StatelessWidget {
  const WorkspaceNavigation({
    required this.location,
    required this.membership,
    required this.email,
    required this.onNavigate,
    required this.onLock,
    required this.onSignOut,
    required this.child,
    this.onSwitchClinic,
    super.key,
  });

  final String location;
  final ClinicMembership membership;
  final String email;
  final ValueChanged<String> onNavigate;
  final VoidCallback? onSwitchClinic;
  final VoidCallback onLock;
  final VoidCallback onSignOut;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final layout = AppBreakpoints.of(context);
    final visible = WorkspaceDestinations.visibleFor(membership.roles);
    final selected = WorkspaceDestinations.selectedFor(location);
    return Scaffold(
      body: switch (layout) {
        AppLayoutClass.desktop => Row(
          children: [
            SizedBox(
              width: AppSizing.desktopSidebarWidth,
              child: _DesktopSidebar(
                destinations: visible,
                selected: selected,
                membership: membership,
                email: email,
                onNavigate: onNavigate,
                onSwitchClinic: onSwitchClinic,
                onLock: onLock,
                onSignOut: onSignOut,
              ),
            ),
            const VerticalDivider(width: 1),
            Expanded(child: child),
          ],
        ),
        AppLayoutClass.tablet => Row(
          children: [
            _TabletRail(
              destinations: visible,
              selected: selected,
              onNavigate: onNavigate,
              onOpenAccount: () => _showWorkspaceMenu(context, visible),
            ),
            const VerticalDivider(width: 1),
            Expanded(child: child),
          ],
        ),
        AppLayoutClass.mobile => child,
      },
      bottomNavigationBar: layout == AppLayoutClass.mobile
          ? _MobileNavigation(
              selected: selected,
              onNavigate: onNavigate,
              onMore: () => _showWorkspaceMenu(context, visible),
            )
          : null,
      floatingActionButton: _canShowQuickActions(location, membership.roles)
          ? FloatingActionButton(
              tooltip: AppLocalizations.of(context).quickActions,
              onPressed: () => _showQuickActions(context),
              child: const Icon(Icons.add_rounded),
            )
          : null,
    );
  }

  bool _canShowQuickActions(String location, Set<String> roles) {
    final allowedRoles = roles.contains('owner') ||
        roles.contains('receptionist') ||
        roles.contains('dentist');
    if (!allowedRoles) return false;
    return location == '/dashboard' ||
        location == '/patients' ||
        location == '/appointments';
  }

  Future<void> _showQuickActions(BuildContext context) async {
    unawaited(HapticFeedback.lightImpact());
    final l = AppLocalizations.of(context);
    final theme = Theme.of(context);
    await showModalBottomSheet<void>(
      context: context,
      useSafeArea: true,
      showDragHandle: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetContext) => Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
              child: Text(
                l.quickActions,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(height: 8),
            ListTile(
              leading: CircleAvatar(
                backgroundColor: theme.colorScheme.primaryContainer,
                foregroundColor: theme.colorScheme.onPrimaryContainer,
                child: const Icon(Icons.event_available_rounded),
              ),
              title: Text(l.quickNewAppointment),
              subtitle: Text(l.newAppointmentLabel),
              trailing: const Icon(Icons.chevron_right_rounded),
              onTap: () {
                Navigator.of(sheetContext).pop();
                onNavigate('/appointments/new');
              },
            ),
            const SizedBox(height: 4),
            ListTile(
              leading: CircleAvatar(
                backgroundColor: theme.colorScheme.secondaryContainer,
                foregroundColor: theme.colorScheme.onSecondaryContainer,
                child: const Icon(Icons.person_add_alt_1_rounded),
              ),
              title: Text(l.quickNewPatient),
              subtitle: Text(l.newPatientLabel),
              trailing: const Icon(Icons.chevron_right_rounded),
              onTap: () {
                Navigator.of(sheetContext).pop();
                onNavigate('/patients/new');
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showWorkspaceMenu(
    BuildContext context,
    List<WorkspaceDestination> visible,
  ) => showModalBottomSheet<void>(
    context: context,
    useSafeArea: true,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (sheetContext) => _WorkspaceMenu(
      destinations: visible
          .where(
            (item) =>
                item.id != WorkspaceDestinationId.dashboard &&
                item.id != WorkspaceDestinationId.patients &&
                item.id != WorkspaceDestinationId.appointments,
          )
          .toList(growable: false),
      membership: membership,
      email: email,
      onNavigate: (route) {
        Navigator.of(sheetContext).pop();
        onNavigate(route);
      },
      onSwitchClinic: onSwitchClinic == null
          ? null
          : () {
              Navigator.of(sheetContext).pop();
              onSwitchClinic!();
            },
      onLock: () {
        Navigator.of(sheetContext).pop();
        onLock();
      },
      onSignOut: () {
        Navigator.of(sheetContext).pop();
        onSignOut();
      },
    ),
  );
}

class _DesktopSidebar extends StatelessWidget {
  const _DesktopSidebar({
    required this.destinations,
    required this.selected,
    required this.membership,
    required this.email,
    required this.onNavigate,
    required this.onSwitchClinic,
    required this.onLock,
    required this.onSignOut,
  });

  final List<WorkspaceDestination> destinations;
  final WorkspaceDestination selected;
  final ClinicMembership membership;
  final String email;
  final ValueChanged<String> onNavigate;
  final VoidCallback? onSwitchClinic;
  final VoidCallback onLock;
  final VoidCallback onSignOut;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);
    return Material(
      color: theme.colorScheme.surfaceContainerLow,
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.all(AppSpacing.large),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(l10n.appTitle, style: theme.textTheme.titleLarge),
                  const SizedBox(height: AppSpacing.medium),
                  Text(
                    membership.clinic.name,
                    style: theme.textTheme.titleMedium,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: AppSpacing.extraSmall),
                  Text(
                    _roleSummary(l10n, membership.roles),
                    style: theme.textTheme.bodySmall,
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.small,
                ),
                itemCount: destinations.length,
                itemBuilder: (context, index) {
                  final destination = destinations[index];
                  final isSelected = destination.id == selected.id;
                  return Padding(
                    padding: const EdgeInsets.only(
                      bottom: AppSpacing.extraSmall,
                    ),
                    child: ListTile(
                      selected: isSelected,
                      leading: Icon(
                        isSelected
                            ? destination.selectedIcon
                            : destination.icon,
                      ),
                      title: Text(destination.label(l10n)),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(
                          AppSizing.controlRadius,
                        ),
                      ),
                      onTap: isSelected
                          ? null
                          : () => onNavigate(destination.route),
                    ),
                  );
                },
              ),
            ),
            const Divider(),
            _AccountActions(
              email: email,
              onSwitchClinic: onSwitchClinic,
              onLock: onLock,
              onSignOut: onSignOut,
            ),
          ],
        ),
      ),
    );
  }
}

class _TabletRail extends StatelessWidget {
  const _TabletRail({
    required this.destinations,
    required this.selected,
    required this.onNavigate,
    required this.onOpenAccount,
  });

  final List<WorkspaceDestination> destinations;
  final WorkspaceDestination selected;
  final ValueChanged<String> onNavigate;
  final VoidCallback onOpenAccount;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return SafeArea(
      child: SizedBox(
        width: AppSizing.tabletRailWidth,
        child: Column(
          children: [
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(vertical: AppSpacing.small),
                children: [
                  for (final destination in destinations)
                    Tooltip(
                      message: destination.label(l10n),
                      child: IconButton(
                        isSelected: selected.id == destination.id,
                        onPressed: selected.id == destination.id
                            ? null
                            : () => onNavigate(destination.route),
                        icon: Icon(destination.icon),
                        selectedIcon: Icon(destination.selectedIcon),
                      ),
                    ),
                ],
              ),
            ),
            const Divider(),
            IconButton(
              tooltip: l10n.accountSectionTitle,
              onPressed: onOpenAccount,
              icon: const Icon(Icons.account_circle_outlined),
            ),
            const SizedBox(height: AppSpacing.small),
          ],
        ),
      ),
    );
  }
}

class _MobileNavigation extends StatelessWidget {
  const _MobileNavigation({
    required this.selected,
    required this.onNavigate,
    required this.onMore,
  });

  final WorkspaceDestination selected;
  final ValueChanged<String> onNavigate;
  final VoidCallback onMore;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final primary = WorkspaceDestinations.all.take(3).toList(growable: false);
    final selectedIndex = primary.indexWhere((item) => item.id == selected.id);
    return NavigationBar(
      selectedIndex: selectedIndex < 0 ? 3 : selectedIndex,
      onDestinationSelected: (index) {
        if (index == 3) {
          onMore();
        } else {
          onNavigate(primary[index].route);
        }
      },
      destinations: [
        for (final destination in primary)
          NavigationDestination(
            icon: Icon(destination.icon),
            selectedIcon: Icon(destination.selectedIcon),
            label: destination.label(l10n),
          ),
        NavigationDestination(
          icon: const Icon(Icons.more_horiz),
          selectedIcon: const Icon(Icons.more),
          label: l10n.moreLabel,
        ),
      ],
    );
  }
}

class _WorkspaceMenu extends StatelessWidget {
  const _WorkspaceMenu({
    required this.destinations,
    required this.membership,
    required this.email,
    required this.onNavigate,
    required this.onSwitchClinic,
    required this.onLock,
    required this.onSignOut,
  });

  final List<WorkspaceDestination> destinations;
  final ClinicMembership membership;
  final String email;
  final ValueChanged<String> onNavigate;
  final VoidCallback? onSwitchClinic;
  final VoidCallback onLock;
  final VoidCallback onSignOut;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return ListView(
      shrinkWrap: true,
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.medium,
        0,
        AppSpacing.medium,
        AppSpacing.large,
      ),
      children: [
        ListTile(
          leading: const Icon(Icons.local_hospital_outlined),
          title: Text(membership.clinic.name),
          subtitle: Text(_roleSummary(l10n, membership.roles)),
        ),
        const Divider(),
        for (final destination in destinations)
          ListTile(
            leading: Icon(destination.icon),
            title: Text(destination.label(l10n)),
            onTap: () => onNavigate(destination.route),
          ),
        const Divider(),
        _AccountActions(
          email: email,
          onSwitchClinic: onSwitchClinic,
          onLock: onLock,
          onSignOut: onSignOut,
        ),
      ],
    );
  }
}

class _AccountActions extends StatelessWidget {
  const _AccountActions({
    required this.email,
    required this.onSwitchClinic,
    required this.onLock,
    required this.onSignOut,
  });

  final String email;
  final VoidCallback? onSwitchClinic;
  final VoidCallback onLock;
  final VoidCallback onSignOut;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.small),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (email.isNotEmpty)
            Padding(
              padding: const EdgeInsets.all(AppSpacing.small),
              child: Text(
                email,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ),
          if (onSwitchClinic != null)
            ListTile(
              leading: const Icon(Icons.swap_horiz),
              title: Text(l10n.switchClinicLabel),
              onTap: onSwitchClinic,
            ),
          ListTile(
            leading: const Icon(Icons.lock_outline),
            title: Text(l10n.lockLabel),
            onTap: onLock,
          ),
          ListTile(
            leading: const Icon(Icons.logout),
            title: Text(l10n.logoutLabel),
            onTap: onSignOut,
          ),
        ],
      ),
    );
  }
}

String _roleSummary(AppLocalizations l10n, Set<String> roles) {
  final labels = <String>[
    if (roles.contains('owner')) l10n.roleOwner,
    if (roles.contains('dentist')) l10n.roleDentist,
    if (roles.contains('assistant')) l10n.roleAssistant,
    if (roles.contains('receptionist')) l10n.roleReceptionist,
  ];
  return labels.join(' · ');
}

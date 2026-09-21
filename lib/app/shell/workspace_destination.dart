import 'package:flutter/material.dart';

import '../localization/generated/app_localizations.dart';

enum WorkspaceDestinationId {
  dashboard,
  patients,
  appointments,
  schedule,
  treatments,
  billing,
  staff,
  audit,
  settings,
}

class WorkspaceDestination {
  const WorkspaceDestination({
    required this.id,
    required this.route,
    required this.icon,
    required this.selectedIcon,
  });

  final WorkspaceDestinationId id;
  final String route;
  final IconData icon;
  final IconData selectedIcon;

  bool isVisibleFor(Set<String> roles) => switch (id) {
    WorkspaceDestinationId.schedule =>
      roles.contains('owner') || roles.contains('dentist'),
    WorkspaceDestinationId.billing =>
      roles.contains('owner') ||
          roles.contains('dentist') ||
          roles.contains('receptionist'),
    WorkspaceDestinationId.staff ||
    WorkspaceDestinationId.audit => roles.contains('owner'),
    _ => true,
  };

  String label(AppLocalizations l10n) => switch (id) {
    WorkspaceDestinationId.dashboard => l10n.dashboardTitle,
    WorkspaceDestinationId.patients => l10n.patientsTitle,
    WorkspaceDestinationId.appointments => l10n.appointmentsTitle,
    WorkspaceDestinationId.schedule => l10n.doctorScheduleTitle,
    WorkspaceDestinationId.treatments => l10n.procedureCatalogueTitle,
    WorkspaceDestinationId.billing => l10n.billingTitle,
    WorkspaceDestinationId.staff => l10n.staffTitle,
    WorkspaceDestinationId.audit => l10n.auditTitle,
    WorkspaceDestinationId.settings => l10n.settingsTitle,
  };
}

abstract final class WorkspaceDestinations {
  static const all = <WorkspaceDestination>[
    WorkspaceDestination(
      id: WorkspaceDestinationId.dashboard,
      route: '/dashboard',
      icon: Icons.dashboard_outlined,
      selectedIcon: Icons.dashboard,
    ),
    WorkspaceDestination(
      id: WorkspaceDestinationId.patients,
      route: '/patients',
      icon: Icons.people_outline,
      selectedIcon: Icons.people,
    ),
    WorkspaceDestination(
      id: WorkspaceDestinationId.appointments,
      route: '/appointments',
      icon: Icons.calendar_month_outlined,
      selectedIcon: Icons.calendar_month,
    ),
    WorkspaceDestination(
      id: WorkspaceDestinationId.schedule,
      route: '/schedule',
      icon: Icons.schedule_outlined,
      selectedIcon: Icons.schedule,
    ),
    WorkspaceDestination(
      id: WorkspaceDestinationId.treatments,
      route: '/procedures',
      icon: Icons.medical_services_outlined,
      selectedIcon: Icons.medical_services,
    ),
    WorkspaceDestination(
      id: WorkspaceDestinationId.billing,
      route: '/billing',
      icon: Icons.receipt_long_outlined,
      selectedIcon: Icons.receipt_long,
    ),
    WorkspaceDestination(
      id: WorkspaceDestinationId.staff,
      route: '/staff',
      icon: Icons.badge_outlined,
      selectedIcon: Icons.badge,
    ),
    WorkspaceDestination(
      id: WorkspaceDestinationId.audit,
      route: '/audit',
      icon: Icons.policy_outlined,
      selectedIcon: Icons.policy,
    ),
    WorkspaceDestination(
      id: WorkspaceDestinationId.settings,
      route: '/settings',
      icon: Icons.settings_outlined,
      selectedIcon: Icons.settings,
    ),
  ];

  static List<WorkspaceDestination> visibleFor(Set<String> roles) => all
      .where((destination) => destination.isVisibleFor(roles))
      .toList(growable: false);

  static WorkspaceDestination selectedFor(String location) {
    if (location.startsWith('/patients/')) return all[1];
    if (location.startsWith('/appointments/')) return all[2];
    return all.firstWhere(
      (destination) => destination.route == location,
      orElse: () => all.first,
    );
  }
}

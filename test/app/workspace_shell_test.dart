import 'package:dental_clini_management_saas/app/localization/generated/app_localizations.dart';
import 'package:dental_clini_management_saas/app/shell/workspace_destination.dart';
import 'package:dental_clini_management_saas/app/shell/workspace_shell.dart';
import 'package:dental_clini_management_saas/app/theme/app_theme.dart';
import 'package:dental_clini_management_saas/features/clinic/domain/clinic_models.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'destination catalogue applies role visibility and contextual selection',
    () {
      final receptionist = WorkspaceDestinations.visibleFor({
        'receptionist',
      }).map((item) => item.id);
      expect(receptionist, contains(WorkspaceDestinationId.billing));
      expect(receptionist, isNot(contains(WorkspaceDestinationId.schedule)));
      expect(receptionist, isNot(contains(WorkspaceDestinationId.staff)));
      expect(receptionist, isNot(contains(WorkspaceDestinationId.audit)));

      final dentist = WorkspaceDestinations.visibleFor({
        'dentist',
      }).map((item) => item.id);
      expect(dentist, contains(WorkspaceDestinationId.schedule));
      expect(dentist, contains(WorkspaceDestinationId.billing));
      expect(dentist, isNot(contains(WorkspaceDestinationId.staff)));

      final assistant = WorkspaceDestinations.visibleFor({
        'assistant',
      }).map((item) => item.id);
      expect(assistant, contains(WorkspaceDestinationId.treatments));
      expect(assistant, contains(WorkspaceDestinationId.settings));
      expect(assistant, isNot(contains(WorkspaceDestinationId.schedule)));
      expect(assistant, isNot(contains(WorkspaceDestinationId.billing)));

      final owner = WorkspaceDestinations.visibleFor({
        'owner',
      }).map((item) => item.id);
      expect(owner, contains(WorkspaceDestinationId.staff));
      expect(owner, contains(WorkspaceDestinationId.audit));
      expect(owner, contains(WorkspaceDestinationId.settings));

      expect(
        WorkspaceDestinations.selectedFor('/patients/demo/medical').id,
        WorkspaceDestinationId.patients,
      );
      expect(
        WorkspaceDestinations.selectedFor('/appointments/new').id,
        WorkspaceDestinationId.appointments,
      );
    },
  );

  testWidgets('desktop renders a labeled role-aware sidebar', (tester) async {
    tester.view.physicalSize = const Size(1440, 1000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      _testApp(roles: const {'receptionist'}, location: '/patients/demo'),
    );
    await tester.pumpAndSettle();

    expect(find.text('Demo Dental Clinic'), findsOneWidget);
    expect(find.text('Patients'), findsOneWidget);
    expect(find.text('Billing & invoices'), findsOneWidget);
    expect(find.text('Staff'), findsNothing);
    expect(find.text('Audit log'), findsNothing);
    expect(find.byType(NavigationBar), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('tablet renders the compact navigation rail', (tester) async {
    tester.view.physicalSize = const Size(800, 1000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      _testApp(roles: const {'owner'}, location: '/dashboard'),
    );
    await tester.pumpAndSettle();

    expect(find.byTooltip('Patients'), findsOneWidget);
    expect(find.byTooltip('Audit log'), findsOneWidget);
    expect(find.byType(NavigationBar), findsNothing);
    expect(tester.takeException(), isNull);
  });

  for (final width in [599.0, 600.0, 1024.0, 1025.0]) {
    testWidgets('shell changes layout at approved width $width', (
      tester,
    ) async {
      tester.view.physicalSize = Size(width, 1000);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        _testApp(roles: const {'owner'}, location: '/dashboard'),
      );
      await tester.pumpAndSettle();

      if (width < 600) {
        expect(find.byType(NavigationBar), findsOneWidget);
      } else if (width <= 1024) {
        expect(find.byType(NavigationBar), findsNothing);
        expect(find.byTooltip('Patients'), findsOneWidget);
        expect(find.text('Demo Dental Clinic'), findsNothing);
      } else {
        expect(find.byType(NavigationBar), findsNothing);
        expect(find.text('Demo Dental Clinic'), findsOneWidget);
      }
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('Arabic mobile navigation and More fit at 320px and 200% text', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 760);
    tester.view.devicePixelRatio = 1;
    tester.platformDispatcher.textScaleFactorTestValue = 2;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);

    await tester.pumpWidget(
      _testApp(
        roles: const {'owner'},
        location: '/settings',
        locale: const Locale('ar'),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byType(NavigationBar), findsOneWidget);
    expect(find.text('المزيد'), findsOneWidget);
    await tester.tap(find.text('المزيد'));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.text('الإعدادات'),
      200,
      scrollable: find.byType(Scrollable).last,
    );
    expect(find.text('الإعدادات'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.text('قفل مساحة العمل'),
      200,
      scrollable: find.byType(Scrollable).last,
    );
    expect(find.text('قفل مساحة العمل'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}

Widget _testApp({
  required Set<String> roles,
  required String location,
  Locale locale = const Locale('en'),
}) => MaterialApp(
  theme: AppTheme.light,
  locale: locale,
  localizationsDelegates: AppLocalizations.localizationsDelegates,
  supportedLocales: AppLocalizations.supportedLocales,
  home: WorkspaceNavigation(
    location: location,
    membership: ClinicMembership(
      clinic: const Clinic(
        id: 'clinic-demo',
        name: 'Demo Dental Clinic',
        currencyCode: 'USD',
        timeZone: 'Etc/UTC',
      ),
      roles: roles,
    ),
    email: 'owner@example.test',
    onNavigate: (_) {},
    onLock: () {},
    onSignOut: () {},
    child: const ColoredBox(
      color: Colors.transparent,
      child: Center(child: Text('Content')),
    ),
  ),
);

import 'package:dental_clini_management_saas/app/localization/generated/app_localizations.dart';
import 'package:dental_clini_management_saas/core/value/money.dart';
import 'package:dental_clini_management_saas/features/clinic/domain/clinic_models.dart';
import 'package:dental_clini_management_saas/features/clinic/presentation/clinic_cubit.dart';
import 'package:dental_clini_management_saas/features/dashboard/domain/dashboard_models.dart';
import 'package:dental_clini_management_saas/features/dashboard/presentation/dashboard_cubit.dart';
import 'package:dental_clini_management_saas/features/dashboard/presentation/pages/dashboard_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockClinicCubit extends Mock implements ClinicCubit {}

class _MockDashboardCubit extends Mock implements DashboardCubit {}

void main() {
  testWidgets('assistant sees operational metrics without protected groups', (
    tester,
  ) async {
    final dashboard = _snapshot(includeProtected: false);
    await tester.pumpWidget(_dashboardApp(const Locale('en'), dashboard));
    await tester.pump();

    expect(find.text('Active patients'), findsOneWidget);
    expect(find.text('Appointments this week'), findsOneWidget);
    expect(find.text('Treatments completed this month'), findsNothing);
    expect(find.text('Outstanding payments'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Arabic owner dashboard fits a narrow phone with large text', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 1100);
    tester.view.devicePixelRatio = 1;
    tester.platformDispatcher.textScaleFactorTestValue = 1.6;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);

    await tester.pumpWidget(
      _dashboardApp(const Locale('ar'), _snapshot(includeProtected: true)),
    );
    await tester.pump();

    expect(find.text('لوحة المعلومات'), findsOneWidget);
    expect(find.text('العلاجات المكتملة هذا الشهر'), findsOneWidget);
    expect(find.text('الدفعات المستحقة'), findsOneWidget);
    expect(
      Directionality.of(tester.element(find.byType(Scaffold))),
      TextDirection.rtl,
    );
    expect(tester.takeException(), isNull);
  });
}

Widget _dashboardApp(Locale locale, DashboardSnapshot snapshot) {
  final clinic = _MockClinicCubit();
  final dashboard = _MockDashboardCubit();
  when(() => clinic.stream).thenAnswer((_) => const Stream.empty());
  when(() => clinic.state).thenReturn(
    const ClinicState(
      status: ClinicStatus.ready,
      activeClinicId: 'clinic-1',
      memberships: [
        ClinicMembership(
          clinic: Clinic(
            id: 'clinic-1',
            name: 'Demo Clinic',
            currencyCode: 'RUB',
            timeZone: 'Europe/Moscow',
          ),
          roles: {'owner'},
        ),
      ],
    ),
  );
  when(() => dashboard.stream).thenAnswer((_) => const Stream.empty());
  when(() => dashboard.state).thenReturn(
    DashboardState(
      status: DashboardLoadStatus.ready,
      clinicId: 'clinic-1',
      snapshot: snapshot,
    ),
  );
  when(() => dashboard.load(any())).thenAnswer((_) async {});
  when(() => dashboard.refresh()).thenAnswer((_) async {});
  return MultiBlocProvider(
    providers: [
      BlocProvider<ClinicCubit>.value(value: clinic),
      BlocProvider<DashboardCubit>.value(value: dashboard),
    ],
    child: MaterialApp(
      locale: locale,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: const DashboardPage(),
    ),
  );
}

DashboardSnapshot _snapshot({required bool includeProtected}) {
  return DashboardSnapshot(
    clinicId: 'clinic-1',
    clinicTimeZone: 'Europe/Moscow',
    generatedAt: DateTime.utc(2026, 9, 13, 9),
    period: DashboardPeriod(
      todayStart: DateTime.utc(2026, 9, 12, 21),
      tomorrowStart: DateTime.utc(2026, 9, 13, 21),
      upcomingEnd: DateTime.utc(2026, 9, 20, 21),
      weekStart: DateTime.utc(2026, 9, 6, 21),
      weekEnd: DateTime.utc(2026, 9, 13, 21),
      monthStart: DateTime.utc(2026, 8, 31, 21),
      nextMonthStart: DateTime.utc(2026, 9, 30, 21),
    ),
    capabilities: DashboardCapabilities(
      canViewCompletedTreatments: includeProtected,
      canViewFinancialSummary: includeProtected,
    ),
    metrics: DashboardMetrics(
      totalPatients: 7,
      appointmentsThisWeek: 4,
      completedTreatmentsThisMonth: includeProtected ? 2 : null,
      financial: includeProtected
          ? const DashboardFinancialSummary(
              outstandingInvoiceCount: 1,
              outstandingAmount: Money.fromMinorUnits(12500),
              currencyCode: 'RUB',
            )
          : null,
    ),
    todayAppointments: const DashboardAppointmentSection(
      totalCount: 0,
      hasMore: false,
      items: [],
    ),
    upcomingAppointments: const DashboardAppointmentSection(
      totalCount: 0,
      hasMore: false,
      items: [],
    ),
  );
}

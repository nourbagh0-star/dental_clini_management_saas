import 'package:dental_clini_management_saas/app/localization/generated/app_localizations.dart';
import 'package:dental_clini_management_saas/app/theme/app_theme.dart';
import 'package:dental_clini_management_saas/features/clinic/domain/clinic_models.dart';
import 'package:dental_clini_management_saas/features/clinic/presentation/clinic_cubit.dart';
import 'package:dental_clini_management_saas/features/schedule/domain/schedule_models.dart';
import 'package:dental_clini_management_saas/features/schedule/presentation/pages/schedule_page.dart';
import 'package:dental_clini_management_saas/features/schedule/presentation/schedule_cubit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockClinicCubit extends Mock implements ClinicCubit {}

class _MockScheduleCubit extends Mock implements ScheduleCubit {}

void main() {
  testWidgets('schedule page identifies the doctor and separates versions', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1400, 1000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final clinic = _clinicCubit();
    final schedule = _scheduleCubit();

    await tester.pumpWidget(_app(clinic, schedule));
    await tester.pump();

    expect(find.text('Dr. Morgan'), findsOneWidget);
    expect(find.text('Active schedule'), findsOneWidget);
    expect(find.text('Upcoming schedule'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.text('Schedule history'),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('Schedule history'), findsOneWidget);
    expect(find.text('Closed'), findsWidgets);
    expect(tester.takeException(), isNull);
  });

  testWidgets('weekly editor uses day chips and picker controls', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(900, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final clinic = _clinicCubit();
    final schedule = _scheduleCubit();

    await tester.pumpWidget(_app(clinic, schedule));
    await tester.pump();
    await tester.tap(find.text('Edit weekly schedule'));
    await tester.pumpAndSettle();

    expect(find.byType(FilterChip), findsNWidgets(7));
    expect(find.text('Select the days this dentist works.'), findsOneWidget);
    expect(find.text('Schedule summary'), findsOneWidget);
    expect(find.byType(TextField), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Arabic schedule and editor fit a narrow phone', (tester) async {
    tester.view.physicalSize = const Size(320, 900);
    tester.view.devicePixelRatio = 1;
    tester.platformDispatcher.textScaleFactorTestValue = 1.3;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    final clinic = _clinicCubit();
    final schedule = _scheduleCubit();

    await tester.pumpWidget(_app(clinic, schedule, locale: const Locale('ar')));
    await tester.pump();
    expect(tester.takeException(), isNull);

    await tester.tap(find.text('تعديل الجدول الأسبوعي'));
    await tester.pumpAndSettle();
    expect(find.byType(FilterChip), findsNWidgets(7));
    expect(tester.takeException(), isNull);
  });
}

_MockClinicCubit _clinicCubit() {
  final cubit = _MockClinicCubit();
  when(() => cubit.stream).thenAnswer((_) => const Stream.empty());
  when(() => cubit.state).thenReturn(
    const ClinicState(
      status: ClinicStatus.ready,
      activeClinicId: 'clinic-1',
      memberships: [
        ClinicMembership(
          clinic: Clinic(
            id: 'clinic-1',
            name: 'Bright Dental',
            currencyCode: 'USD',
            timeZone: 'Asia/Damascus',
          ),
          memberId: 'dentist-1',
          roles: {'owner', 'dentist'},
        ),
      ],
    ),
  );
  return cubit;
}

_MockScheduleCubit _scheduleCubit() {
  final now = DateTime.now();
  String formatDate(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
  final historyDate = formatDate(now.subtract(const Duration(days: 14)));
  final activeDate = formatDate(now.subtract(const Duration(days: 1)));
  final upcomingDate = formatDate(now.add(const Duration(days: 7)));

  final cubit = _MockScheduleCubit();
  when(() => cubit.stream).thenAnswer((_) => const Stream.empty());
  when(() => cubit.load(any())).thenAnswer((_) async {});
  when(() => cubit.state).thenReturn(
    ScheduleState(
      status: ScheduleStatus.ready,
      clinicId: 'clinic-1',
      dentists: const [
        ScheduleDentist(memberId: 'dentist-1', displayName: 'Dr. Morgan'),
      ],
      versions: [
        DoctorScheduleVersion(
          id: 'history',
          clinicId: 'clinic-1',
          dentistMemberId: 'dentist-1',
          effectiveFrom: historyDate,
          workingPeriods: const [],
        ),
        DoctorScheduleVersion(
          id: 'active',
          clinicId: 'clinic-1',
          dentistMemberId: 'dentist-1',
          effectiveFrom: activeDate,
          workingPeriods: const [
            DoctorWorkingPeriod(
              id: 'hours-1',
              weekday: 1,
              startsAt: '09:00',
              endsAt: '17:00',
              breaks: [],
            ),
          ],
        ),
        DoctorScheduleVersion(
          id: 'upcoming',
          clinicId: 'clinic-1',
          dentistMemberId: 'dentist-1',
          effectiveFrom: upcomingDate,
          workingPeriods: const [
            DoctorWorkingPeriod(
              id: 'hours-2',
              weekday: 1,
              startsAt: '10:00',
              endsAt: '18:00',
              breaks: [],
            ),
          ],
        ),
      ],
    ),
  );
  return cubit;
}

Widget _app(
  ClinicCubit clinic,
  ScheduleCubit schedule, {
  Locale locale = const Locale('en'),
}) => MultiBlocProvider(
  providers: [
    BlocProvider<ClinicCubit>.value(value: clinic),
    BlocProvider<ScheduleCubit>.value(value: schedule),
  ],
  child: MaterialApp(
    theme: AppTheme.light,
    locale: locale,
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    home: const DoctorSchedulePage(),
  ),
);

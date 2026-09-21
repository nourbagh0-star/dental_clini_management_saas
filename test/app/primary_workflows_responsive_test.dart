import 'package:dental_clini_management_saas/app/localization/generated/app_localizations.dart';
import 'package:dental_clini_management_saas/app/theme/app_theme.dart';
import 'package:dental_clini_management_saas/features/appointment/presentation/appointment_cubit.dart';
import 'package:dental_clini_management_saas/features/appointment/presentation/pages/appointment_pages.dart';
import 'package:dental_clini_management_saas/features/clinic/domain/clinic_models.dart';
import 'package:dental_clini_management_saas/features/clinic/presentation/clinic_cubit.dart';
import 'package:dental_clini_management_saas/features/patient/domain/patient_models.dart';
import 'package:dental_clini_management_saas/features/patient/presentation/pages/patient_pages.dart';
import 'package:dental_clini_management_saas/features/patient/presentation/patient_cubit.dart';
import 'package:dental_clini_management_saas/features/patient/presentation/patient_medical_cubit.dart';
import 'package:dental_clini_management_saas/features/schedule/presentation/schedule_cubit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockClinicCubit extends Mock implements ClinicCubit {}

class _MockPatientCubit extends Mock implements PatientCubit {}

class _MockAppointmentCubit extends Mock implements AppointmentCubit {}

class _MockScheduleCubit extends Mock implements ScheduleCubit {}

class _MockPatientMedicalCubit extends Mock implements PatientMedicalCubit {}

void main() {
  testWidgets(
    'new patient form keeps separated fields on a narrow Arabic view',
    (tester) async {
      tester.view.physicalSize = const Size(320, 900);
      tester.view.devicePixelRatio = 1;
      tester.platformDispatcher.textScaleFactorTestValue = 2;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
      final patient = _patientCubit(const PatientState());

      await tester.pumpWidget(
        BlocProvider<PatientCubit>.value(
          value: patient,
          child: _localizedApp(const NewPatientPage(), const Locale('ar')),
        ),
      );
      await tester.pumpAndSettle();

      final fields = find.byType(TextFormField);
      final first = tester.getRect(fields.at(0));
      final last = tester.getRect(fields.at(1));
      expect(last.top, greaterThan(first.bottom));
      expect(find.text('مريض جديد'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('patient collection becomes a table at desktop content width', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1200, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final clinic = _clinicCubit();
    final patient = _patientCubit(
      const PatientState(
        status: PatientStatus.ready,
        clinicId: 'clinic-1',
        patients: [
          Patient(
            id: 'patient-1',
            clinicId: 'clinic-1',
            patientNumber: 'P-0001',
            firstName: 'Demo',
            lastName: 'Patient',
            phone: '+10000000000',
            birthDatePrecision: BirthDatePrecision.unknown,
            isMinorDeclared: false,
            isArchived: false,
          ),
        ],
      ),
    );

    await tester.pumpWidget(
      MultiBlocProvider(
        providers: [
          BlocProvider<ClinicCubit>.value(value: clinic),
          BlocProvider<PatientCubit>.value(value: patient),
        ],
        child: _localizedApp(const PatientsPage()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byType(DataTable), findsOneWidget);
    expect(find.text('Demo Patient'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('mobile appointment view loads a one-day agenda range', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final clinic = _clinicCubit();
    final appointment = _MockAppointmentCubit();
    final schedule = _MockScheduleCubit();
    when(() => appointment.stream).thenAnswer((_) => const Stream.empty());
    when(
      () => appointment.state,
    ).thenReturn(const AppointmentState(status: AppointmentLoadStatus.ready));
    when(
      () => appointment.load(
        clinicId: any(named: 'clinicId'),
        from: any(named: 'from'),
        until: any(named: 'until'),
      ),
    ).thenAnswer((_) async {});
    when(() => schedule.stream).thenAnswer((_) => const Stream.empty());
    when(() => schedule.state).thenReturn(const ScheduleState());
    when(() => schedule.load(any())).thenAnswer((_) async {});

    await tester.pumpWidget(
      MultiBlocProvider(
        providers: [
          BlocProvider<ClinicCubit>.value(value: clinic),
          BlocProvider<AppointmentCubit>.value(value: appointment),
          BlocProvider<ScheduleCubit>.value(value: schedule),
        ],
        child: _localizedApp(const AppointmentCalendarPage()),
      ),
    );
    await tester.pump();

    final calls = verify(
      () => appointment.load(
        clinicId: 'clinic-1',
        from: captureAny(named: 'from'),
        until: captureAny(named: 'until'),
      ),
    ).captured.cast<DateTime>();
    expect(calls[1].difference(calls[0]), const Duration(days: 1));
    expect(find.byTooltip('Today'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('medical profile stays readable on a wide desktop', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1800, 1000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final clinic = _clinicCubit(roles: const {'dentist'});
    final medical = _MockPatientMedicalCubit();
    when(() => medical.stream).thenAnswer((_) => const Stream.empty());
    when(
      () => medical.state,
    ).thenReturn(const PatientMedicalState(profile: PatientMedicalProfile()));
    when(() => medical.load(any())).thenAnswer((_) async {});

    await tester.pumpWidget(
      MultiBlocProvider(
        providers: [
          BlocProvider<ClinicCubit>.value(value: clinic),
          BlocProvider<PatientMedicalCubit>.value(value: medical),
        ],
        child: _localizedApp(const PatientMedicalPage(patientId: 'patient-1')),
      ),
    );
    await tester.pump();

    final firstField = tester.getRect(find.byType(TextField).first);
    final saveButton = tester.getRect(
      find.widgetWithText(FilledButton, 'Save medical profile'),
    );
    expect(firstField.width, lessThanOrEqualTo(AppSpacing.contentWidth));
    expect(saveButton.width, lessThanOrEqualTo(240));
    expect(tester.takeException(), isNull);
  });
}

_MockClinicCubit _clinicCubit({Set<String> roles = const {'owner'}}) {
  final cubit = _MockClinicCubit();
  when(() => cubit.stream).thenAnswer((_) => const Stream.empty());
  when(() => cubit.state).thenReturn(
    ClinicState(
      status: ClinicStatus.ready,
      activeClinicId: 'clinic-1',
      memberships: [
        ClinicMembership(
          clinic: const Clinic(
            id: 'clinic-1',
            name: 'Demo Clinic',
            currencyCode: 'USD',
            timeZone: 'Etc/UTC',
          ),
          roles: roles,
        ),
      ],
    ),
  );
  return cubit;
}

_MockPatientCubit _patientCubit(PatientState state) {
  final cubit = _MockPatientCubit();
  when(() => cubit.stream).thenAnswer((_) => const Stream.empty());
  when(() => cubit.state).thenReturn(state);
  when(
    () => cubit.load(any(), query: any(named: 'query')),
  ).thenAnswer((_) async {});
  return cubit;
}

Widget _localizedApp(Widget home, [Locale locale = const Locale('en')]) =>
    MaterialApp(
      theme: AppTheme.light,
      locale: locale,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: home,
    );

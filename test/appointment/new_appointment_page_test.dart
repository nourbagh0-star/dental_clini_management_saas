import 'package:dental_clini_management_saas/app/localization/generated/app_localizations.dart';
import 'package:dental_clini_management_saas/app/theme/app_theme.dart';
import 'package:dental_clini_management_saas/core/error/app_failure.dart';
import 'package:dental_clini_management_saas/features/appointment/presentation/appointment_cubit.dart';
import 'package:dental_clini_management_saas/features/appointment/presentation/pages/appointment_pages.dart';
import 'package:dental_clini_management_saas/features/clinic/domain/clinic_models.dart';
import 'package:dental_clini_management_saas/features/clinic/presentation/clinic_cubit.dart';
import 'package:dental_clini_management_saas/features/patient/domain/patient_models.dart';
import 'package:dental_clini_management_saas/features/patient/presentation/patient_cubit.dart';
import 'package:dental_clini_management_saas/features/schedule/domain/schedule_models.dart';
import 'package:dental_clini_management_saas/features/schedule/presentation/schedule_cubit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockClinicCubit extends Mock implements ClinicCubit {}

class _MockPatientCubit extends Mock implements PatientCubit {}

class _MockScheduleCubit extends Mock implements ScheduleCubit {}

class _MockAppointmentCubit extends Mock implements AppointmentCubit {}

void main() {
  testWidgets('loads dentists directly and selects the only dentist', (
    tester,
  ) async {
    final clinic = _clinicCubit();
    final patient = _patientCubit(
      const PatientState(
        status: PatientStatus.ready,
        clinicId: 'clinic-1',
        patients: [_patient],
      ),
    );
    final schedule = _scheduleCubit(
      const ScheduleState(
        status: ScheduleStatus.ready,
        clinicId: 'clinic-1',
        dentists: [
          ScheduleDentist(memberId: 'dentist-1', displayName: 'Dr. Morgan'),
        ],
      ),
    );
    final appointment = _appointmentCubit();

    await tester.pumpWidget(_app(clinic, patient, schedule, appointment));
    await tester.pump();

    verify(() => schedule.load('clinic-1')).called(1);
    final dropdown = tester.widget<DropdownButtonFormField<String>>(
      find.byType(DropdownButtonFormField<String>),
    );
    expect(dropdown.initialValue, 'dentist-1');
    expect(find.text('Dr. Morgan'), findsOneWidget);

    await tester.tap(find.text('Demo Patient'));
    await tester.pump();
    final create = tester.widget<FilledButton>(
      find.widgetWithText(FilledButton, 'Create appointment'),
    );
    expect(create.onPressed, isNotNull);
    expect(tester.takeException(), isNull);
  });

  testWidgets('shows an Arabic retry state without overflowing on a phone', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 900);
    tester.view.devicePixelRatio = 1;
    tester.platformDispatcher.textScaleFactorTestValue = 1.3;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    final clinic = _clinicCubit();
    final patient = _patientCubit(const PatientState());
    final schedule = _scheduleCubit(
      const ScheduleState(
        status: ScheduleStatus.failure,
        clinicId: 'clinic-1',
        failure: NetworkFailure(),
      ),
    );
    final appointment = _appointmentCubit();

    await tester.pumpWidget(
      _app(clinic, patient, schedule, appointment, locale: const Locale('ar')),
    );
    await tester.pump();

    expect(find.text('المحاولة مرة أخرى'), findsOneWidget);
    await tester.tap(find.text('المحاولة مرة أخرى'));
    await tester.pump();
    verify(() => schedule.load('clinic-1')).called(2);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'displays selected patient card with change button, and tapping change resets patient selection',
    (tester) async {
      final clinic = _clinicCubit();
      final patient = _patientCubit(
        const PatientState(
          status: PatientStatus.ready,
          clinicId: 'clinic-1',
          patients: [_patient],
        ),
      );
      final schedule = _scheduleCubit(
        const ScheduleState(
          status: ScheduleStatus.ready,
          clinicId: 'clinic-1',
          dentists: [
            ScheduleDentist(memberId: 'dentist-1', displayName: 'Dr. Morgan'),
          ],
        ),
      );
      final appointment = _appointmentCubit();

      await tester.pumpWidget(_app(clinic, patient, schedule, appointment));
      await tester.pump();

      expect(find.byIcon(Icons.search), findsOneWidget);
      expect(find.text('Change patient'), findsNothing);

      await tester.tap(find.text('Demo Patient'));
      await tester.pump();

      expect(find.text('Change patient'), findsOneWidget);
      expect(find.byIcon(Icons.search), findsNothing);

      await tester.tap(find.text('Change patient'));
      await tester.pump();

      expect(find.text('Change patient'), findsNothing);
      expect(find.byIcon(Icons.search), findsOneWidget);
    },
  );

  testWidgets('tapping quick reason chip populates and clears purpose field', (
    tester,
  ) async {
    final clinic = _clinicCubit();
    final patient = _patientCubit(
      const PatientState(
        status: PatientStatus.ready,
        clinicId: 'clinic-1',
        patients: [_patient],
      ),
    );
    final schedule = _scheduleCubit(
      const ScheduleState(
        status: ScheduleStatus.ready,
        clinicId: 'clinic-1',
        dentists: [
          ScheduleDentist(memberId: 'dentist-1', displayName: 'Dr. Morgan'),
        ],
      ),
    );
    final appointment = _appointmentCubit();

    await tester.pumpWidget(_app(clinic, patient, schedule, appointment));
    await tester.pump();

    final chipFinder = find.widgetWithText(ActionChip, 'Routine Checkup');
    expect(chipFinder, findsOneWidget);
    await tester.ensureVisible(chipFinder);
    await tester.pumpAndSettle();
    await tester.tap(chipFinder);
    await tester.pump();

    expect(
      find.widgetWithText(TextFormField, 'Routine Checkup'),
      findsOneWidget,
    );

    await tester.tap(chipFinder);
    await tester.pump();

    expect(find.widgetWithText(TextFormField, 'Routine Checkup'), findsNothing);
  });

  testWidgets(
    'displays warning when doctor has no working schedule configured',
    (tester) async {
      final clinic = _clinicCubit();
      final patient = _patientCubit(const PatientState());
      final schedule = _scheduleCubit(
        const ScheduleState(
          status: ScheduleStatus.ready,
          clinicId: 'clinic-1',
          dentists: [
            ScheduleDentist(memberId: 'dentist-1', displayName: 'Dr. Morgan'),
          ],
          versions: [],
        ),
      );
      final appointment = _appointmentCubit();

      await tester.pumpWidget(_app(clinic, patient, schedule, appointment));
      await tester.pump();

      expect(
        find.text('Doctor has no working schedule configured in this clinic'),
        findsOneWidget,
      );
    },
  );

  testWidgets('displays doctor working hours when scheduled', (tester) async {
    final clinic = _clinicCubit();
    final patient = _patientCubit(
      const PatientState(
        status: PatientStatus.ready,
        clinicId: 'clinic-1',
        patients: [_patient],
      ),
    );
    final schedule = _scheduleCubit(
      ScheduleState(
        status: ScheduleStatus.ready,
        clinicId: 'clinic-1',
        dentists: const [
          ScheduleDentist(memberId: 'dentist-1', displayName: 'Dr. Morgan'),
        ],
        versions: [
          DoctorScheduleVersion(
            id: 'dsv-1',
            clinicId: 'clinic-1',
            dentistMemberId: 'dentist-1',
            effectiveFrom: '2000-01-01',
            workingPeriods: [
              DoctorWorkingPeriod(
                id: 'wp-1',
                weekday: DateTime.now().weekday,
                startsAt: '09:00',
                endsAt: '17:00',
                breaks: const [],
              ),
            ],
          ),
        ],
      ),
    );
    final appointment = _appointmentCubit();

    await tester.pumpWidget(_app(clinic, patient, schedule, appointment));
    await tester.pump();

    expect(find.textContaining('09:00 – 17:00'), findsOneWidget);
  });

  testWidgets('displays doctor leave badge when doctor has an exception', (
    tester,
  ) async {
    final clinic = _clinicCubit();
    final patient = _patientCubit(
      const PatientState(
        status: PatientStatus.ready,
        clinicId: 'clinic-1',
        patients: [_patient],
      ),
    );
    final schedule = _scheduleCubit(
      ScheduleState(
        status: ScheduleStatus.ready,
        clinicId: 'clinic-1',
        dentists: const [
          ScheduleDentist(memberId: 'dentist-1', displayName: 'Dr. Morgan'),
        ],
        exceptions: [
          DoctorScheduleException(
            id: 'exc-1',
            clinicId: 'clinic-1',
            dentistMemberId: 'dentist-1',
            kind: ScheduleExceptionKind.leave,
            startsAt: DateTime.now().subtract(const Duration(days: 1)),
            endsAt: DateTime.now().add(const Duration(days: 1)),
            reason: 'Annual vacation',
          ),
        ],
      ),
    );
    final appointment = _appointmentCubit();

    await tester.pumpWidget(_app(clinic, patient, schedule, appointment));
    await tester.pump();

    expect(find.textContaining('Doctor is on leave'), findsOneWidget);
    expect(find.textContaining('Annual vacation'), findsOneWidget);
  });

  testWidgets('pre-selects patient card when initialPatientId is provided', (
    tester,
  ) async {
    final clinic = _clinicCubit();
    final patient = _patientCubit(
      const PatientState(
        status: PatientStatus.ready,
        clinicId: 'clinic-1',
        patients: [_patient],
      ),
    );
    final schedule = _scheduleCubit(
      const ScheduleState(
        status: ScheduleStatus.ready,
        clinicId: 'clinic-1',
        dentists: [
          ScheduleDentist(memberId: 'dentist-1', displayName: 'Dr. Morgan'),
        ],
      ),
    );
    final appointment = _appointmentCubit();

    await tester.pumpWidget(
      _app(
        clinic,
        patient,
        schedule,
        appointment,
        initialPatientId: 'patient-1',
      ),
    );
    await tester.pump();

    expect(find.text('Demo Patient'), findsOneWidget);
    expect(find.text('Change patient'), findsOneWidget);
    expect(find.byIcon(Icons.search), findsNothing);
  });
}

const _patient = Patient(
  id: 'patient-1',
  clinicId: 'clinic-1',
  patientNumber: 'P-0001',
  firstName: 'Demo',
  lastName: 'Patient',
  phone: '+963900000000',
  birthDatePrecision: BirthDatePrecision.unknown,
  isMinorDeclared: false,
  isArchived: false,
);

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

_MockPatientCubit _patientCubit(PatientState state) {
  final cubit = _MockPatientCubit();
  when(() => cubit.stream).thenAnswer((_) => const Stream.empty());
  when(() => cubit.state).thenReturn(state);
  when(
    () => cubit.load(any(), query: any(named: 'query')),
  ).thenAnswer((_) async {});
  return cubit;
}

_MockScheduleCubit _scheduleCubit(ScheduleState state) {
  final cubit = _MockScheduleCubit();
  when(() => cubit.stream).thenAnswer((_) => const Stream.empty());
  when(() => cubit.state).thenReturn(state);
  when(() => cubit.load(any())).thenAnswer((_) async {});
  return cubit;
}

_MockAppointmentCubit _appointmentCubit() {
  final cubit = _MockAppointmentCubit();
  when(() => cubit.stream).thenAnswer((_) => const Stream.empty());
  when(() => cubit.state).thenReturn(const AppointmentState());
  return cubit;
}

Widget _app(
  ClinicCubit clinic,
  PatientCubit patient,
  ScheduleCubit schedule,
  AppointmentCubit appointment, {
  Locale locale = const Locale('en'),
  String? initialPatientId,
}) => MultiBlocProvider(
  providers: [
    BlocProvider<ClinicCubit>.value(value: clinic),
    BlocProvider<PatientCubit>.value(value: patient),
    BlocProvider<ScheduleCubit>.value(value: schedule),
    BlocProvider<AppointmentCubit>.value(value: appointment),
  ],
  child: MaterialApp(
    theme: AppTheme.light,
    locale: locale,
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    home: NewAppointmentPage(initialPatientId: initialPatientId),
  ),
);

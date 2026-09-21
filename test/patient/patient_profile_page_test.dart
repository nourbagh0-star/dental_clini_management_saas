import 'package:dental_clini_management_saas/app/localization/generated/app_localizations.dart';
import 'package:dental_clini_management_saas/features/clinic/domain/clinic_models.dart';
import 'package:dental_clini_management_saas/features/clinic/presentation/clinic_cubit.dart';
import 'package:dental_clini_management_saas/features/patient/domain/patient_models.dart';
import 'package:dental_clini_management_saas/features/patient/presentation/pages/patient_pages.dart';
import 'package:dental_clini_management_saas/features/patient/presentation/patient_cubit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockClinicCubit extends Mock implements ClinicCubit {}

class _MockPatientCubit extends Mock implements PatientCubit {}

void main() {
  const clinic = Clinic(
    id: 'clinic-1',
    name: 'Demo Dental Clinic',
    currencyCode: 'USD',
    timeZone: 'Etc/UTC',
  );

  Widget createWidget({
    required ClinicCubit clinicCubit,
    required PatientCubit patientCubit,
    required String patientId,
    Locale locale = const Locale('en'),
  }) {
    return MaterialApp(
      locale: locale,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: MultiBlocProvider(
        providers: [
          BlocProvider<ClinicCubit>.value(value: clinicCubit),
          BlocProvider<PatientCubit>.value(value: patientCubit),
        ],
        child: PatientProfilePage(patientId: patientId),
      ),
    );
  }

  void stub({
    required _MockClinicCubit clinicCubit,
    required _MockPatientCubit patientCubit,
    required Patient patient,
    Set<String> roles = const {'owner', 'dentist', 'receptionist'},
  }) {
    when(() => clinicCubit.stream).thenAnswer((_) => const Stream.empty());
    when(() => patientCubit.stream).thenAnswer((_) => const Stream.empty());
    when(() => clinicCubit.state).thenReturn(
      ClinicState(
        status: ClinicStatus.ready,
        memberships: [
          ClinicMembership(clinic: clinic, memberId: 'm1', roles: roles),
        ],
        activeClinicId: clinic.id,
      ),
    );
    when(() => patientCubit.state).thenReturn(
      PatientState(
        status: PatientStatus.ready,
        clinicId: clinic.id,
        patients: [patient],
      ),
    );
  }

  testWidgets('renders patient header card, avatar, badges, and both phone & email', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1024, 1600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final clinicCubit = _MockClinicCubit();
    final patientCubit = _MockPatientCubit();

    const patient = Patient(
      id: 'patient-1',
      clinicId: 'clinic-1',
      patientNumber: 'PAT-00042',
      firstName: 'Sara',
      middleName: 'Ahmad',
      lastName: 'Al-Ali',
      phone: '+963991234567',
      email: 'sara@example.com',
      birthDatePrecision: BirthDatePrecision.exact,
      birthDate: '1998-05-14',
      isMinorDeclared: false,
      isArchived: false,
      administrativeNotes: 'Patient has high dental anxiety',
    );

    stub(
      clinicCubit: clinicCubit,
      patientCubit: patientCubit,
      patient: patient,
    );

    await tester.pumpWidget(
      createWidget(
        clinicCubit: clinicCubit,
        patientCubit: patientCubit,
        patientId: 'patient-1',
      ),
    );
    await tester.pumpAndSettle();

    // Initials SA
    expect(find.text('SA'), findsOneWidget);
    // Full name
    expect(find.text('Sara Ahmad Al-Ali'), findsOneWidget);
    // Patient number badge
    expect(find.text('#PAT-00042'), findsOneWidget);
    // Active badge
    expect(find.text('Active'), findsOneWidget);

    // Both phone AND email are displayed
    expect(find.text('+963991234567'), findsOneWidget);
    expect(find.text('sara@example.com'), findsOneWidget);

    // Communication action buttons
    expect(find.byIcon(Icons.call_outlined), findsAtLeastNWidgets(1));
    expect(find.byIcon(Icons.chat_bubble_outline_rounded), findsAtLeastNWidgets(1));
    expect(find.byIcon(Icons.email_outlined), findsAtLeastNWidgets(1));

    // Administrative notes card is displayed
    expect(find.text('Patient has high dental anxiety'), findsOneWidget);

    // Action hubs
    expect(find.text('Clinical Records & Treatment'), findsOneWidget);
    expect(find.text('Administration & Appointments'), findsOneWidget);
    expect(find.text('Dental Chart'), findsOneWidget);
    expect(find.text('Treatment plans'), findsOneWidget);
    expect(find.text('Book Appointment'), findsOneWidget);
  });

  testWidgets('renders guardian section when patient is minor', (tester) async {
    tester.view.physicalSize = const Size(1024, 1600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final clinicCubit = _MockClinicCubit();
    final patientCubit = _MockPatientCubit();

    const minorPatient = Patient(
      id: 'patient-child',
      clinicId: 'clinic-1',
      patientNumber: 'PAT-00099',
      firstName: 'Omar',
      lastName: 'Hassan',
      birthDatePrecision: BirthDatePrecision.approximate,
      approximateAgeYears: 9,
      isMinorDeclared: true,
      isArchived: false,
      guardianName: 'Hassan Ali',
      guardianPhone: '+963998888888',
      guardianEmail: 'guardian@example.com',
    );

    stub(
      clinicCubit: clinicCubit,
      patientCubit: patientCubit,
      patient: minorPatient,
    );

    await tester.pumpWidget(
      createWidget(
        clinicCubit: clinicCubit,
        patientCubit: patientCubit,
        patientId: 'patient-child',
      ),
    );
    await tester.pumpAndSettle();

    // Minor badge
    expect(find.text('Minor'), findsOneWidget);

    // Guardian section visible
    expect(find.text('Parent / Guardian Contact (Minor)'), findsOneWidget);
    expect(find.text('Hassan Ali'), findsOneWidget);
    expect(find.text('+963998888888'), findsOneWidget);
    expect(find.text('guardian@example.com'), findsOneWidget);
  });

  testWidgets('does not show guardian section for adult patient', (tester) async {
    final clinicCubit = _MockClinicCubit();
    final patientCubit = _MockPatientCubit();

    const adultPatient = Patient(
      id: 'patient-adult',
      clinicId: 'clinic-1',
      patientNumber: 'PAT-00100',
      firstName: 'Kareem',
      lastName: 'Nasser',
      birthDatePrecision: BirthDatePrecision.exact,
      birthDate: '1985-01-01',
      isMinorDeclared: false,
      isArchived: false,
    );

    stub(
      clinicCubit: clinicCubit,
      patientCubit: patientCubit,
      patient: adultPatient,
    );

    await tester.pumpWidget(
      createWidget(
        clinicCubit: clinicCubit,
        patientCubit: patientCubit,
        patientId: 'patient-adult',
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Minor'), findsNothing);
    expect(find.text('Parent / Guardian Contact (Minor)'), findsNothing);
  });

  testWidgets('renders Arabic profile on a narrow screen without flex overflow', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 900);
    tester.view.devicePixelRatio = 1;
    tester.platformDispatcher.textScaleFactorTestValue = 2;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);

    final clinicCubit = _MockClinicCubit();
    final patientCubit = _MockPatientCubit();

    const patient = Patient(
      id: 'patient-ar',
      clinicId: 'clinic-1',
      patientNumber: 'PAT-00077',
      firstName: 'نور',
      middleName: 'الدين',
      lastName: 'الحلبي',
      phone: '+963991112233',
      email: 'nour@example.com',
      birthDatePrecision: BirthDatePrecision.exact,
      birthDate: '2010-06-15',
      isMinorDeclared: true,
      isArchived: false,
      guardianName: 'أحمد الحلبي',
      guardianPhone: '+963994445566',
      administrativeNotes: 'يفضل المواعيد المسائية',
    );

    stub(
      clinicCubit: clinicCubit,
      patientCubit: patientCubit,
      patient: patient,
    );

    await tester.pumpWidget(
      createWidget(
        clinicCubit: clinicCubit,
        patientCubit: patientCubit,
        patientId: 'patient-ar',
        locale: const Locale('ar'),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('نور الدين الحلبي'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}

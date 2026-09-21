import 'package:dental_clini_management_saas/app/localization/generated/app_localizations.dart';
import 'package:dental_clini_management_saas/features/clinical_session/domain/clinical_session_models.dart';
import 'package:dental_clini_management_saas/features/clinical_session/presentation/clinical_session_cubit.dart';
import 'package:dental_clini_management_saas/features/clinical_session/presentation/pages/clinical_session_pages.dart';
import 'package:dental_clini_management_saas/features/clinic/domain/clinic_models.dart';
import 'package:dental_clini_management_saas/features/clinic/presentation/clinic_cubit.dart';
import 'package:dental_clini_management_saas/features/patient/domain/patient_models.dart';
import 'package:dental_clini_management_saas/features/patient/presentation/patient_cubit.dart';
import 'package:dental_clini_management_saas/features/staff/presentation/staff_cubit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockClinicCubit extends Mock implements ClinicCubit {}

class _MockPatientCubit extends Mock implements PatientCubit {}

class _MockStaffCubit extends Mock implements StaffCubit {}

class _MockClinicalSessionCubit extends Mock implements ClinicalSessionCubit {}

void main() {
  const patient = Patient(
    id: 'patient-1',
    clinicId: 'clinic-1',
    patientNumber: 'PAT-00001',
    firstName: 'Demo',
    lastName: 'Patient',
    birthDatePrecision: BirthDatePrecision.unknown,
    isMinorDeclared: false,
    isArchived: false,
  );
  const clinic = Clinic(
    id: 'clinic-1',
    name: 'Demo Clinic',
    currencyCode: 'RUB',
    timeZone: 'Europe/Moscow',
  );

  testWidgets('receptionist cannot open clinical session content', (
    tester,
  ) async {
    final clinicCubit = _MockClinicCubit();
    final patientCubit = _MockPatientCubit();
    when(() => clinicCubit.stream).thenAnswer((_) => const Stream.empty());
    when(() => patientCubit.stream).thenAnswer((_) => const Stream.empty());
    when(() => clinicCubit.state).thenReturn(
      const ClinicState(
        status: ClinicStatus.ready,
        memberships: [
          ClinicMembership(
            clinic: clinic,
            memberId: 'reception-1',
            roles: {'receptionist'},
          ),
        ],
        activeClinicId: 'clinic-1',
      ),
    );
    when(() => patientCubit.state).thenReturn(
      const PatientState(
        status: PatientStatus.ready,
        clinicId: 'clinic-1',
        patients: [patient],
      ),
    );

    await tester.pumpWidget(
      MultiBlocProvider(
        providers: [
          BlocProvider<ClinicCubit>.value(value: clinicCubit),
          BlocProvider<PatientCubit>.value(value: patientCubit),
        ],
        child: const _LocalizedTestApp(
          locale: Locale('en'),
          child: ClinicalSessionsPage(patientId: 'patient-1'),
        ),
      ),
    );

    expect(find.text('This clinical session is unavailable.'), findsOneWidget);
    expect(find.text('Clinical notes'), findsNothing);
  });

  testWidgets('Arabic finalized visit fits a narrow phone screen', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final clinicCubit = _MockClinicCubit();
    final patientCubit = _MockPatientCubit();
    final staffCubit = _MockStaffCubit();
    final sessionCubit = _MockClinicalSessionCubit();
    when(() => clinicCubit.stream).thenAnswer((_) => const Stream.empty());
    when(() => patientCubit.stream).thenAnswer((_) => const Stream.empty());
    when(() => staffCubit.stream).thenAnswer((_) => const Stream.empty());
    when(() => sessionCubit.stream).thenAnswer((_) => const Stream.empty());
    when(() => clinicCubit.state).thenReturn(
      const ClinicState(
        status: ClinicStatus.ready,
        memberships: [
          ClinicMembership(
            clinic: clinic,
            memberId: 'owner-1',
            roles: {'owner'},
          ),
        ],
        activeClinicId: 'clinic-1',
      ),
    );
    when(() => patientCubit.state).thenReturn(
      const PatientState(
        status: PatientStatus.ready,
        clinicId: 'clinic-1',
        patients: [patient],
      ),
    );
    when(() => staffCubit.state).thenReturn(const StaffState());
    when(() => staffCubit.load(any())).thenAnswer((_) async {});
    final session = ClinicalSession(
      id: 'session-1',
      clinicId: 'clinic-1',
      patientId: 'patient-1',
      dentistMemberId: 'dentist-1',
      sessionDate: DateTime.utc(2026, 9, 9),
      clinicalNotes: 'ملاحظات سريرية تجريبية',
      recommendations: 'مراجعة بعد ستة أشهر',
      status: ClinicalSessionStatus.finalized,
      revision: 2,
      createdBy: 'user-1',
      updatedBy: 'user-1',
      finalizedBy: 'user-1',
      finalizedAt: DateTime.utc(2026, 9, 9),
      createdAt: DateTime.utc(2026, 9, 9),
      updatedAt: DateTime.utc(2026, 9, 9),
    );
    when(() => sessionCubit.state).thenReturn(
      ClinicalSessionState(
        status: ClinicalSessionLoadStatus.ready,
        patientId: 'patient-1',
        sessions: [session],
        selectedSessionId: 'session-1',
      ),
    );
    when(() => sessionCubit.load(any())).thenAnswer((_) async {});

    await tester.pumpWidget(
      MultiBlocProvider(
        providers: [
          BlocProvider<ClinicCubit>.value(value: clinicCubit),
          BlocProvider<PatientCubit>.value(value: patientCubit),
          BlocProvider<StaffCubit>.value(value: staffCubit),
          BlocProvider<ClinicalSessionCubit>.value(value: sessionCubit),
        ],
        child: const _LocalizedTestApp(
          locale: Locale('ar'),
          child: ClinicalSessionsPage(patientId: 'patient-1'),
        ),
      ),
    );
    await tester.pump();

    expect(find.text('الزيارات'), findsWidgets);
    expect(find.text('الملاحظات السريرية'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}

class _LocalizedTestApp extends StatelessWidget {
  const _LocalizedTestApp({required this.locale, required this.child});
  final Locale locale;
  final Widget child;

  @override
  Widget build(BuildContext context) => MaterialApp(
    locale: locale,
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    home: child,
  );
}

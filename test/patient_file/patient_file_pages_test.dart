import 'package:dental_clini_management_saas/app/localization/generated/app_localizations.dart';
import 'package:dental_clini_management_saas/features/clinical_session/presentation/clinical_session_cubit.dart';
import 'package:dental_clini_management_saas/features/clinic/domain/clinic_models.dart';
import 'package:dental_clini_management_saas/features/clinic/presentation/clinic_cubit.dart';
import 'package:dental_clini_management_saas/features/patient/domain/patient_models.dart';
import 'package:dental_clini_management_saas/features/patient/presentation/patient_cubit.dart';
import 'package:dental_clini_management_saas/features/patient_file/domain/patient_file_models.dart';
import 'package:dental_clini_management_saas/features/patient_file/presentation/pages/patient_file_pages.dart';
import 'package:dental_clini_management_saas/features/patient_file/presentation/patient_file_cubit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockClinicCubit extends Mock implements ClinicCubit {}

class _MockPatientCubit extends Mock implements PatientCubit {}

class _MockPatientFileCubit extends Mock implements PatientFileCubit {}

class _MockClinicalSessionCubit extends Mock implements ClinicalSessionCubit {}

void main() {
  const clinic = Clinic(
    id: 'clinic-1',
    name: 'Demo Clinic',
    currencyCode: 'RUB',
    timeZone: 'Europe/Moscow',
  );
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

  testWidgets('Receptionist cannot discover file metadata or actions', (
    tester,
  ) async {
    final clinicCubit = _MockClinicCubit();
    final patientCubit = _MockPatientCubit();
    _stubBase(clinicCubit, patientCubit, clinic, patient, const {
      'receptionist',
    });

    await tester.pumpWidget(
      MultiBlocProvider(
        providers: [
          BlocProvider<ClinicCubit>.value(value: clinicCubit),
          BlocProvider<PatientCubit>.value(value: patientCubit),
        ],
        child: const _LocalizedApp(
          locale: Locale('en'),
          child: PatientFilesPage(patientId: 'patient-1'),
        ),
      ),
    );

    expect(
      find.text('Patient files are restricted to authorized clinical staff.'),
      findsOneWidget,
    );
    expect(find.text('Upload file'), findsNothing);
  });

  testWidgets('Arabic file detail fits a narrow phone screen', (tester) async {
    tester.view.physicalSize = const Size(320, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final clinicCubit = _MockClinicCubit();
    final patientCubit = _MockPatientCubit();
    final fileCubit = _MockPatientFileCubit();
    final sessionCubit = _MockClinicalSessionCubit();
    _stubBase(clinicCubit, patientCubit, clinic, patient, const {'owner'});
    when(() => fileCubit.stream).thenAnswer((_) => const Stream.empty());
    when(() => sessionCubit.stream).thenAnswer((_) => const Stream.empty());
    final file = PatientFile(
      id: 'file-1',
      clinicId: 'clinic-1',
      patientId: 'patient-1',
      category: PatientFileCategory.xRay,
      originalFilename: 'demo.pdf',
      mimeType: 'application/pdf',
      sizeBytes: 1200,
      status: PatientFileStatus.available,
      uploadedBy: 'user-1',
      availableAt: DateTime.utc(2026, 9, 10),
      createdAt: DateTime.utc(2026, 9, 10),
    );
    when(() => fileCubit.state).thenReturn(
      PatientFileState(
        status: PatientFileLoadStatus.ready,
        patientId: 'patient-1',
        clinicId: 'clinic-1',
        files: [file],
        selectedFileId: 'file-1',
      ),
    );
    when(() => fileCubit.load(any(), any())).thenAnswer((_) async {});
    when(() => sessionCubit.state).thenReturn(const ClinicalSessionState());
    when(() => sessionCubit.load(any())).thenAnswer((_) async {});

    await tester.pumpWidget(
      MultiBlocProvider(
        providers: [
          BlocProvider<ClinicCubit>.value(value: clinicCubit),
          BlocProvider<PatientCubit>.value(value: patientCubit),
          BlocProvider<PatientFileCubit>.value(value: fileCubit),
          BlocProvider<ClinicalSessionCubit>.value(value: sessionCubit),
        ],
        child: const _LocalizedApp(
          locale: Locale('ar'),
          child: PatientFilesPage(patientId: 'patient-1'),
        ),
      ),
    );
    await tester.pump();

    expect(find.text('ملفات المريض'), findsOneWidget);
    expect(find.text('فتح PDF'), findsOneWidget);
    expect(find.text('أرشفة الملف'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}

void _stubBase(
  _MockClinicCubit clinicCubit,
  _MockPatientCubit patientCubit,
  Clinic clinic,
  Patient patient,
  Set<String> roles,
) {
  when(() => clinicCubit.stream).thenAnswer((_) => const Stream.empty());
  when(() => patientCubit.stream).thenAnswer((_) => const Stream.empty());
  when(() => clinicCubit.state).thenReturn(
    ClinicState(
      status: ClinicStatus.ready,
      memberships: [
        ClinicMembership(clinic: clinic, memberId: 'member-1', roles: roles),
      ],
      activeClinicId: 'clinic-1',
    ),
  );
  when(() => patientCubit.state).thenReturn(
    PatientState(
      status: PatientStatus.ready,
      clinicId: 'clinic-1',
      patients: [patient],
    ),
  );
}

class _LocalizedApp extends StatelessWidget {
  const _LocalizedApp({required this.locale, required this.child});
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

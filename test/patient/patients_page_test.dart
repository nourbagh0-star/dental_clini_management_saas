import 'package:dental_clini_management_saas/app/localization/generated/app_localizations.dart';
import 'package:dental_clini_management_saas/app/theme/app_theme.dart';
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
    name: 'Al-Amal Dental Center',
    currencyCode: 'USD',
    timeZone: 'Asia/Damascus',
  );

  const testPatients = [
    Patient(
      id: 'p1',
      clinicId: 'clinic-1',
      patientNumber: 'PAT-00001',
      firstName: 'Nour',
      lastName: 'Bagh',
      phone: '+79282916705',
      birthDatePrecision: BirthDatePrecision.exact,
      isMinorDeclared: false,
      isArchived: false,
      birthDate: '1995-04-12',
    ),
    Patient(
      id: 'p2',
      clinicId: 'clinic-1',
      patientNumber: 'PAT-00002',
      firstName: 'Sami',
      lastName: 'Ahmad',
      phone: '8696',
      birthDatePrecision: BirthDatePrecision.exact,
      isMinorDeclared: true,
      isArchived: false,
      birthDate: '2015-08-20',
    ),
    Patient(
      id: 'p3',
      clinicId: 'clinic-1',
      patientNumber: 'PAT-00003',
      firstName: 'Ola',
      lastName: 'Karim',
      phone: '96666',
      birthDatePrecision: BirthDatePrecision.unknown,
      isMinorDeclared: false,
      isArchived: true,
    ),
  ];

  testWidgets('PatientsPage renders separate cards with avatars, badges, and no overflows in Arabic mobile view', (tester) async {
    tester.view.physicalSize = const Size(360, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final mockClinic = _MockClinicCubit();
    final mockPatient = _MockPatientCubit();

    when(() => mockClinic.stream).thenAnswer((_) => const Stream.empty());
    when(() => mockClinic.state).thenReturn(
      const ClinicState(
        status: ClinicStatus.ready,
        activeClinicId: 'clinic-1',
        memberships: [
          ClinicMembership(clinic: clinic, roles: {'owner', 'dentist'}),
        ],
      ),
    );

    when(() => mockPatient.stream).thenAnswer((_) => const Stream.empty());
    when(() => mockPatient.state).thenReturn(
      const PatientState(
        status: PatientStatus.ready,
        clinicId: 'clinic-1',
        patients: testPatients,
      ),
    );
    when(() => mockPatient.load(any(), query: any(named: 'query'))).thenAnswer((_) async {});

    await tester.pumpWidget(
      MultiBlocProvider(
        providers: [
          BlocProvider<ClinicCubit>.value(value: mockClinic),
          BlocProvider<PatientCubit>.value(value: mockPatient),
        ],
        child: MaterialApp(
          theme: AppTheme.light,
          locale: const Locale('ar'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: const PatientsPage(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Verify patient names rendered
    expect(find.text('Nour Bagh'), findsOneWidget);
    expect(find.text('Sami Ahmad'), findsOneWidget);
    expect(find.text('Ola Karim'), findsOneWidget);

    // Verify file number badges
    expect(find.text('#PAT-00001'), findsOneWidget);
    expect(find.text('#PAT-00002'), findsOneWidget);
    expect(find.text('#PAT-00003'), findsOneWidget);

    // Verify minor badge
    expect(find.text('قاصر'), findsOneWidget);

    // Verify status badges
    expect(find.text('نشط'), findsNWidgets(2));
    expect(find.text('مؤرشف'), findsOneWidget);

    // Verify phone numbers
    expect(find.text('+79282916705'), findsOneWidget);
    expect(find.text('8696'), findsOneWidget);
    expect(find.text('96666'), findsOneWidget);

    // Verify search field has clear icon functionality
    await tester.enterText(find.byType(TextField), 'Nour');
    await tester.pumpAndSettle();
    expect(find.byIcon(Icons.clear), findsOneWidget);

    // Tap clear
    await tester.tap(find.byIcon(Icons.clear));
    await tester.pumpAndSettle();
    expect(find.text('Nour'), findsNothing);

    // Verify each patient card has a non-zero margin ensuring separation
    final cards = tester.widgetList<Card>(find.byType(Card));
    for (final card in cards) {
      expect(card.margin, equals(const EdgeInsets.only(bottom: 12)));
    }

    // No exception / no overflows
    expect(tester.takeException(), isNull);
  });
}

import 'package:dental_clini_management_saas/app/localization/generated/app_localizations.dart';
import 'package:dental_clini_management_saas/features/clinic/domain/clinic_models.dart';
import 'package:dental_clini_management_saas/features/clinic/presentation/clinic_cubit.dart';
import 'package:dental_clini_management_saas/features/patient/domain/patient_models.dart';
import 'package:dental_clini_management_saas/features/patient/presentation/patient_medical_cubit.dart';
import 'package:dental_clini_management_saas/features/patient/presentation/widgets/patient_medical_alert_banner.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockClinicCubit extends Mock implements ClinicCubit {}

class _MockPatientMedicalCubit extends Mock implements PatientMedicalCubit {}

void main() {
  const clinic = Clinic(
    id: 'clinic-1',
    name: 'Test Clinic',
    currencyCode: 'USD',
    timeZone: 'Etc/UTC',
  );

  late _MockClinicCubit clinicCubit;
  late _MockPatientMedicalCubit medicalCubit;

  setUp(() {
    clinicCubit = _MockClinicCubit();
    medicalCubit = _MockPatientMedicalCubit();

    when(() => clinicCubit.stream).thenAnswer((_) => const Stream.empty());
    when(() => medicalCubit.stream).thenAnswer((_) => const Stream.empty());

    when(() => clinicCubit.state).thenReturn(
      const ClinicState(
        status: ClinicStatus.ready,
        memberships: [
          ClinicMembership(
            clinic: clinic,
            memberId: 'm1',
            roles: {'owner', 'dentist'},
          ),
        ],
        activeClinicId: 'clinic-1',
      ),
    );
  });

  Widget createWidget({required String patientId, Locale locale = const Locale('en')}) {
    return MaterialApp(
      locale: locale,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(
        body: MultiBlocProvider(
          providers: [
            BlocProvider<ClinicCubit>.value(value: clinicCubit),
            BlocProvider<PatientMedicalCubit>.value(value: medicalCubit),
          ],
          child: PatientMedicalAlertBanner(patientId: patientId),
        ),
      ),
    );
  }

  group('PatientMedicalProfile domain helpers', () {
    test('hasAlerts is true when allergies or conditions exist', () {
      const p1 = PatientMedicalProfile(allergies: 'Penicillin');
      expect(p1.hasAlerts, isTrue);
      expect(p1.isEmpty, isFalse);

      const p2 = PatientMedicalProfile(chronicConditions: 'Asthma');
      expect(p2.hasAlerts, isTrue);
      expect(p2.isEmpty, isFalse);

      const p3 = PatientMedicalProfile(importantMedicalNotes: 'Pre-medicate');
      expect(p3.hasAlerts, isTrue);
      expect(p3.isEmpty, isFalse);
    });

    test('isEmpty is true when all fields are null or empty', () {
      const p1 = PatientMedicalProfile();
      expect(p1.isEmpty, isTrue);
      expect(p1.hasAlerts, isFalse);

      const p2 = PatientMedicalProfile(
        allergies: '   ',
        chronicConditions: '',
        currentMedications: null,
        importantMedicalNotes: ' ',
      );
      expect(p2.isEmpty, isTrue);
      expect(p2.hasAlerts, isFalse);
    });

    test('hasAlerts is false for medication-only profile', () {
      const p = PatientMedicalProfile(currentMedications: 'Vitamin C');
      expect(p.hasAlerts, isFalse);
      expect(p.isEmpty, isFalse);
    });
  });

  group('PatientMedicalAlertBanner widget', () {
    testWidgets('renders critical red alert banner when allergies and conditions exist', (
      tester,
    ) async {
      when(() => medicalCubit.state).thenReturn(
        const PatientMedicalState(
          patientId: 'pat-1',
          profile: PatientMedicalProfile(
            allergies: 'Penicillin, Aspirin',
            chronicConditions: 'Hypertension',
            importantMedicalNotes: 'Requires local anesthetic without epinephrine',
          ),
        ),
      );

      await tester.pumpWidget(createWidget(patientId: 'pat-1'));
      await tester.pumpAndSettle();

      expect(find.text('Medical & Allergy Alerts'), findsOneWidget);
      expect(find.textContaining('Penicillin, Aspirin'), findsOneWidget);
      expect(find.textContaining('Hypertension'), findsOneWidget);
      expect(
        find.textContaining('Requires local anesthetic without epinephrine'),
        findsOneWidget,
      );
      expect(find.byIcon(Icons.warning_amber_rounded), findsOneWidget);
      expect(find.text('Edit'), findsOneWidget);
    });

    testWidgets('renders green NKDA clean banner when no alerts exist', (
      tester,
    ) async {
      when(() => medicalCubit.state).thenReturn(
        const PatientMedicalState(
          patientId: 'pat-2',
          profile: PatientMedicalProfile(
            currentMedications: 'Multivitamins daily',
          ),
        ),
      );

      await tester.pumpWidget(createWidget(patientId: 'pat-2'));
      await tester.pumpAndSettle();

      expect(
        find.text('No known drug allergies or medical alerts'),
        findsOneWidget,
      );
      expect(find.byIcon(Icons.verified_outlined), findsOneWidget);
    });

    testWidgets('renders unscreened invitation banner when profile is empty or null', (
      tester,
    ) async {
      when(() => medicalCubit.state).thenReturn(
        const PatientMedicalState(
          patientId: 'pat-3',
          profile: null,
        ),
      );

      await tester.pumpWidget(createWidget(patientId: 'pat-3'));
      await tester.pumpAndSettle();

      expect(
        find.text(
          'No medical history recorded yet. Complete medical screening before clinical procedures.',
        ),
        findsOneWidget,
      );
      expect(find.text('Screen medical history'), findsOneWidget);
      expect(find.byIcon(Icons.health_and_safety_outlined), findsOneWidget);
    });

    testWidgets('does not render medical info for unauthorized receptionist role', (
      tester,
    ) async {
      when(() => clinicCubit.state).thenReturn(
        const ClinicState(
          status: ClinicStatus.ready,
          memberships: [
            ClinicMembership(
              clinic: clinic,
              memberId: 'm1',
              roles: {'receptionist'},
            ),
          ],
          activeClinicId: 'clinic-1',
        ),
      );

      when(() => medicalCubit.state).thenReturn(
        const PatientMedicalState(
          patientId: 'pat-1',
          profile: PatientMedicalProfile(allergies: 'Penicillin'),
        ),
      );

      await tester.pumpWidget(createWidget(patientId: 'pat-1'));
      await tester.pumpAndSettle();

      expect(find.text('Medical & Allergy Alerts'), findsNothing);
      expect(find.textContaining('Penicillin'), findsNothing);
    });

    testWidgets('renders Arabic alert banner properly', (tester) async {
      when(() => medicalCubit.state).thenReturn(
        const PatientMedicalState(
          patientId: 'pat-ar',
          profile: PatientMedicalProfile(allergies: 'بنسلين'),
        ),
      );

      await tester.pumpWidget(
        createWidget(patientId: 'pat-ar', locale: const Locale('ar')),
      );
      await tester.pumpAndSettle();

      expect(find.text('تنبيهات طبية وحساسية'), findsOneWidget);
      expect(find.textContaining('بنسلين'), findsOneWidget);
    });
  });
}

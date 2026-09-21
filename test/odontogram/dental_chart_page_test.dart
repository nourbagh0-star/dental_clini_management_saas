import 'package:dental_clini_management_saas/app/localization/generated/app_localizations.dart';
import 'package:dental_clini_management_saas/app/theme/app_theme.dart';
import 'package:dental_clini_management_saas/features/clinic/domain/clinic_models.dart';
import 'package:dental_clini_management_saas/features/clinic/presentation/clinic_cubit.dart';
import 'package:dental_clini_management_saas/features/odontogram/presentation/odontogram_cubit.dart';
import 'package:dental_clini_management_saas/features/odontogram/presentation/pages/dental_chart_page.dart';
import 'package:dental_clini_management_saas/features/patient/domain/patient_models.dart';
import 'package:dental_clini_management_saas/features/patient/presentation/patient_cubit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockClinicCubit extends Mock implements ClinicCubit {}

class _MockPatientCubit extends Mock implements PatientCubit {}

class _MockOdontogramCubit extends Mock implements OdontogramCubit {}

void main() {
  testWidgets('Arabic dental chart fits narrow large text with a dropdown', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 900);
    tester.view.devicePixelRatio = 1;
    tester.platformDispatcher.textScaleFactorTestValue = 2;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);

    final clinic = _MockClinicCubit();
    final patient = _MockPatientCubit();
    final odontogram = _MockOdontogramCubit();
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
              currencyCode: 'USD',
              timeZone: 'Etc/UTC',
            ),
            roles: {'dentist'},
          ),
        ],
      ),
    );
    when(() => patient.stream).thenAnswer((_) => const Stream.empty());
    when(() => patient.state).thenReturn(
      const PatientState(
        status: PatientStatus.ready,
        patients: [
          Patient(
            id: 'patient-1',
            clinicId: 'clinic-1',
            patientNumber: 'P-0001',
            firstName: 'Demo',
            lastName: 'Patient',
            birthDatePrecision: BirthDatePrecision.unknown,
            isMinorDeclared: false,
            isArchived: false,
          ),
        ],
      ),
    );
    when(() => odontogram.stream).thenAnswer((_) => const Stream.empty());
    when(
      () => odontogram.state,
    ).thenReturn(const OdontogramState(status: OdontogramLoadStatus.ready));
    when(() => odontogram.load(any())).thenAnswer((_) async {});

    await tester.pumpWidget(
      MultiBlocProvider(
        providers: [
          BlocProvider<ClinicCubit>.value(value: clinic),
          BlocProvider<PatientCubit>.value(value: patient),
          BlocProvider<OdontogramCubit>.value(value: odontogram),
        ],
        child: MaterialApp(
          theme: AppTheme.light,
          locale: const Locale('ar'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: const DentalChartPage(patientId: 'patient-1'),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('dentition-selector')), findsOneWidget);
    expect(find.byType(SegmentedButton<dynamic>), findsNothing);
    expect(find.text('مخطط الأسنان'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}

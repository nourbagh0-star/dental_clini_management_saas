import 'package:dental_clini_management_saas/app/localization/generated/app_localizations.dart';
import 'package:dental_clini_management_saas/features/patient/domain/patient_models.dart';
import 'package:dental_clini_management_saas/features/patient/presentation/pages/patient_pages.dart';
import 'package:dental_clini_management_saas/features/patient/presentation/patient_cubit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockPatientCubit extends Mock implements PatientCubit {}

class _FakePatientDraft extends Fake implements PatientDraft {}

void main() {
  setUpAll(() {
    registerFallbackValue(_FakePatientDraft());
  });

  _MockPatientCubit buildCubit({
    PatientState state = const PatientState(
      status: PatientStatus.ready,
      clinicId: 'c1',
    ),
  }) {
    final cubit = _MockPatientCubit();
    when(() => cubit.stream).thenAnswer((_) => const Stream.empty());
    when(() => cubit.state).thenReturn(state);
    return cubit;
  }

  Widget createWidget({
    required PatientCubit cubit,
    Locale locale = const Locale('en'),
  }) {
    return MaterialApp(
      locale: locale,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: BlocProvider<PatientCubit>.value(
        value: cubit,
        child: const NewPatientPage(),
      ),
    );
  }

  testWidgets('renders all section cards and input fields', (tester) async {
    tester.view.physicalSize = const Size(1024, 1400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final cubit = buildCubit();

    await tester.pumpWidget(createWidget(cubit: cubit));
    await tester.pumpAndSettle();

    expect(find.text('Personal Information'), findsOneWidget);
    expect(find.text('Contact Information'), findsOneWidget);
    expect(find.text('Birth Date & Age'), findsOneWidget);
    expect(find.text('Administrative / Clinic notes'), findsWidgets);

    expect(find.widgetWithText(TextFormField, 'First name'), findsOneWidget);
    expect(find.widgetWithText(TextFormField, "Middle / Father's name"), findsOneWidget);
    expect(find.widgetWithText(TextFormField, 'Last name'), findsOneWidget);
    expect(find.widgetWithText(TextFormField, 'Phone'), findsOneWidget);
    expect(find.widgetWithText(TextFormField, 'Email'), findsOneWidget);
    expect(find.text('Patient is known to be under 18'), findsOneWidget);
  });

  testWidgets('checking minor checkbox reveals guardian section', (tester) async {
    tester.view.physicalSize = const Size(1024, 1400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final cubit = buildCubit();

    await tester.pumpWidget(createWidget(cubit: cubit));
    await tester.pumpAndSettle();

    // Guardian section is not visible initially
    expect(find.text('Parent / Guardian Contact (Minor)'), findsNothing);

    // Tap minor checkbox
    await tester.tap(find.text('Patient is known to be under 18'));
    await tester.pumpAndSettle();

    // Guardian section is now visible
    expect(find.text('Parent / Guardian Contact (Minor)'), findsOneWidget);
    expect(find.widgetWithText(TextFormField, 'Guardian name'), findsOneWidget);
    expect(find.widgetWithText(TextFormField, 'Guardian phone'), findsOneWidget);
    expect(find.widgetWithText(TextFormField, 'Guardian email'), findsOneWidget);
  });

  testWidgets('approximate age < 18 automatically declares minor and shows guardian section', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1024, 1400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final cubit = buildCubit();

    await tester.pumpWidget(createWidget(cubit: cubit));
    await tester.pumpAndSettle();

    // Select Approximate age precision
    await tester.tap(find.text('Unknown'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Approximate').last);
    await tester.pumpAndSettle();

    // Enter age 12
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Approximate age in years'),
      '12',
    );
    await tester.pumpAndSettle();

    // Minor checkbox should now be true and guardian section should be visible
    expect(find.text('Parent / Guardian Contact (Minor)'), findsOneWidget);
  });

  testWidgets('submitting valid form passes middleName and administrativeNotes to cubit', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1024, 1400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final cubit = buildCubit();
    when(() => cubit.create(any())).thenAnswer((_) async => true);

    await tester.pumpWidget(createWidget(cubit: cubit));
    await tester.pumpAndSettle();

    await tester.enterText(
      find.widgetWithText(TextFormField, 'First name'),
      'Sara',
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, "Middle / Father's name"),
      'Ahmad',
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Last name'),
      'Al-Ali',
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Phone'),
      '+963991234567',
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Administrative / Clinic notes'),
      'Referred by Dr. Sami',
    );

    // Tap submit
    await tester.tap(find.text('Create patient'));
    await tester.pumpAndSettle();

    final captured = verify(() => cubit.create(captureAny())).captured;
    expect(captured.length, 1);
    final draft = captured.first as PatientDraft;
    expect(draft.firstName, 'Sara');
    expect(draft.middleName, 'Ahmad');
    expect(draft.lastName, 'Al-Ali');
    expect(draft.phone, '+963991234567');
    expect(draft.administrativeNotes, 'Referred by Dr. Sami');
  });
}

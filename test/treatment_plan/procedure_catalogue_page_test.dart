import 'package:dental_clini_management_saas/app/localization/generated/app_localizations.dart';
import 'package:dental_clini_management_saas/core/value/money.dart';
import 'package:dental_clini_management_saas/features/clinic/domain/clinic_models.dart';
import 'package:dental_clini_management_saas/features/clinic/presentation/clinic_cubit.dart';
import 'package:dental_clini_management_saas/features/treatment_plan/domain/treatment_plan_models.dart';
import 'package:dental_clini_management_saas/features/treatment_plan/presentation/pages/procedure_catalogue_page.dart';
import 'package:dental_clini_management_saas/features/treatment_plan/presentation/treatment_plan_cubit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockClinicCubit extends Mock implements ClinicCubit {}

class _MockTreatmentPlanCubit extends Mock implements TreatmentPlanCubit {}

void main() {
  const clinic = Clinic(
    id: 'clinic-1',
    name: 'Smile Dental Clinic',
    currencyCode: 'USD',
    timeZone: 'Etc/UTC',
  );

  const ownerMembership = ClinicMembership(
    clinic: clinic,
    roles: {'owner'},
  );

  const procedures = [
    ClinicProcedure(
      id: 'proc-1',
      clinicId: 'clinic-1',
      name: 'Scaling & Polishing',
      category: 'Preventive',
      defaultPrice: Money.fromMinorUnits(5000),
      durationMinutes: 45,
      active: true,
    ),
    ClinicProcedure(
      id: 'proc-2',
      clinicId: 'clinic-1',
      name: 'Composite Filling',
      category: 'Restorative',
      defaultPrice: Money.fromMinorUnits(7000),
      durationMinutes: 45,
      active: true,
    ),
    ClinicProcedure(
      id: 'proc-3',
      clinicId: 'clinic-1',
      name: 'Old Root Canal',
      category: 'Endodontics',
      defaultPrice: Money.fromMinorUnits(15000),
      durationMinutes: 60,
      active: false,
    ),
  ];

  late _MockClinicCubit clinicCubit;
  late _MockTreatmentPlanCubit treatmentPlanCubit;

  setUp(() {
    clinicCubit = _MockClinicCubit();
    treatmentPlanCubit = _MockTreatmentPlanCubit();

    when(() => clinicCubit.stream).thenAnswer((_) => const Stream.empty());
    when(() => clinicCubit.state).thenReturn(
      const ClinicState(
        status: ClinicStatus.ready,
        activeClinicId: 'clinic-1',
        memberships: [ownerMembership],
      ),
    );
  });

  Widget createWidget({
    List<ClinicProcedure> procs = procedures,
    Locale locale = const Locale('en'),
  }) {
    when(() => treatmentPlanCubit.state).thenReturn(
      TreatmentPlanState(
        status: TreatmentPlanLoadStatus.ready,
        clinicId: 'clinic-1',
        procedures: procs,
      ),
    );
    when(() => treatmentPlanCubit.stream).thenAnswer(
      (_) => Stream.value(
        TreatmentPlanState(
          status: TreatmentPlanLoadStatus.ready,
          clinicId: 'clinic-1',
          procedures: procs,
        ),
      ),
    );
    when(() => treatmentPlanCubit.loadCatalogue(any()))
        .thenAnswer((_) async {});

    return MaterialApp(
      locale: locale,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: MultiBlocProvider(
        providers: [
          BlocProvider<ClinicCubit>.value(value: clinicCubit),
          BlocProvider<TreatmentPlanCubit>.value(value: treatmentPlanCubit),
        ],
        child: const ProcedureCataloguePage(),
      ),
    );
  }

  testWidgets('renders clinic header summary, count badges, and procedure cards', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1024, 1600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(createWidget());
    await tester.pumpAndSettle();

    expect(find.text('Smile Dental Clinic'), findsOneWidget);
    expect(find.text('3 procedures'), findsOneWidget);
    expect(find.text('2 active'), findsOneWidget);
    expect(find.text('3 categories'), findsOneWidget);

    expect(find.text('Scaling & Polishing'), findsOneWidget);
    expect(find.text('Composite Filling'), findsOneWidget);
    expect(find.text('Old Root Canal'), findsOneWidget);

    expect(find.text('50.00 USD'), findsOneWidget);
    expect(find.text('70.00 USD'), findsOneWidget);
    expect(find.text('150.00 USD'), findsOneWidget);

    expect(find.text('Inactive'), findsOneWidget);
  });

  testWidgets('filters procedures by search text in real-time', (tester) async {
    tester.view.physicalSize = const Size(1024, 1600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(createWidget());
    await tester.pumpAndSettle();

    expect(find.text('Scaling & Polishing'), findsOneWidget);
    expect(find.text('Composite Filling'), findsOneWidget);

    await tester.enterText(find.byType(TextField), 'filling');
    await tester.pumpAndSettle();

    expect(find.text('Composite Filling'), findsOneWidget);
    expect(find.text('Scaling & Polishing'), findsNothing);
    expect(find.text('Old Root Canal'), findsNothing);
  });

  testWidgets('filters procedures by category choice chip', (tester) async {
    tester.view.physicalSize = const Size(1024, 1600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(createWidget());
    await tester.pumpAndSettle();

    expect(find.text('Scaling & Polishing'), findsOneWidget);
    expect(find.text('Composite Filling'), findsOneWidget);

    await tester.tap(find.widgetWithText(ChoiceChip, 'Preventive'));
    await tester.pumpAndSettle();

    expect(find.text('Scaling & Polishing'), findsOneWidget);
    expect(find.text('Composite Filling'), findsNothing);
    expect(find.text('Old Root Canal'), findsNothing);
  });

  testWidgets('filters by active only chip', (tester) async {
    tester.view.physicalSize = const Size(1024, 1600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(createWidget());
    await tester.pumpAndSettle();

    expect(find.text('Old Root Canal'), findsOneWidget);

    await tester.tap(find.widgetWithText(FilterChip, 'Active only'));
    await tester.pumpAndSettle();

    expect(find.text('Scaling & Polishing'), findsOneWidget);
    expect(find.text('Composite Filling'), findsOneWidget);
    expect(find.text('Old Root Canal'), findsNothing);
  });

  testWidgets('shows empty state with load standard procedures button when no procedures', (
    tester,
  ) async {
    await tester.pumpWidget(createWidget(procs: const []));
    await tester.pumpAndSettle();

    expect(find.text('Load standard procedures'), findsWidgets);
    expect(find.text('New procedure'), findsWidgets);
  });

  testWidgets('renders cleanly in Arabic RTL on narrow mobile screen', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(360, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() => tester.view.resetPhysicalSize());

    await tester.pumpWidget(
      createWidget(locale: const Locale('ar')),
    );
    await tester.pumpAndSettle();

    expect(find.text('Smile Dental Clinic'), findsOneWidget);
    expect(find.text('Scaling & Polishing'), findsOneWidget);
  });
}

import 'package:dental_clini_management_saas/app/localization/generated/app_localizations.dart';
import 'package:dental_clini_management_saas/app/theme/app_theme.dart';
import 'package:dental_clini_management_saas/features/appointment/domain/appointment_models.dart';
import 'package:dental_clini_management_saas/features/appointment/presentation/appointment_cubit.dart';
import 'package:dental_clini_management_saas/features/clinic/domain/clinic_models.dart';
import 'package:dental_clini_management_saas/features/clinic/presentation/clinic_cubit.dart';
import 'package:dental_clini_management_saas/features/patient/domain/patient_models.dart';
import 'package:dental_clini_management_saas/features/patient/presentation/patient_cubit.dart';
import 'package:dental_clini_management_saas/features/staff/domain/staff_models.dart';
import 'package:dental_clini_management_saas/features/staff/presentation/staff_cubit.dart';
import 'package:dental_clini_management_saas/features/treatment_plan/presentation/pages/treatment_plan_page.dart';
import 'package:dental_clini_management_saas/features/treatment_plan/presentation/treatment_plan_cubit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockClinicCubit extends Mock implements ClinicCubit {}

class _MockPatientCubit extends Mock implements PatientCubit {}

class _MockTreatmentPlanCubit extends Mock implements TreatmentPlanCubit {}

class _MockStaffCubit extends Mock implements StaffCubit {}

class _MockAppointmentCubit extends Mock implements AppointmentCubit {}

void main() {
  late _MockClinicCubit clinic;
  late _MockPatientCubit patient;
  late _MockTreatmentPlanCubit treatmentPlan;
  late _MockStaffCubit staff;
  late _MockAppointmentCubit appointment;

  final now = DateTime.now();

  setUp(() {
    clinic = _MockClinicCubit();
    patient = _MockPatientCubit();
    treatmentPlan = _MockTreatmentPlanCubit();
    staff = _MockStaffCubit();
    appointment = _MockAppointmentCubit();

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
            roles: {'owner', 'dentist'},
            memberId: 'staff-1',
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

    when(() => treatmentPlan.stream).thenAnswer((_) => const Stream.empty());
    when(() => treatmentPlan.state).thenReturn(
      const TreatmentPlanState(
        status: TreatmentPlanLoadStatus.ready,
        clinicId: 'clinic-1',
        patientId: 'patient-1',
        plans: [],
      ),
    );
    when(() => treatmentPlan.loadPatient(any(), any())).thenAnswer((_) async {});

    when(() => staff.stream).thenAnswer((_) => const Stream.empty());
    when(() => staff.state).thenReturn(
      const StaffState(
        status: StaffStatus.ready,
        members: [
          StaffMember(
            id: 'staff-1',
            userId: 'user-1',
            displayName: 'Dr. Dentist',
            email: 'dentist@clinic.com',
            roles: {StaffRole.dentist},
            isActive: true,
          ),
        ],
      ),
    );
    when(() => staff.load(any())).thenAnswer((_) async {});

    when(() => appointment.stream).thenAnswer((_) => const Stream.empty());
    when(() => appointment.state).thenReturn(
      AppointmentState(
        status: AppointmentLoadStatus.ready,
        clinicId: 'clinic-1',
        appointments: [
          Appointment(
            id: 'appt-1',
            clinicId: 'clinic-1',
            patientId: 'patient-1',
            patientName: 'Demo Patient',
            patientNumber: 'P-0001',
            dentistMemberId: 'staff-1',
            dentistName: 'Dr. Dentist',
            startsAt: now.add(const Duration(days: 2)),
            endsAt: now.add(const Duration(days: 2, minutes: 30)),
            status: AppointmentStatus.scheduled,
            purpose: 'Tooth 16 - Cleaning',
          ),
          Appointment(
            id: 'appt-2',
            clinicId: 'clinic-1',
            patientId: 'patient-1',
            patientName: 'Demo Patient',
            patientNumber: 'P-0001',
            dentistMemberId: 'staff-1',
            dentistName: 'Dr. Dentist',
            startsAt: now.subtract(const Duration(days: 10)),
            endsAt: now.subtract(const Duration(days: 10, minutes: -30)),
            status: AppointmentStatus.completed,
            purpose: 'Consultation',
          ),
        ],
      ),
    );
    when(
      () => appointment.load(
        clinicId: any(named: 'clinicId'),
        from: any(named: 'from'),
        until: any(named: 'until'),
      ),
    ).thenAnswer((_) async {});
  });

  Widget buildSubject({Locale locale = const Locale('ar')}) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<ClinicCubit>.value(value: clinic),
        BlocProvider<PatientCubit>.value(value: patient),
        BlocProvider<TreatmentPlanCubit>.value(value: treatmentPlan),
        BlocProvider<StaffCubit>.value(value: staff),
        BlocProvider<AppointmentCubit>.value(value: appointment),
      ],
      child: MaterialApp(
        theme: AppTheme.light,
        locale: locale,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: const TreatmentPlanPage(patientId: 'patient-1'),
      ),
    );
  }

  testWidgets('Renders Arabic Treatment Plan with tabs and switches to Appointments timeline', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(800, 1000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(buildSubject());
    await tester.pumpAndSettle();

    // Check segment buttons
    expect(find.byType(SegmentedButton<int>), findsOneWidget);
    expect(find.text('إجراءات العلاج'), findsOneWidget);
    expect(find.text('المواعيد (2)'), findsOneWidget);

    // Empty state for plans displays quick action buttons
    expect(
      find.text('لا توجد خطة علاج بعد. يمكن لطبيب الأسنان إعداد مسودة.'),
      findsOneWidget,
    );
    expect(find.text('خطة جديدة'), findsWidgets);
    expect(find.text('حجز موعد'), findsWidgets);
    expect(find.text('مخطط الأسنان'), findsWidgets);

    // Switch to appointments tab
    await tester.tap(find.text('المواعيد (2)'));
    await tester.pumpAndSettle();

    // Verify Appointments timeline is visible
    expect(find.text('جدول مواعيد المريض'), findsOneWidget);
    expect(find.text('المواعيد القادمة'), findsOneWidget);
    expect(find.text('المواعيد السابقة'), findsOneWidget);
    expect(find.text('Tooth 16 - Cleaning'), findsOneWidget);
    expect(find.text('Consultation'), findsOneWidget);
    expect(find.text('تذكير عبر واتساب'), findsOneWidget);

    expect(tester.takeException(), isNull);
  });

  testWidgets('Renders cleanly on narrow mobile screen (320px)', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(buildSubject());
    await tester.pumpAndSettle();

    expect(find.byType(TreatmentPlanPage), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}

import 'package:dental_clini_management_saas/app/localization/generated/app_localizations.dart';
import 'package:dental_clini_management_saas/app/theme/app_theme.dart';
import 'package:dental_clini_management_saas/features/appointment/domain/appointment_models.dart';
import 'package:dental_clini_management_saas/features/appointment/presentation/appointment_cubit.dart';
import 'package:dental_clini_management_saas/features/appointment/presentation/pages/appointment_pages.dart';
import 'package:dental_clini_management_saas/features/clinic/domain/clinic_models.dart';
import 'package:dental_clini_management_saas/features/clinic/presentation/clinic_cubit.dart';
import 'package:dental_clini_management_saas/features/schedule/presentation/schedule_cubit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';

class _MockClinicCubit extends Mock implements ClinicCubit {}

class _MockScheduleCubit extends Mock implements ScheduleCubit {}

class _MockAppointmentCubit extends Mock implements AppointmentCubit {}

const _clinic = Clinic(
  id: 'clinic-1',
  name: 'Smile Clinic',
  timeZone: 'Etc/UTC',
  currencyCode: 'USD',
);


final _appointmentScheduled = Appointment(
  id: 'app-1',
  clinicId: 'clinic-1',
  patientId: 'patient-1',
  patientName: 'Sarah Connor',
  patientNumber: 'PT-1001',
  dentistMemberId: 'dentist-1',
  dentistName: 'Dr. Sarah Smith',
  startsAt: DateTime.utc(2026, 9, 21, 9, 0),
  endsAt: DateTime.utc(2026, 9, 21, 9, 30),
  status: AppointmentStatus.scheduled,
  purpose: 'Routine checkup',
);

final _appointmentConfirmed = Appointment(
  id: 'app-2',
  clinicId: 'clinic-1',
  patientId: 'patient-2',
  patientName: 'John Doe',
  patientNumber: 'PT-1002',
  dentistMemberId: 'dentist-1',
  dentistName: 'Dr. Sarah Smith',
  startsAt: DateTime.utc(2026, 9, 21, 10, 0),
  endsAt: DateTime.utc(2026, 9, 21, 10, 45),
  status: AppointmentStatus.confirmed,
  purpose: 'Dental scaling & cleaning',
  preparationNote: 'Needs blood pressure check',
);

final _appointmentInProgress = Appointment(
  id: 'app-3',
  clinicId: 'clinic-1',
  patientId: 'patient-3',
  patientName: 'Kyle Reese',
  patientNumber: 'PT-1003',
  dentistMemberId: 'dentist-1',
  dentistName: 'Dr. Sarah Smith',
  startsAt: DateTime.utc(2026, 9, 21, 11, 0),
  endsAt: DateTime.utc(2026, 9, 21, 11, 30),
  status: AppointmentStatus.inProgress,
  overrideReason: 'Emergency squeeze-in',
);

void main() {
  setUpAll(() {
    registerFallbackValue(AppointmentStatus.scheduled);
  });

  testWidgets('renders empty state when there are no appointments', (
    tester,
  ) async {
    final clinic = _clinicCubit(roles: const {'owner'});
    final schedule = _scheduleCubit();
    final appointment = _appointmentCubit(
      const AppointmentState(
        status: AppointmentLoadStatus.ready,
        appointments: [],
      ),
    );

    await tester.pumpWidget(_app(clinic, schedule, appointment));
    await tester.pump();

    expect(find.text('No appointments scheduled'), findsOneWidget);
    expect(find.byIcon(Icons.event_available_rounded), findsOneWidget);
    expect(find.text('New appointment'), findsWidgets);
  });

  testWidgets(
    'renders appointment cards with status badge, time, doctor, and notes',
    (tester) async {
      tester.view.physicalSize = const Size(1024, 1600);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final clinic = _clinicCubit(roles: const {'receptionist'});
      final schedule = _scheduleCubit();
      final appointment = _appointmentCubit(
        AppointmentState(
          status: AppointmentLoadStatus.ready,
          appointments: [_appointmentScheduled, _appointmentConfirmed],
        ),
      );

      await tester.pumpWidget(_app(clinic, schedule, appointment));
      await tester.pump();

      expect(find.text('2 appointments'), findsOneWidget);
      expect(find.text('Sarah Connor'), findsOneWidget);
      expect(find.text('PT-1001'), findsOneWidget);
      expect(find.text('Scheduled'), findsOneWidget);
      expect(find.text('Routine checkup'), findsOneWidget);

      expect(find.text('John Doe'), findsOneWidget);
      expect(find.text('PT-1002'), findsOneWidget);
      expect(find.text('Confirmed'), findsOneWidget);
      expect(find.text('Dental scaling & cleaning'), findsOneWidget);
      expect(
        find.text('Prep Note: Needs blood pressure check'),
        findsOneWidget,
      );
      expect(find.byIcon(Icons.chat_bubble_outline_rounded), findsNWidgets(2));
    },
  );

  testWidgets('receptionist can 1-tap confirm a scheduled appointment', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1024, 1600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final clinic = _clinicCubit(roles: const {'receptionist'});
    final schedule = _scheduleCubit();
    final appointment = _appointmentCubit(
      AppointmentState(
        status: AppointmentLoadStatus.ready,
        appointments: [_appointmentScheduled],
      ),
    );

    when(
      () => appointment.transition(
        appointmentId: any(named: 'appointmentId'),
        status: any(named: 'status'),
        cancellationReason: any(named: 'cancellationReason'),
      ),
    ).thenAnswer((_) async => true);

    await tester.pumpWidget(_app(clinic, schedule, appointment));
    await tester.pump();

    final confirmBtn = find.widgetWithText(FilledButton, 'Confirm');
    expect(confirmBtn, findsOneWidget);

    await tester.tap(confirmBtn);
    await tester.pump();

    verify(
      () => appointment.transition(
        appointmentId: 'app-1',
        status: AppointmentStatus.confirmed,
      ),
    ).called(1);
  });

  testWidgets('dentist can 1-tap start a confirmed appointment', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1024, 1600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final clinic = _clinicCubit(roles: const {'dentist'});
    final schedule = _scheduleCubit();
    final appointment = _appointmentCubit(
      AppointmentState(
        status: AppointmentLoadStatus.ready,
        appointments: [_appointmentConfirmed],
      ),
    );

    when(
      () => appointment.transition(
        appointmentId: any(named: 'appointmentId'),
        status: any(named: 'status'),
        cancellationReason: any(named: 'cancellationReason'),
      ),
    ).thenAnswer((_) async => true);

    await tester.pumpWidget(_app(clinic, schedule, appointment));
    await tester.pump();

    final startBtn = find.widgetWithText(FilledButton, 'Start');
    expect(startBtn, findsOneWidget);

    await tester.tap(startBtn);
    await tester.pump();

    verify(
      () => appointment.transition(
        appointmentId: 'app-2',
        status: AppointmentStatus.inProgress,
      ),
    ).called(1);
  });

  testWidgets(
    'shows Open Clinical Session for active appointment and navigates',
    (tester) async {
      tester.view.physicalSize = const Size(1024, 1600);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final clinic = _clinicCubit(roles: const {'dentist'});
      final schedule = _scheduleCubit();
      final appointment = _appointmentCubit(
        AppointmentState(
          status: AppointmentLoadStatus.ready,
          appointments: [_appointmentInProgress],
        ),
      );

      String? pushedRoute;
      final router = GoRouter(
        initialLocation: '/appointments',
        routes: [
          GoRoute(
            path: '/appointments',
            builder: (context, state) => const AppointmentCalendarPage(),
          ),
          GoRoute(
            path: '/patients/:patientId/visits',
            builder: (context, state) {
              pushedRoute = state.uri.toString();
              return const SizedBox();
            },
          ),
          GoRoute(
            path: '/patients/:patientId',
            builder: (context, state) => const SizedBox(),
          ),
          GoRoute(
            path: '/clinic-gate',
            builder: (context, state) => const SizedBox(),
          ),
        ],
      );

      await tester.pumpWidget(
        MultiBlocProvider(
          providers: [
            BlocProvider<ClinicCubit>.value(value: clinic),
            BlocProvider<ScheduleCubit>.value(value: schedule),
            BlocProvider<AppointmentCubit>.value(value: appointment),
          ],
          child: MaterialApp.router(
            theme: AppTheme.light,
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            routerConfig: router,
          ),
        ),
      );
      await tester.pump();

      expect(find.text('Override: Emergency squeeze-in'), findsOneWidget);

      final sessionBtn = find.widgetWithText(
        FilledButton,
        'Open clinical session',
      );
      expect(sessionBtn, findsOneWidget);

      await tester.tap(sessionBtn);
      await tester.pumpAndSettle();

      expect(pushedRoute, '/patients/patient-3/visits?appointmentId=app-3');
    },
  );

  testWidgets(
    'navigates to patient profile when Profile button is tapped',
    (tester) async {
      tester.view.physicalSize = const Size(1024, 1600);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final clinic = _clinicCubit(roles: const {'receptionist'});
      final schedule = _scheduleCubit();
      final appointment = _appointmentCubit(
        AppointmentState(
          status: AppointmentLoadStatus.ready,
          appointments: [_appointmentScheduled],
        ),
      );

      String? pushedRoute;
      final router = GoRouter(
        initialLocation: '/appointments',
        routes: [
          GoRoute(
            path: '/appointments',
            builder: (context, state) => const AppointmentCalendarPage(),
          ),
          GoRoute(
            path: '/patients/:patientId',
            builder: (context, state) {
              pushedRoute = state.uri.toString();
              return const SizedBox();
            },
          ),
          GoRoute(
            path: '/clinic-gate',
            builder: (context, state) => const SizedBox(),
          ),
        ],
      );

      await tester.pumpWidget(
        MultiBlocProvider(
          providers: [
            BlocProvider<ClinicCubit>.value(value: clinic),
            BlocProvider<ScheduleCubit>.value(value: schedule),
            BlocProvider<AppointmentCubit>.value(value: appointment),
          ],
          child: MaterialApp.router(
            theme: AppTheme.light,
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            routerConfig: router,
          ),
        ),
      );
      await tester.pump();

      final profileBtn = find.widgetWithText(OutlinedButton, 'Profile');
      expect(profileBtn, findsOneWidget);

      await tester.tap(profileBtn);
      await tester.pumpAndSettle();

      expect(pushedRoute, '/patients/patient-1');
    },
  );

  testWidgets(
    'tapping WhatsApp reminder when patient has no phone shows snackbar',
    (tester) async {
      tester.view.physicalSize = const Size(1024, 1600);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final clinic = _clinicCubit(roles: const {'receptionist'});
      final schedule = _scheduleCubit();
      final appointment = _appointmentCubit(
        AppointmentState(
          status: AppointmentLoadStatus.ready,
          appointments: [_appointmentScheduled],
        ),
      );

      await tester.pumpWidget(_app(clinic, schedule, appointment));
      await tester.pump();

      final waBtn = find.byIcon(Icons.chat_bubble_outline_rounded);
      expect(waBtn, findsOneWidget);

      await tester.tap(waBtn);
      await tester.pumpAndSettle();

      expect(
        find.text('No phone number registered for this patient.'),
        findsOneWidget,
      );
    },
  );
}

_MockClinicCubit _clinicCubit({Set<String> roles = const {'owner'}}) {
  final cubit = _MockClinicCubit();
  when(() => cubit.stream).thenAnswer((_) => const Stream.empty());
  when(() => cubit.state).thenReturn(
    ClinicState(
      status: ClinicStatus.ready,
      activeClinicId: _clinic.id,
      memberships: [
        ClinicMembership(
          clinic: _clinic,
          memberId: 'user-1',
          roles: roles,
        ),
      ],
    ),
  );
  return cubit;
}

_MockScheduleCubit _scheduleCubit() {
  final cubit = _MockScheduleCubit();
  when(() => cubit.stream).thenAnswer((_) => const Stream.empty());
  when(() => cubit.state).thenReturn(const ScheduleState());
  when(() => cubit.load(any())).thenAnswer((_) async {});
  return cubit;
}

_MockAppointmentCubit _appointmentCubit([
  AppointmentState state = const AppointmentState(),
]) {
  final cubit = _MockAppointmentCubit();
  when(() => cubit.stream).thenAnswer((_) => const Stream.empty());
  when(() => cubit.state).thenReturn(state);
  when(
    () => cubit.load(
      clinicId: any(named: 'clinicId'),
      from: any(named: 'from'),
      until: any(named: 'until'),
    ),
  ).thenAnswer((_) async {});
  return cubit;
}

Widget _app(
  ClinicCubit clinic,
  ScheduleCubit schedule,
  AppointmentCubit appointment,
) => MultiBlocProvider(
  providers: [
    BlocProvider<ClinicCubit>.value(value: clinic),
    BlocProvider<ScheduleCubit>.value(value: schedule),
    BlocProvider<AppointmentCubit>.value(value: appointment),
  ],
  child: MaterialApp(
    theme: AppTheme.light,
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    home: const AppointmentCalendarPage(),
  ),
);

import 'dart:async';

import 'package:dental_clini_management_saas/core/auth/session_coordinator.dart';
import 'package:dental_clini_management_saas/core/error/app_failure.dart';
import 'package:dental_clini_management_saas/features/dashboard/domain/dashboard_models.dart';
import 'package:dental_clini_management_saas/features/dashboard/domain/dashboard_repository.dart';
import 'package:dental_clini_management_saas/features/dashboard/presentation/dashboard_cubit.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockSessionCoordinator extends Mock implements SessionCoordinator {}

void main() {
  late _MockSessionCoordinator session;

  setUp(() {
    session = _MockSessionCoordinator();
    when(() => session.changes).thenAnswer((_) => const Stream.empty());
  });

  test('loads one active-clinic snapshot', () async {
    final cubit = DashboardCubit(
      _DashboardRepository((clinicId) async => _snapshot(clinicId)),
      session,
    );
    addTearDown(cubit.close);

    await cubit.load('clinic-a');

    expect(cubit.state.status, DashboardLoadStatus.ready);
    expect(cubit.state.snapshot?.clinicId, 'clinic-a');
  });

  test('an older response cannot overwrite a new clinic', () async {
    final first = Completer<DashboardSnapshot>();
    final cubit = DashboardCubit(
      _DashboardRepository(
        (clinicId) => clinicId == 'clinic-a'
            ? first.future
            : Future.value(_snapshot(clinicId)),
      ),
      session,
    );
    addTearDown(cubit.close);

    final oldLoad = cubit.load('clinic-a');
    await cubit.load('clinic-b');
    first.complete(_snapshot('clinic-a'));
    await oldLoad;

    expect(cubit.state.snapshot?.clinicId, 'clinic-b');
  });

  test('refresh failure retains the last successful snapshot', () async {
    var calls = 0;
    final cubit = DashboardCubit(
      _DashboardRepository((clinicId) async {
        if (calls++ == 0) return _snapshot(clinicId);
        throw const NetworkFailure();
      }),
      session,
    );
    addTearDown(cubit.close);

    await cubit.load('clinic-a');
    final previous = cubit.state.snapshot;
    await cubit.refresh();

    expect(cubit.state.snapshot, same(previous));
    expect(cubit.state.refreshFailure, isA<NetworkFailure>());
    expect(cubit.state.status, DashboardLoadStatus.ready);
  });
}

class _DashboardRepository implements DashboardRepository {
  _DashboardRepository(this.handler);

  final Future<DashboardSnapshot> Function(String clinicId) handler;

  @override
  Future<DashboardSnapshot> load(String clinicId) => handler(clinicId);
}

DashboardSnapshot _snapshot(String clinicId) => DashboardSnapshot(
  clinicId: clinicId,
  clinicTimeZone: 'Europe/Moscow',
  generatedAt: DateTime.utc(2026, 9, 13, 9),
  period: DashboardPeriod(
    todayStart: DateTime.utc(2026, 9, 12, 21),
    tomorrowStart: DateTime.utc(2026, 9, 13, 21),
    upcomingEnd: DateTime.utc(2026, 9, 20, 21),
    weekStart: DateTime.utc(2026, 9, 6, 21),
    weekEnd: DateTime.utc(2026, 9, 13, 21),
    monthStart: DateTime.utc(2026, 8, 31, 21),
    nextMonthStart: DateTime.utc(2026, 9, 30, 21),
  ),
  capabilities: const DashboardCapabilities(
    canViewCompletedTreatments: false,
    canViewFinancialSummary: false,
  ),
  metrics: const DashboardMetrics(totalPatients: 0, appointmentsThisWeek: 0),
  todayAppointments: const DashboardAppointmentSection(
    totalCount: 0,
    hasMore: false,
    items: [],
  ),
  upcomingAppointments: const DashboardAppointmentSection(
    totalCount: 0,
    hasMore: false,
    items: [],
  ),
);

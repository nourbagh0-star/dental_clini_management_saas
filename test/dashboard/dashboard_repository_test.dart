import 'package:dental_clini_management_saas/core/error/app_failure.dart';
import 'package:dental_clini_management_saas/features/dashboard/data/dashboard_data_source.dart';
import 'package:dental_clini_management_saas/features/dashboard/data/supabase_dashboard_repository.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const clinicId = '12000000-0000-4000-8000-000000000010';

  test('maps a role-filtered snapshot and exact money', () async {
    final repository = SupabaseDashboardRepository(
      _FakeDashboardSource(_snapshot()),
    );

    final result = await repository.load(clinicId);

    expect(result.clinicId, clinicId);
    expect(result.metrics.totalPatients, 3);
    expect(result.metrics.completedTreatmentsThisMonth, 2);
    expect(result.metrics.financial!.outstandingAmount.minorUnits, 14000);
    expect(result.todayAppointments.items.single.patientName, 'Ada Demo');
  });

  test('accepts omitted denied metric groups', () async {
    final value = _snapshot();
    value['capabilities'] = {
      'canViewCompletedTreatments': false,
      'canViewFinancialSummary': false,
    };
    value['metrics'] = {'totalPatients': 3, 'appointmentsThisWeek': 4};
    final repository = SupabaseDashboardRepository(_FakeDashboardSource(value));

    final result = await repository.load(clinicId);

    expect(result.metrics.completedTreatmentsThisMonth, isNull);
    expect(result.metrics.financial, isNull);
  });

  test('rejects a denied group that is present in the response', () async {
    final value = _snapshot();
    value['capabilities'] = {
      'canViewCompletedTreatments': false,
      'canViewFinancialSummary': true,
    };
    final repository = SupabaseDashboardRepository(_FakeDashboardSource(value));

    await expectLater(repository.load(clinicId), throwsA(isA<ServerFailure>()));
  });

  test('rejects non-canonical money and stale clinic scope', () async {
    final badMoney = _snapshot();
    (badMoney['metrics'] as Map<String, dynamic>)['financial'] = {
      'outstandingInvoiceCount': 2,
      'outstandingAmount': '140.001',
      'currencyCode': 'RUB',
    };
    await expectLater(
      SupabaseDashboardRepository(
        _FakeDashboardSource(badMoney),
      ).load(clinicId),
      throwsA(isA<ServerFailure>()),
    );

    final wrongClinic = _snapshot()
      ..['clinicId'] = '12000000-0000-4000-8000-000000000011';
    await expectLater(
      SupabaseDashboardRepository(
        _FakeDashboardSource(wrongClinic),
      ).load(clinicId),
      throwsA(isA<ServerFailure>()),
    );
  });
}

class _FakeDashboardSource implements DashboardDataSource {
  _FakeDashboardSource(this.value);

  final Map<String, dynamic> value;

  @override
  Future<Map<String, dynamic>> snapshot(String clinicId) async => value;
}

Map<String, dynamic> _snapshot() => {
  'clinicId': '12000000-0000-4000-8000-000000000010',
  'clinicTimeZone': 'Europe/Moscow',
  'generatedAt': '2026-09-13T09:00:00+00:00',
  'periods': {
    'todayStart': '2026-09-12T21:00:00+00:00',
    'tomorrowStart': '2026-09-13T21:00:00+00:00',
    'upcomingEnd': '2026-09-20T21:00:00+00:00',
    'weekStart': '2026-09-06T21:00:00+00:00',
    'weekEnd': '2026-09-13T21:00:00+00:00',
    'monthStart': '2026-08-31T21:00:00+00:00',
    'nextMonthStart': '2026-09-30T21:00:00+00:00',
  },
  'capabilities': {
    'canViewCompletedTreatments': true,
    'canViewFinancialSummary': true,
  },
  'metrics': {
    'totalPatients': 3,
    'appointmentsThisWeek': 4,
    'completedTreatmentsThisMonth': 2,
    'financial': {
      'outstandingInvoiceCount': 2,
      'outstandingAmount': '140.00',
      'currencyCode': 'RUB',
    },
  },
  'todayAppointments': {
    'totalCount': 1,
    'hasMore': false,
    'items': [
      {
        'id': '12000000-0000-4000-8000-000000000040',
        'patientId': '12000000-0000-4000-8000-000000000030',
        'patientName': 'Ada Demo',
        'patientNumber': 'PAT-12001',
        'dentistMemberId': '12000000-0000-4000-8000-000000000020',
        'dentistLabel': 'dentist@example.test',
        'startsAt': '2026-09-13T08:00:00+00:00',
        'endsAt': '2026-09-13T08:30:00+00:00',
        'status': 'confirmed',
      },
    ],
  },
  'upcomingAppointments': {
    'totalCount': 0,
    'hasMore': false,
    'items': <Map<String, dynamic>>[],
  },
};

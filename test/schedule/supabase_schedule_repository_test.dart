import 'package:dental_clini_management_saas/features/schedule/data/schedule_data_source.dart';
import 'package:dental_clini_management_saas/features/schedule/data/supabase_schedule_repository.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'normalizes PostgreSQL time values when a saved schedule reloads',
    () async {
      final repository = SupabaseScheduleRepository(_ScheduleSource());

      final versions = await repository.getScheduleVersions(
        '11111111-1111-4111-8111-111111111111',
      );

      final period = versions.single.workingPeriods.single;
      expect(period.startsAt, '09:00');
      expect(period.endsAt, '17:00');
      expect(period.breaks.single.startsAt, '13:00');
      expect(period.breaks.single.endsAt, '14:00');
    },
  );
}

class _ScheduleSource implements ScheduleDataSource {
  @override
  Future<List<Map<String, dynamic>>> getScheduleVersionRows(
    String clinicId,
  ) async => [
    {
      'id': '22222222-2222-4222-8222-222222222222',
      'clinic_id': clinicId,
      'dentist_member_id': '33333333-3333-4333-8333-333333333333',
      'effective_from': '2026-09-20',
      'doctor_working_hours': [
        {
          'id': '44444444-4444-4444-8444-444444444444',
          'weekday': 1,
          'starts_at': '09:00:00',
          'ends_at': '17:00:00',
          'doctor_schedule_breaks': [
            {
              'id': '55555555-5555-4555-8555-555555555555',
              'starts_at': '13:00:00',
              'ends_at': '14:00:00',
            },
          ],
        },
      ],
    },
  ];

  @override
  Future<List<Map<String, dynamic>>> getScheduleExceptionRows(
    String clinicId,
  ) async => const [];

  @override
  Future<List<Map<String, dynamic>>> getManageableDentistRows(
    String clinicId,
  ) async => const [];

  @override
  Future<Map<String, dynamic>> invokeScheduleAction(
    Map<String, dynamic> request,
  ) async => const {};
}

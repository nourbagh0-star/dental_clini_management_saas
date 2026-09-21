import 'package:dental_clini_management_saas/core/error/app_failure.dart';
import 'package:dental_clini_management_saas/features/audit/data/audit_data_source.dart';
import 'package:dental_clini_management_saas/features/audit/data/supabase_audit_repository.dart';
import 'package:dental_clini_management_saas/features/audit/domain/audit_models.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const clinicId = '13000000-0000-4000-8000-000000000010';

  test('maps a strict owner page and typed safe context', () async {
    final repository = SupabaseAuditRepository(_FakeSource(_page()));
    final result = await repository.page(
      clinicId: clinicId,
      filter: AuditFilter(
        fromDate: DateTime(2026, 9, 1),
        toDateExclusive: DateTime(2026, 10, 1),
      ),
    );

    expect(result.clinicTimeZone, 'Europe/Moscow');
    expect(result.items.single.category, AuditCategory.financial);
    expect(result.items.single.context.amount, '125.00');
    expect(result.items.single.actorRoles, {'owner'});
    expect(result.nextCursor!.id, '13000000-0000-4000-8000-000000000051');
  });

  test('rejects unsafe context and stale clinic scope', () async {
    final unsafe = _page();
    ((unsafe['items'] as List).single as Map<String, dynamic>)['context'] = {
      'patient_name': 'Must not cross the boundary',
    };
    await expectLater(
      SupabaseAuditRepository(_FakeSource(unsafe)).page(
        clinicId: clinicId,
        filter: AuditFilter(
          fromDate: DateTime(2026, 9, 1),
          toDateExclusive: DateTime(2026, 10, 1),
        ),
      ),
      throwsA(isA<ServerFailure>()),
    );

    final stale = _page()
      ..['clinicId'] = '13000000-0000-4000-8000-000000000011';
    await expectLater(
      SupabaseAuditRepository(_FakeSource(stale)).page(
        clinicId: clinicId,
        filter: AuditFilter(
          fromDate: DateTime(2026, 9, 1),
          toDateExclusive: DateTime(2026, 10, 1),
        ),
      ),
      throwsA(isA<ServerFailure>()),
    );
  });

  test('records access with an idempotency UUID', () async {
    final source = _FakeSource(_page());
    final repository = SupabaseAuditRepository(source);
    await repository.recordAccess(
      clinicId: clinicId,
      intent: AuditAccessIntent.patientProfile,
      subjectId: '13000000-0000-4000-8000-000000000030',
    );

    expect(source.access!['intent'], 'patient_profile');
    expect(source.access!['requestId'], matches(RegExp(r'^[0-9a-f-]{36}$')));
  });
}

class _FakeSource implements AuditDataSource {
  _FakeSource(this.value);
  final Map<String, dynamic> value;
  Map<String, dynamic>? access;

  @override
  Future<Map<String, dynamic>> page(Map<String, dynamic> query) async => value;

  @override
  Future<Map<String, dynamic>> recordAccess(Map<String, dynamic> body) async {
    access = body;
    return {'eventId': '13000000-0000-4000-8000-000000000099'};
  }
}

Map<String, dynamic> _page() => {
  'clinicId': '13000000-0000-4000-8000-000000000010',
  'clinicTimeZone': 'Europe/Moscow',
  'rangeFrom': '2026-09-01',
  'rangeToExclusive': '2026-10-01',
  'hasMore': true,
  'nextCursor': {
    'occurredAt': '2026-09-13T09:00:00+00:00',
    'id': '13000000-0000-4000-8000-000000000051',
  },
  'actors': [
    {
      'userId': '13000000-0000-4000-8000-000000000001',
      'memberId': '13000000-0000-4000-8000-000000000020',
      'email': 'audit-owner@example.test',
      'isActive': true,
    },
  ],
  'items': [
    {
      'id': '13000000-0000-4000-8000-000000000051',
      'actorUserId': '13000000-0000-4000-8000-000000000001',
      'actorMemberId': '13000000-0000-4000-8000-000000000020',
      'actorEmail': 'audit-owner@example.test',
      'actorRoles': ['owner'],
      'category': 'financial',
      'eventType': 'payment_recorded',
      'subjectType': 'payment',
      'subjectId': '13000000-0000-4000-8000-000000000060',
      'reason': null,
      'context': {
        'patient_id': '13000000-0000-4000-8000-000000000030',
        'amount': '125.00',
        'currency': 'RUB',
      },
      'occurredAt': '2026-09-13T09:00:00+00:00',
    },
  ],
};

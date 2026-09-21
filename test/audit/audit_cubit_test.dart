import 'dart:async';

import 'package:dental_clini_management_saas/core/auth/session_coordinator.dart';
import 'package:dental_clini_management_saas/core/error/app_failure.dart';
import 'package:dental_clini_management_saas/features/audit/domain/audit_models.dart';
import 'package:dental_clini_management_saas/features/audit/domain/audit_repository.dart';
import 'package:dental_clini_management_saas/features/audit/presentation/audit_cubit.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockSessionCoordinator extends Mock implements SessionCoordinator {}

void main() {
  late _MockSessionCoordinator session;
  late AuditFilter filter;

  setUp(() {
    session = _MockSessionCoordinator();
    when(() => session.changes).thenAnswer((_) => const Stream.empty());
    filter = AuditFilter(
      fromDate: DateTime(2026, 9, 1),
      toDateExclusive: DateTime(2026, 10, 1),
    );
  });

  test('records opening before loading the first owner page', () async {
    final repository = _AuditRepository();
    final cubit = AuditCubit(repository, session);
    addTearDown(cubit.close);

    await cubit.load('clinic-a', filter);

    expect(repository.calls, ['access:clinic-a', 'page:clinic-a']);
    expect(cubit.state.status, AuditLoadStatus.ready);
    expect(cubit.state.page?.clinicId, 'clinic-a');
  });

  test('load more appends rows and advances the cursor', () async {
    final repository = _AuditRepository(hasSecondPage: true);
    final cubit = AuditCubit(repository, session);
    addTearDown(cubit.close);

    await cubit.load('clinic-a', filter);
    await cubit.loadMore();

    expect(cubit.state.page?.items, hasLength(2));
    expect(cubit.state.page?.hasMore, false);
  });

  test('refresh failure retains the previous audit page', () async {
    final repository = _AuditRepository(failSecondPageCall: true);
    final cubit = AuditCubit(repository, session);
    addTearDown(cubit.close);

    await cubit.load('clinic-a', filter);
    final previous = cubit.state.page;
    await cubit.refresh();

    expect(cubit.state.page, same(previous));
    expect(cubit.state.secondaryFailure, isA<NetworkFailure>());
  });
}

class _AuditRepository implements AuditRepository {
  _AuditRepository({
    this.hasSecondPage = false,
    this.failSecondPageCall = false,
  });

  final bool hasSecondPage;
  final bool failSecondPageCall;
  final calls = <String>[];
  int pageCalls = 0;

  @override
  Future<AuditPage> page({
    required String clinicId,
    required AuditFilter filter,
    AuditCursor? cursor,
    int limit = 50,
  }) async {
    calls.add('page:$clinicId');
    pageCalls++;
    if (failSecondPageCall && pageCalls == 2) throw const NetworkFailure();
    final second = cursor != null;
    return AuditPage(
      clinicId: clinicId,
      clinicTimeZone: 'Europe/Moscow',
      fromDate: filter.fromDate,
      toDateExclusive: filter.toDateExclusive,
      items: [
        _event(
          second
              ? '13000000-0000-4000-8000-000000000052'
              : '13000000-0000-4000-8000-000000000051',
        ),
      ],
      actors: const [],
      hasMore: hasSecondPage && !second,
      nextCursor: hasSecondPage && !second
          ? AuditCursor(
              occurredAt: DateTime.utc(2026, 9, 13, 9),
              id: '13000000-0000-4000-8000-000000000051',
            )
          : null,
    );
  }

  @override
  Future<void> recordAccess({
    required String clinicId,
    required AuditAccessIntent intent,
    required String subjectId,
    String? requestId,
    int? resultCount,
    int? pageSize,
    bool? searchPresent,
  }) async => calls.add('access:$clinicId');
}

AuditEvent _event(String id) => AuditEvent(
  id: id,
  actorUserId: '13000000-0000-4000-8000-000000000001',
  actorRoles: const {'owner'},
  category: AuditCategory.access,
  eventType: 'audit_log_opened',
  subjectType: 'clinic',
  subjectId: '13000000-0000-4000-8000-000000000010',
  context: const AuditContext(),
  occurredAt: DateTime.utc(2026, 9, 13, 9),
);

import 'package:bloc_test/bloc_test.dart';
import 'package:dental_clini_management_saas/features/clinical_session/domain/clinical_session_models.dart';
import 'package:dental_clini_management_saas/features/clinical_session/domain/clinical_session_repository.dart';
import 'package:dental_clini_management_saas/features/clinical_session/presentation/clinical_session_cubit.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late _FakeRepository repository;

  setUp(() => repository = _FakeRepository());

  blocTest<ClinicalSessionCubit, ClinicalSessionState>(
    'loads patient visits and selects the newest session',
    build: () => ClinicalSessionCubit(repository),
    act: (cubit) => cubit.load('patient-1'),
    verify: (cubit) {
      expect(cubit.state.status, ClinicalSessionLoadStatus.ready);
      expect(cubit.state.selectedSessionId, 'session-1');
      expect(cubit.state.amendments.single.reason, 'Correction');
    },
  );

  blocTest<ClinicalSessionCubit, ClinicalSessionState>(
    'creates a walk-in draft and refreshes to the created session',
    build: () => ClinicalSessionCubit(repository),
    act: (cubit) async {
      await cubit.load('patient-1');
      await cubit.create(
        ClinicalSessionDraft(
          patientId: 'patient-1',
          dentistMemberId: 'dentist-1',
          sessionDate: DateTime.utc(2026, 9, 9),
        ),
      );
    },
    verify: (cubit) {
      expect(repository.created, isTrue);
      expect(cubit.state.selectedSessionId, 'created-session');
      expect(cubit.state.status, ClinicalSessionLoadStatus.ready);
    },
  );

  blocTest<ClinicalSessionCubit, ClinicalSessionState>(
    'keeps the loaded draft and exposes a revision conflict safely',
    build: () => ClinicalSessionCubit(repository),
    act: (cubit) async {
      await cubit.load('patient-1');
      repository.failRevision = true;
      await cubit.saveDraft(
        sessionId: 'session-1',
        clinicalNotes: 'Stale',
        recommendations: null,
        expectedRevision: 1,
      );
    },
    verify: (cubit) {
      expect(cubit.state.issue, ClinicalSessionOperationIssue.revisionConflict);
      expect(cubit.state.sessions, isNotEmpty);
    },
  );
}

class _FakeRepository implements ClinicalSessionRepository {
  bool created = false;
  bool failRevision = false;

  @override
  Future<List<ClinicalSession>> sessions({
    required String patientId,
    required int offset,
    required int limit,
  }) async {
    final id = created ? 'created-session' : 'session-1';
    return [
      ClinicalSession(
        id: id,
        clinicId: 'clinic-1',
        patientId: patientId,
        dentistMemberId: 'dentist-1',
        sessionDate: DateTime.utc(2026, 9, 9),
        clinicalNotes: 'Notes',
        status: ClinicalSessionStatus.finalized,
        revision: 2,
        createdBy: 'user-1',
        updatedBy: 'user-1',
        createdAt: DateTime.utc(2026, 9, 9),
        updatedAt: DateTime.utc(2026, 9, 9),
      ),
    ];
  }

  @override
  Future<List<ClinicalSessionAmendment>> amendments(String sessionId) async => [
    ClinicalSessionAmendment(
      id: 'amendment-1',
      clinicalSessionId: sessionId,
      amendmentText: 'Updated wording',
      reason: 'Correction',
      amendedBy: 'user-1',
      amendedAt: DateTime.utc(2026, 9, 9),
    ),
  ];

  @override
  Future<List<EligibleSessionAppointment>> eligibleAppointments(
    String patientId,
  ) async => const [];

  @override
  Future<String> createSession(ClinicalSessionDraft draft) async {
    created = true;
    return 'created-session';
  }

  @override
  Future<void> updateDraft({
    required String sessionId,
    required String? clinicalNotes,
    required String? recommendations,
    required int expectedRevision,
  }) async {
    if (failRevision) {
      throw const ClinicalSessionOperationException(
        ClinicalSessionOperationIssue.revisionConflict,
      );
    }
  }

  @override
  Future<void> addAmendment({
    required String sessionId,
    required String amendmentText,
    required String reason,
  }) async {}

  @override
  Future<void> finalizeSession(String sessionId, int expectedRevision) async {}

  @override
  Future<void> markInError({
    required String sessionId,
    required int expectedRevision,
    required String reason,
  }) async {}
}

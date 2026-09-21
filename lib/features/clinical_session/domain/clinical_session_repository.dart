import 'clinical_session_models.dart';

abstract class ClinicalSessionRepository {
  Future<List<ClinicalSession>> sessions({
    required String patientId,
    required int offset,
    required int limit,
  });

  Future<List<ClinicalSessionAmendment>> amendments(String sessionId);

  Future<List<EligibleSessionAppointment>> eligibleAppointments(
    String patientId,
  );

  Future<String> createSession(ClinicalSessionDraft draft);

  Future<void> updateDraft({
    required String sessionId,
    required String? clinicalNotes,
    required String? recommendations,
    required int expectedRevision,
  });

  Future<void> finalizeSession(String sessionId, int expectedRevision);

  Future<void> markInError({
    required String sessionId,
    required int expectedRevision,
    required String reason,
  });

  Future<void> addAmendment({
    required String sessionId,
    required String amendmentText,
    required String reason,
  });
}

import 'package:injectable/injectable.dart';

import '../domain/clinical_session_models.dart';
import '../domain/clinical_session_repository.dart';
import 'clinical_session_data_source.dart';

@LazySingleton(as: ClinicalSessionRepository)
class SupabaseClinicalSessionRepository implements ClinicalSessionRepository {
  SupabaseClinicalSessionRepository(this._source);

  final ClinicalSessionDataSource _source;

  @override
  Future<List<ClinicalSession>> sessions({
    required String patientId,
    required int offset,
    required int limit,
  }) async => (await _source.sessionRows(
    patientId: patientId,
    offset: offset,
    limit: limit,
  )).map(_session).toList(growable: false);

  @override
  Future<List<ClinicalSessionAmendment>> amendments(String sessionId) async =>
      (await _source.amendmentRows(
        sessionId,
      )).map(_amendment).toList(growable: false);

  @override
  Future<List<EligibleSessionAppointment>> eligibleAppointments(
    String patientId,
  ) async => (await _source.eligibleAppointmentRows(
    patientId,
  )).map(_appointment).toList(growable: false);

  @override
  Future<String> createSession(ClinicalSessionDraft draft) async {
    final response = await _source.invokeAction({
      'action': 'create_session',
      'patientId': draft.patientId,
      'appointmentId': draft.appointmentId,
      'dentistMemberId': draft.dentistMemberId,
      'sessionDate': draft.sessionDate?.toUtc().toIso8601String(),
    });
    return response['sessionId'] as String;
  }

  @override
  Future<void> updateDraft({
    required String sessionId,
    required String? clinicalNotes,
    required String? recommendations,
    required int expectedRevision,
  }) => _source.invokeAction({
    'action': 'update_draft_session',
    'sessionId': sessionId,
    'clinicalNotes': clinicalNotes,
    'recommendations': recommendations,
    'expectedRevision': expectedRevision,
  });

  @override
  Future<void> finalizeSession(String sessionId, int expectedRevision) =>
      _source.invokeAction({
        'action': 'finalize_session',
        'sessionId': sessionId,
        'expectedRevision': expectedRevision,
      });

  @override
  Future<void> markInError({
    required String sessionId,
    required int expectedRevision,
    required String reason,
  }) => _source.invokeAction({
    'action': 'mark_draft_session_in_error',
    'sessionId': sessionId,
    'expectedRevision': expectedRevision,
    'reason': reason,
  });

  @override
  Future<void> addAmendment({
    required String sessionId,
    required String amendmentText,
    required String reason,
  }) => _source.invokeAction({
    'action': 'add_session_amendment',
    'sessionId': sessionId,
    'amendmentText': amendmentText,
    'reason': reason,
  });

  ClinicalSession _session(Map<String, dynamic> row) => ClinicalSession(
    id: row['id'] as String,
    clinicId: row['clinic_id'] as String,
    patientId: row['patient_id'] as String,
    appointmentId: row['appointment_id'] as String?,
    dentistMemberId: row['dentist_member_id'] as String,
    sessionDate: _date(row['session_date'])!,
    clinicalNotes: row['clinical_notes'] as String?,
    recommendations: row['recommendations'] as String?,
    status: ClinicalSessionStatus.fromApi(row['status']),
    revision: row['revision'] as int,
    createdBy: row['created_by'] as String,
    updatedBy: row['updated_by'] as String,
    finalizedBy: row['finalized_by'] as String?,
    finalizedAt: _date(row['finalized_at']),
    errorReason: row['error_reason'] as String?,
    markedInErrorBy: row['marked_in_error_by'] as String?,
    markedInErrorAt: _date(row['marked_in_error_at']),
    createdAt: _date(row['created_at'])!,
    updatedAt: _date(row['updated_at'])!,
  );

  ClinicalSessionAmendment _amendment(Map<String, dynamic> row) =>
      ClinicalSessionAmendment(
        id: row['id'] as String,
        clinicalSessionId: row['clinical_session_id'] as String,
        amendmentText: row['amendment_text'] as String,
        reason: row['reason'] as String,
        amendedBy: row['amended_by'] as String,
        amendedAt: _date(row['amended_at'])!,
      );

  EligibleSessionAppointment _appointment(Map<String, dynamic> row) =>
      EligibleSessionAppointment(
        id: row['id'] as String,
        dentistMemberId: row['dentist_member_id'] as String,
        startsAt: _date(row['starts_at'])!,
        status: row['status'] as String,
        purpose: row['purpose'] as String?,
      );

  DateTime? _date(Object? value) =>
      value is String ? DateTime.parse(value).toUtc() : null;
}

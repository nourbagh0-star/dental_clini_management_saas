enum ClinicalSessionStatus {
  draft,
  finalized,
  enteredInError;

  static ClinicalSessionStatus fromApi(Object? value) => switch (value) {
    'finalized' => ClinicalSessionStatus.finalized,
    'entered_in_error' => ClinicalSessionStatus.enteredInError,
    _ => ClinicalSessionStatus.draft,
  };
}

class ClinicalSession {
  const ClinicalSession({
    required this.id,
    required this.clinicId,
    required this.patientId,
    required this.dentistMemberId,
    required this.sessionDate,
    required this.status,
    required this.revision,
    required this.createdBy,
    required this.updatedBy,
    required this.createdAt,
    required this.updatedAt,
    this.appointmentId,
    this.clinicalNotes,
    this.recommendations,
    this.finalizedBy,
    this.finalizedAt,
    this.errorReason,
    this.markedInErrorBy,
    this.markedInErrorAt,
  });

  final String id;
  final String clinicId;
  final String patientId;
  final String? appointmentId;
  final String dentistMemberId;
  final DateTime sessionDate;
  final String? clinicalNotes;
  final String? recommendations;
  final ClinicalSessionStatus status;
  final int revision;
  final String createdBy;
  final String updatedBy;
  final String? finalizedBy;
  final DateTime? finalizedAt;
  final String? errorReason;
  final String? markedInErrorBy;
  final DateTime? markedInErrorAt;
  final DateTime createdAt;
  final DateTime updatedAt;
}

class ClinicalSessionAmendment {
  const ClinicalSessionAmendment({
    required this.id,
    required this.clinicalSessionId,
    required this.amendmentText,
    required this.reason,
    required this.amendedBy,
    required this.amendedAt,
  });

  final String id;
  final String clinicalSessionId;
  final String amendmentText;
  final String reason;
  final String amendedBy;
  final DateTime amendedAt;
}

class EligibleSessionAppointment {
  const EligibleSessionAppointment({
    required this.id,
    required this.dentistMemberId,
    required this.startsAt,
    required this.status,
    this.purpose,
  });

  final String id;
  final String dentistMemberId;
  final DateTime startsAt;
  final String status;
  final String? purpose;
}

class ClinicalSessionDraft {
  const ClinicalSessionDraft({
    required this.patientId,
    this.appointmentId,
    this.dentistMemberId,
    this.sessionDate,
  });

  final String patientId;
  final String? appointmentId;
  final String? dentistMemberId;
  final DateTime? sessionDate;
}

enum ClinicalSessionOperationIssue {
  forbidden,
  unavailable,
  appointmentHasSession,
  appointmentNotEligible,
  dentistMismatch,
  notesRequired,
  draftOnly,
  finalizedRequired,
  revisionConflict,
  immutable,
  invalidInput,
}

class ClinicalSessionOperationException implements Exception {
  const ClinicalSessionOperationException(this.issue);
  final ClinicalSessionOperationIssue issue;
}

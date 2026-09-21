enum AuditCategory {
  access,
  patientAdministration,
  scheduling,
  clinical,
  financial,
  staffSecurity;

  String get apiValue => switch (this) {
    AuditCategory.patientAdministration => 'patient_administration',
    AuditCategory.staffSecurity => 'staff_security',
    _ => name,
  };

  static AuditCategory? fromApi(Object? value) => switch (value) {
    'access' => AuditCategory.access,
    'patient_administration' => AuditCategory.patientAdministration,
    'scheduling' => AuditCategory.scheduling,
    'clinical' => AuditCategory.clinical,
    'financial' => AuditCategory.financial,
    'staff_security' => AuditCategory.staffSecurity,
    _ => null,
  };
}

class AuditCursor {
  const AuditCursor({required this.occurredAt, required this.id});

  final DateTime occurredAt;
  final String id;
}

class AuditFilter {
  const AuditFilter({
    required this.fromDate,
    required this.toDateExclusive,
    this.actorUserId,
    this.category,
    this.eventType,
    this.subjectType,
  });

  final DateTime fromDate;
  final DateTime toDateExclusive;
  final String? actorUserId;
  final AuditCategory? category;
  final String? eventType;
  final String? subjectType;

  AuditFilter copyWith({
    DateTime? fromDate,
    DateTime? toDateExclusive,
    String? actorUserId,
    bool clearActor = false,
    AuditCategory? category,
    bool clearCategory = false,
    String? eventType,
    bool clearEventType = false,
    String? subjectType,
    bool clearSubjectType = false,
  }) => AuditFilter(
    fromDate: fromDate ?? this.fromDate,
    toDateExclusive: toDateExclusive ?? this.toDateExclusive,
    actorUserId: clearActor ? null : actorUserId ?? this.actorUserId,
    category: clearCategory ? null : category ?? this.category,
    eventType: clearEventType ? null : eventType ?? this.eventType,
    subjectType: clearSubjectType ? null : subjectType ?? this.subjectType,
  );

  int get appliedCount => [
    actorUserId,
    category,
    eventType,
    subjectType,
  ].where((v) => v != null).length;
}

class AuditActorOption {
  const AuditActorOption({
    required this.userId,
    required this.memberId,
    required this.email,
    required this.isActive,
  });

  final String userId;
  final String memberId;
  final String email;
  final bool isActive;
}

class AuditContext {
  const AuditContext({
    this.patientId,
    this.invoiceId,
    this.appointmentId,
    this.memberId,
    this.amount,
    this.currency,
    this.previousStatus,
    this.nextStatus,
    this.resultCount,
    this.searchPresent,
  });

  final String? patientId;
  final String? invoiceId;
  final String? appointmentId;
  final String? memberId;
  final String? amount;
  final String? currency;
  final String? previousStatus;
  final String? nextStatus;
  final int? resultCount;
  final bool? searchPresent;
}

class AuditEvent {
  const AuditEvent({
    required this.id,
    required this.actorUserId,
    required this.actorRoles,
    required this.category,
    required this.eventType,
    required this.subjectType,
    required this.subjectId,
    required this.context,
    required this.occurredAt,
    this.actorMemberId,
    this.actorEmail,
    this.reason,
  });

  final String id;
  final String actorUserId;
  final String? actorMemberId;
  final String? actorEmail;
  final Set<String> actorRoles;
  final AuditCategory category;
  final String eventType;
  final String subjectType;
  final String subjectId;
  final String? reason;
  final AuditContext context;
  final DateTime occurredAt;
}

class AuditPage {
  const AuditPage({
    required this.clinicId,
    required this.clinicTimeZone,
    required this.fromDate,
    required this.toDateExclusive,
    required this.items,
    required this.actors,
    required this.hasMore,
    this.nextCursor,
  });

  final String clinicId;
  final String clinicTimeZone;
  final DateTime fromDate;
  final DateTime toDateExclusive;
  final List<AuditEvent> items;
  final List<AuditActorOption> actors;
  final bool hasMore;
  final AuditCursor? nextCursor;
}

enum AuditAccessIntent {
  auditLog,
  patientSearch,
  patientProfile,
  medicalRecord,
  odontogram,
  treatmentPlan,
  clinicalSessions,
  patientFiles,
  filePreview,
  fileDownload;

  String get apiValue => switch (this) {
    AuditAccessIntent.auditLog => 'audit_log',
    AuditAccessIntent.patientSearch => 'patient_search',
    AuditAccessIntent.patientProfile => 'patient_profile',
    AuditAccessIntent.medicalRecord => 'medical_record',
    AuditAccessIntent.treatmentPlan => 'treatment_plan',
    AuditAccessIntent.clinicalSessions => 'clinical_sessions',
    AuditAccessIntent.patientFiles => 'patient_files',
    AuditAccessIntent.filePreview => 'file_preview',
    AuditAccessIntent.fileDownload => 'file_download',
    _ => name,
  };
}

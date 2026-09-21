enum ScheduleExceptionKind {
  leave,
  unavailable;

  String get apiValue => name;

  static ScheduleExceptionKind? fromApi(Object? value) => switch (value) {
    'leave' => ScheduleExceptionKind.leave,
    'unavailable' => ScheduleExceptionKind.unavailable,
    _ => null,
  };
}

enum ScheduleOperationIssue {
  invalidInput,
  editForbidden,
  activeDentistRequired,
  effectiveDateInvalid,
  exceptionUnavailable,
  affectedAppointments,
}

class ScheduleImpactPreview {
  const ScheduleImpactPreview({required this.count});
  final int count;
}

class ScheduleOperationException implements Exception {
  const ScheduleOperationException(this.issue);

  final ScheduleOperationIssue issue;

  @override
  String toString() => 'ScheduleOperationException(${issue.name})';
}

class DoctorScheduleBreak {
  const DoctorScheduleBreak({
    required this.id,
    required this.startsAt,
    required this.endsAt,
  });

  final String id;
  final String startsAt;
  final String endsAt;
}

class DoctorWorkingPeriod {
  const DoctorWorkingPeriod({
    required this.id,
    required this.weekday,
    required this.startsAt,
    required this.endsAt,
    required this.breaks,
  });

  final String id;
  final int weekday;
  final String startsAt;
  final String endsAt;
  final List<DoctorScheduleBreak> breaks;
}

class DoctorScheduleVersion {
  const DoctorScheduleVersion({
    required this.id,
    required this.clinicId,
    required this.dentistMemberId,
    required this.effectiveFrom,
    required this.workingPeriods,
  });

  final String id;
  final String clinicId;
  final String dentistMemberId;

  /// A clinic-local ISO calendar date, never an instant.
  final String effectiveFrom;
  final List<DoctorWorkingPeriod> workingPeriods;
}

class DoctorScheduleException {
  const DoctorScheduleException({
    required this.id,
    required this.clinicId,
    required this.dentistMemberId,
    required this.kind,
    required this.startsAt,
    required this.endsAt,
    this.reason,
  });

  final String id;
  final String clinicId;
  final String dentistMemberId;
  final ScheduleExceptionKind kind;
  final DateTime startsAt;
  final DateTime endsAt;
  final String? reason;
}

class ScheduleDentist {
  const ScheduleDentist({required this.memberId, required this.displayName});

  final String memberId;
  final String displayName;
}

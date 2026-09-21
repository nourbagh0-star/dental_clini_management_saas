enum AppointmentStatus {
  scheduled,
  confirmed,
  inProgress,
  completed,
  cancelled,
  noShow;

  String get apiValue => switch (this) {
    AppointmentStatus.inProgress => 'in_progress',
    AppointmentStatus.noShow => 'no_show',
    _ => name,
  };

  static AppointmentStatus fromApi(Object? value) => switch (value) {
    'confirmed' => AppointmentStatus.confirmed,
    'in_progress' => AppointmentStatus.inProgress,
    'completed' => AppointmentStatus.completed,
    'cancelled' => AppointmentStatus.cancelled,
    'no_show' => AppointmentStatus.noShow,
    _ => AppointmentStatus.scheduled,
  };
}

enum AppointmentOperationIssue {
  unavailable,
  forbidden,
  patientOverlap,
  dentistOverlap,
  workingHours,
  leave,
  unavailablePeriod,
  overrideReasonRequired,
  invalidTransition,
}

class AppointmentOperationException implements Exception {
  const AppointmentOperationException(this.issue);
  final AppointmentOperationIssue issue;
}

class Appointment {
  const Appointment({
    required this.id,
    required this.clinicId,
    required this.patientId,
    required this.patientName,
    required this.patientNumber,
    required this.dentistMemberId,
    required this.dentistName,
    required this.startsAt,
    required this.endsAt,
    required this.status,
    this.purpose,
    this.overrideReason,
    this.preparationNote,
  });
  final String id;
  final String clinicId;
  final String patientId;
  final String patientName;
  final String patientNumber;
  final String dentistMemberId;
  final String dentistName;
  final DateTime startsAt;
  final DateTime endsAt;
  final AppointmentStatus status;
  final String? purpose;
  final String? overrideReason;
  final String? preparationNote;

  Duration get duration => endsAt.difference(startsAt);
}

class AppointmentDraft {
  const AppointmentDraft({
    required this.clinicId,
    required this.patientId,
    required this.dentistMemberId,
    required this.startsAt,
    required this.endsAt,
    this.purpose,
    this.overrideReason,
  });
  final String clinicId;
  final String patientId;
  final String dentistMemberId;
  final DateTime startsAt;
  final DateTime endsAt;
  final String? purpose;
  final String? overrideReason;
}

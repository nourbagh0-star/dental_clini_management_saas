import 'schedule_models.dart';

abstract interface class ScheduleRepository {
  Future<List<DoctorScheduleVersion>> getScheduleVersions(String clinicId);

  Future<List<DoctorScheduleException>> getScheduleExceptions(String clinicId);

  Future<List<ScheduleDentist>> getManageableDentists(String clinicId);

  Future<String> replaceWeeklySchedule({
    required String dentistMemberId,
    required String effectiveFrom,
    required List<DoctorWorkingPeriod> periods,
    bool confirmAffectedAppointments = false,
    String? appointmentImpactReason,
  });

  Future<ScheduleImpactPreview> previewWeeklyImpact({
    required String dentistMemberId,
    required String effectiveFrom,
    required List<DoctorWorkingPeriod> periods,
  });

  Future<String> createException({
    required String dentistMemberId,
    required ScheduleExceptionKind kind,
    required DateTime startsAt,
    required DateTime endsAt,
    String? reason,
    bool confirmAffectedAppointments = false,
    String? appointmentImpactReason,
  });

  Future<ScheduleImpactPreview> previewExceptionImpact({
    required String dentistMemberId,
    required DateTime startsAt,
    required DateTime endsAt,
  });

  Future<void> updateException({
    required String exceptionId,
    required ScheduleExceptionKind kind,
    required DateTime startsAt,
    required DateTime endsAt,
    String? reason,
  });

  Future<void> deleteException(String exceptionId);
}

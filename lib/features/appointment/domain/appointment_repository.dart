import 'appointment_models.dart';

abstract interface class AppointmentRepository {
  Future<List<Appointment>> listRange({
    required String clinicId,
    required DateTime from,
    required DateTime until,
  });
  Future<void> create(AppointmentDraft draft);
  Future<void> reschedule({
    required String appointmentId,
    required DateTime startsAt,
    required DateTime endsAt,
    String? overrideReason,
  });
  Future<void> transition({
    required String appointmentId,
    required AppointmentStatus status,
    String? cancellationReason,
  });
  Future<void> savePreparationNote({
    required String appointmentId,
    required String note,
  });
}

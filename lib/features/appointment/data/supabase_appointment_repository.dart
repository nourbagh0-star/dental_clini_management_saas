import 'package:injectable/injectable.dart';

import '../domain/appointment_models.dart';
import '../domain/appointment_repository.dart';
import 'appointment_data_source.dart';

@LazySingleton(as: AppointmentRepository)
class SupabaseAppointmentRepository implements AppointmentRepository {
  SupabaseAppointmentRepository(this._source);
  final AppointmentDataSource _source;

  @override
  Future<List<Appointment>> listRange({
    required String clinicId,
    required DateTime from,
    required DateTime until,
  }) async => (await _source.listRows(
    clinicId: clinicId,
    from: from,
    until: until,
  )).map(_appointment).toList(growable: false);

  @override
  Future<void> create(AppointmentDraft draft) async {
    await _source.invokeAction({
      'action': 'create',
      'clinicId': draft.clinicId,
      'patientId': draft.patientId,
      'dentistMemberId': draft.dentistMemberId,
      'startsAt': draft.startsAt.toUtc().toIso8601String(),
      'endsAt': draft.endsAt.toUtc().toIso8601String(),
      'purpose': draft.purpose,
      'overrideReason': draft.overrideReason,
    });
  }

  @override
  Future<void> reschedule({
    required String appointmentId,
    required DateTime startsAt,
    required DateTime endsAt,
    String? overrideReason,
  }) async {
    await _source.invokeAction({
      'action': 'reschedule',
      'appointmentId': appointmentId,
      'startsAt': startsAt.toUtc().toIso8601String(),
      'endsAt': endsAt.toUtc().toIso8601String(),
      'overrideReason': overrideReason,
    });
  }

  @override
  Future<void> transition({
    required String appointmentId,
    required AppointmentStatus status,
    String? cancellationReason,
  }) async {
    final action = switch (status) {
      AppointmentStatus.confirmed => 'confirm',
      AppointmentStatus.inProgress => 'start',
      AppointmentStatus.completed => 'complete',
      AppointmentStatus.cancelled => 'cancel',
      AppointmentStatus.noShow => 'mark_no_show',
      AppointmentStatus.scheduled => throw ArgumentError.value(status),
    };
    await _source.invokeAction({
      'action': action,
      'appointmentId': appointmentId,
      'cancellationReason': cancellationReason,
    });
  }

  @override
  Future<void> savePreparationNote({
    required String appointmentId,
    required String note,
  }) async => _source.invokeAction({
    'action': 'save_preparation_note',
    'appointmentId': appointmentId,
    'note': note,
  });

  Appointment _appointment(Map<String, dynamic> row) {
    final patient = Map<String, dynamic>.from(row['patients'] as Map? ?? {});
    final dentist = Map<String, dynamic>.from(
      row['clinic_members'] as Map? ?? {},
    );
    final rawNote = row['appointment_preparation_notes'];
    final note = rawNote is Map
        ? Map<String, dynamic>.from(rawNote)
        : rawNote is List && rawNote.isNotEmpty && rawNote.first is Map
        ? Map<String, dynamic>.from(rawNote.first as Map)
        : const <String, dynamic>{};
    return Appointment(
      id: row['id'] as String,
      clinicId: row['clinic_id'] as String,
      patientId: row['patient_id'] as String,
      patientName:
          '${patient['first_name'] ?? ''} ${patient['last_name'] ?? ''}'.trim(),
      patientNumber: patient['patient_number'] as String? ?? '',
      dentistMemberId: row['dentist_member_id'] as String,
      dentistName: dentist['display_name'] as String? ?? '',
      startsAt: DateTime.parse(row['starts_at'] as String).toUtc(),
      endsAt: DateTime.parse(row['ends_at'] as String).toUtc(),
      status: AppointmentStatus.fromApi(row['status']),
      purpose: row['purpose'] as String?,
      overrideReason: row['override_reason'] as String?,
      preparationNote: note['note'] as String?,
    );
  }
}

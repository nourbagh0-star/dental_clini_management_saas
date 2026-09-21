import 'package:injectable/injectable.dart';

import '../../../core/error/app_failure.dart';
import '../domain/patient_models.dart';
import '../domain/patient_repository.dart';
import 'patient_data_source.dart';

@LazySingleton(as: PatientRepository)
class SupabasePatientRepository implements PatientRepository {
  SupabasePatientRepository(this._source);
  final PatientDataSource _source;

  @override
  Future<List<Patient>> search({
    required String clinicId,
    String query = '',
    int page = 0,
    int pageSize = 30,
  }) async {
    if (page < 0 || pageSize < 1 || pageSize > 100) {
      throw const ValidationFailure();
    }
    final rows = await _source.searchRows(
      clinicId: clinicId,
      query: query,
      offset: page * pageSize,
      limit: pageSize,
    );
    return rows.map(_patient).toList(growable: false);
  }

  @override
  Future<PatientMedicalProfile?> medicalProfile(String patientId) async {
    final row = await _source.medicalProfileRow(patientId);
    if (row == null) return null;
    return PatientMedicalProfile(
      allergies: _nullable(row['allergies']),
      currentMedications: _nullable(row['current_medications']),
      chronicConditions: _nullable(row['chronic_conditions']),
      importantMedicalNotes: _nullable(row['important_medical_notes']),
    );
  }

  @override
  Future<void> upsertMedicalProfile({
    required String patientId,
    required PatientMedicalProfile profile,
  }) async {
    final response = await _source.invokePatientAction({
      'action': 'upsert_medical',
      'patientId': patientId,
      'medical': {
        'allergies': profile.allergies,
        'currentMedications': profile.currentMedications,
        'chronicConditions': profile.chronicConditions,
        'importantMedicalNotes': profile.importantMedicalNotes,
      },
    });
    if (response['ok'] != true) throw const ServerFailure();
  }

  @override
  Future<void> setArchived({
    required String patientId,
    required bool isArchived,
  }) async {
    final response = await _source.invokePatientAction({
      'action': 'set_archived',
      'patientId': patientId,
      'isArchived': isArchived,
    });
    if (response['ok'] != true) throw const ServerFailure();
  }

  @override
  Future<String> create({
    required String clinicId,
    required PatientDraft input,
  }) async {
    final response = await _source.invokePatientAction({
      'action': 'create',
      'clinicId': clinicId,
      'demographic': _draft(input),
    });
    final patientId = response['patientId'];
    if (patientId is! String || patientId.isEmpty) throw const ServerFailure();
    return patientId;
  }

  Patient _patient(Map<String, dynamic> row) => Patient(
    id: _string(row, 'id'),
    clinicId: _string(row, 'clinic_id'),
    patientNumber: _string(row, 'patient_number'),
    firstName: _string(row, 'first_name'),
    lastName: _string(row, 'last_name'),
    middleName: _nullable(row['middle_name']),
    phone: _nullable(row['phone']),
    email: _nullable(row['email']),
    birthDate: _nullable(row['birth_date']),
    birthDatePrecision:
        BirthDatePrecision.fromApi(row['birth_date_precision']) ??
        (throw const ServerFailure()),
    approximateAgeYears: row['approximate_age_years'] as int?,
    ageAssessedAt: _nullable(row['age_assessed_at']),
    isMinorDeclared: row['is_minor_declared'] as bool? ?? false,
    guardianName: _nullable(row['guardian_name']),
    guardianPhone: _nullable(row['guardian_phone']),
    guardianEmail: _nullable(row['guardian_email']),
    administrativeNotes: _nullable(row['administrative_notes']),
    isArchived: row['archived_at'] != null,
  );

  Map<String, dynamic> _draft(PatientDraft value) => {
    'firstName': value.firstName,
    'lastName': value.lastName,
    'middleName': value.middleName,
    'phone': value.phone,
    'email': value.email,
    'birthDate': value.birthDate,
    'birthDatePrecision': value.birthDatePrecision.apiValue,
    'approximateAgeYears': value.approximateAgeYears,
    'ageAssessedAt': value.ageAssessedAt,
    'isMinorDeclared': value.isMinorDeclared,
    'guardianName': value.guardianName,
    'guardianPhone': value.guardianPhone,
    'guardianEmail': value.guardianEmail,
    'administrativeNotes': value.administrativeNotes,
  };
  String _string(Map<String, dynamic> row, String key) =>
      row[key] is String && (row[key] as String).isNotEmpty
      ? row[key] as String
      : throw const ServerFailure();
  String? _nullable(Object? value) => value is String && value.isNotEmpty
      ? value
      : value == null
      ? null
      : throw const ServerFailure();
}

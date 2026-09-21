import 'patient_models.dart';

abstract interface class PatientRepository {
  Future<List<Patient>> search({
    required String clinicId,
    String query = '',
    int page = 0,
    int pageSize = 30,
  });

  Future<PatientMedicalProfile?> medicalProfile(String patientId);

  Future<void> upsertMedicalProfile({
    required String patientId,
    required PatientMedicalProfile profile,
  });

  Future<void> setArchived({
    required String patientId,
    required bool isArchived,
  });

  Future<String> create({
    required String clinicId,
    required PatientDraft input,
  });
}

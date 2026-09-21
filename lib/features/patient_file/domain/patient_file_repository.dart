import 'patient_file_models.dart';

abstract class PatientFileRepository {
  Future<List<PatientFile>> files({
    required String patientId,
    required bool includeArchived,
    required PatientFileCategory? category,
    required int offset,
    required int limit,
  });

  Future<String> upload({
    required PatientFileDraft draft,
    required SelectedPatientFile file,
    required void Function(int sentBytes, int totalBytes) onProgress,
  });

  Future<void> cancelActiveUpload();
  Future<PatientFileReadAccess> readAccess(
    String fileId, {
    required bool preview,
  });
  Future<void> archive(String fileId, String reason);
  Future<void> restore(String fileId);
  Future<void> reconcilePending(String clinicId);
}

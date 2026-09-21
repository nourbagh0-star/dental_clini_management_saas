import 'patient_file_models.dart';

abstract class FileTransferClient {
  Future<void> upload({
    required PatientFileUploadTarget target,
    required SelectedPatientFile file,
    required void Function(int sentBytes, int totalBytes) onProgress,
  });

  void cancelActiveUpload();
  void dispose();
}

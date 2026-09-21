import 'dart:typed_data';

enum PatientFileCategory {
  xRay('x_ray'),
  clinicalPhoto('clinical_photo'),
  consent('consent'),
  referral('referral'),
  laboratoryResult('laboratory_result'),
  other('other');

  const PatientFileCategory(this.apiValue);
  final String apiValue;

  static PatientFileCategory fromApi(Object? value) => values.firstWhere(
    (item) => item.apiValue == value,
    orElse: () => PatientFileCategory.other,
  );
}

enum PatientFileStatus {
  pendingUpload,
  available,
  archived,
  rejected;

  static PatientFileStatus fromApi(Object? value) => switch (value) {
    'available' => PatientFileStatus.available,
    'archived' => PatientFileStatus.archived,
    'rejected' => PatientFileStatus.rejected,
    _ => PatientFileStatus.pendingUpload,
  };
}

class PatientFile {
  const PatientFile({
    required this.id,
    required this.clinicId,
    required this.patientId,
    required this.category,
    required this.originalFilename,
    required this.mimeType,
    required this.sizeBytes,
    required this.status,
    required this.uploadedBy,
    required this.availableAt,
    required this.createdAt,
    this.appointmentId,
    this.clinicalSessionId,
    this.replacesFileId,
    this.description,
    this.archivedAt,
    this.archivedBy,
    this.archiveReason,
  });

  final String id;
  final String clinicId;
  final String patientId;
  final String? appointmentId;
  final String? clinicalSessionId;
  final String? replacesFileId;
  final PatientFileCategory category;
  final String? description;
  final String originalFilename;
  final String mimeType;
  final int sizeBytes;
  final PatientFileStatus status;
  final String uploadedBy;
  final DateTime availableAt;
  final DateTime? archivedAt;
  final String? archivedBy;
  final String? archiveReason;
  final DateTime createdAt;

  bool get isImage => mimeType == 'image/jpeg' || mimeType == 'image/png';
  bool get isArchived => status == PatientFileStatus.archived;
}

class SelectedPatientFile {
  const SelectedPatientFile({
    required this.name,
    required this.extension,
    required this.mimeType,
    required this.bytes,
  });

  final String name;
  final String extension;
  final String mimeType;
  final Uint8List bytes;
  int get sizeBytes => bytes.length;
}

class PatientFileDraft {
  const PatientFileDraft({
    required this.patientId,
    required this.category,
    this.description,
    this.appointmentId,
    this.clinicalSessionId,
    this.replacesFileId,
  });

  final String patientId;
  final PatientFileCategory category;
  final String? description;
  final String? appointmentId;
  final String? clinicalSessionId;
  final String? replacesFileId;
}

class PatientFileUploadTarget {
  const PatientFileUploadTarget({
    required this.fileId,
    required this.bucket,
    required this.objectPath,
    required this.expiresAt,
  });

  final String fileId;
  final String bucket;
  final String objectPath;
  final DateTime expiresAt;
}

class PatientFileReadAccess {
  const PatientFileReadAccess({
    required this.url,
    required this.mimeType,
    required this.filename,
    required this.expiresIn,
  });

  final Uri url;
  final String mimeType;
  final String filename;
  final Duration expiresIn;
}

enum PatientFileOperationIssue {
  forbidden,
  unavailable,
  patientArchived,
  invalidName,
  typeNotAllowed,
  tooLarge,
  empty,
  uploadExpired,
  uploadMissing,
  signatureMismatch,
  invalidState,
  storageUnavailable,
  invalidInput,
}

class PatientFileOperationException implements Exception {
  const PatientFileOperationException(this.issue);
  final PatientFileOperationIssue issue;
}

enum PatientFileSelectionIssue {
  cancelled,
  invalidName,
  typeNotAllowed,
  tooLarge,
  empty,
  signatureMismatch,
}

class PatientFileSelectionException implements Exception {
  const PatientFileSelectionException(this.issue);
  final PatientFileSelectionIssue issue;
}

import 'dart:typed_data';

import 'package:bloc_test/bloc_test.dart';
import 'package:dental_clini_management_saas/features/patient_file/domain/patient_file_models.dart';
import 'package:dental_clini_management_saas/features/patient_file/domain/patient_file_repository.dart';
import 'package:dental_clini_management_saas/features/patient_file/presentation/patient_file_cubit.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late _FakeRepository repository;
  setUp(() => repository = _FakeRepository());

  blocTest<PatientFileCubit, PatientFileState>(
    'loads files and selects the newest record',
    build: () => PatientFileCubit(repository),
    act: (cubit) => cubit.load('patient-1', 'clinic-1'),
    verify: (cubit) {
      expect(cubit.state.status, PatientFileLoadStatus.ready);
      expect(cubit.state.selectedFileId, 'file-1');
      expect(repository.reconciled, isTrue);
    },
  );

  blocTest<PatientFileCubit, PatientFileState>(
    'reports upload progress and refreshes to the accepted file',
    build: () => PatientFileCubit(repository),
    act: (cubit) async {
      await cubit.load('patient-1', 'clinic-1');
      await cubit.upload(
        const PatientFileDraft(
          patientId: 'patient-1',
          category: PatientFileCategory.xRay,
        ),
        SelectedPatientFile(
          name: 'demo.jpg',
          extension: 'jpg',
          mimeType: 'image/jpeg',
          bytes: Uint8List.fromList([0xff, 0xd8, 0xff]),
        ),
      );
    },
    verify: (cubit) {
      expect(repository.uploaded, isTrue);
      expect(cubit.state.uploading, isFalse);
      expect(cubit.state.selectedFileId, 'uploaded-file');
    },
  );

  blocTest<PatientFileCubit, PatientFileState>(
    'exposes a typed signature failure without provider details',
    build: () => PatientFileCubit(repository),
    act: (cubit) async {
      await cubit.load('patient-1', 'clinic-1');
      repository.failUpload = true;
      await cubit.upload(
        const PatientFileDraft(
          patientId: 'patient-1',
          category: PatientFileCategory.other,
        ),
        SelectedPatientFile(
          name: 'demo.pdf',
          extension: 'pdf',
          mimeType: 'application/pdf',
          bytes: Uint8List.fromList([0x25, 0x50, 0x44, 0x46, 0x2d]),
        ),
      );
    },
    verify: (cubit) =>
        expect(cubit.state.issue, PatientFileOperationIssue.signatureMismatch),
  );
}

class _FakeRepository implements PatientFileRepository {
  bool uploaded = false;
  bool reconciled = false;
  bool failUpload = false;

  @override
  Future<List<PatientFile>> files({
    required String patientId,
    required bool includeArchived,
    required PatientFileCategory? category,
    required int offset,
    required int limit,
  }) async => [
    PatientFile(
      id: uploaded ? 'uploaded-file' : 'file-1',
      clinicId: 'clinic-1',
      patientId: patientId,
      category: PatientFileCategory.xRay,
      originalFilename: 'demo.jpg',
      mimeType: 'image/jpeg',
      sizeBytes: 1200,
      status: PatientFileStatus.available,
      uploadedBy: 'user-1',
      availableAt: DateTime.utc(2026, 9, 10),
      createdAt: DateTime.utc(2026, 9, 10),
    ),
  ];

  @override
  Future<String> upload({
    required PatientFileDraft draft,
    required SelectedPatientFile file,
    required void Function(int sentBytes, int totalBytes) onProgress,
  }) async {
    if (failUpload) {
      throw const PatientFileOperationException(
        PatientFileOperationIssue.signatureMismatch,
      );
    }
    onProgress(file.sizeBytes, file.sizeBytes);
    uploaded = true;
    return 'uploaded-file';
  }

  @override
  Future<void> archive(String fileId, String reason) async {}
  @override
  Future<void> cancelActiveUpload() async {}
  @override
  Future<PatientFileReadAccess> readAccess(
    String fileId, {
    required bool preview,
  }) async => PatientFileReadAccess(
    url: Uri.parse('https://example.test/private'),
    mimeType: 'image/jpeg',
    filename: 'demo.jpg',
    expiresIn: const Duration(seconds: 60),
  );
  @override
  Future<void> reconcilePending(String clinicId) async => reconciled = true;
  @override
  Future<void> restore(String fileId) async {}
}

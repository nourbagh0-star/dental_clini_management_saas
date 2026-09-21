import 'dart:async';

import 'package:injectable/injectable.dart';
import 'dart:math';

import '../../../core/config/app_config.dart';
import '../domain/file_transfer_client.dart';
import '../domain/patient_file_models.dart';
import '../domain/patient_file_repository.dart';
import 'patient_file_data_source.dart';

@LazySingleton(as: PatientFileRepository)
class SupabasePatientFileRepository implements PatientFileRepository {
  SupabasePatientFileRepository(this._source, this._transfer, this._config);

  final PatientFileDataSource _source;
  final FileTransferClient _transfer;
  final AppConfig _config;
  PatientFileUploadTarget? _activeTarget;

  @override
  Future<List<PatientFile>> files({
    required String patientId,
    required bool includeArchived,
    required PatientFileCategory? category,
    required int offset,
    required int limit,
  }) async => (await _source.fileRows(
    patientId: patientId,
    includeArchived: includeArchived,
    category: category?.apiValue,
    offset: offset,
    limit: limit,
  )).map(_file).toList(growable: false);

  @override
  Future<String> upload({
    required PatientFileDraft draft,
    required SelectedPatientFile file,
    required void Function(int sentBytes, int totalBytes) onProgress,
  }) async {
    final created = await _source.invokeAction({
      'action': 'create_upload',
      'patientId': draft.patientId,
      'appointmentId': draft.appointmentId,
      'clinicalSessionId': draft.clinicalSessionId,
      'replacesFileId': draft.replacesFileId,
      'category': draft.category.apiValue,
      'description': draft.description,
      'originalFilename': file.name,
      'extension': file.extension,
      'mimeType': file.mimeType,
      'sizeBytes': file.sizeBytes,
    });
    final target = PatientFileUploadTarget(
      fileId: created['fileId'] as String,
      bucket: created['bucket'] as String,
      objectPath: created['objectPath'] as String,
      expiresAt: DateTime.parse(created['expiresAt'] as String).toUtc(),
    );
    _activeTarget = target;
    try {
      await _transfer.upload(
        target: target,
        file: file,
        onProgress: onProgress,
      );
      await _source.invokeAction({
        'action': 'complete_upload',
        'fileId': target.fileId,
      });
      return target.fileId;
    } on Object {
      unawaited(
        _source
            .invokeAction({'action': 'cancel_upload', 'fileId': target.fileId})
            .catchError((_) => <String, dynamic>{}),
      );
      rethrow;
    } finally {
      if (identical(_activeTarget, target)) _activeTarget = null;
    }
  }

  @override
  Future<void> cancelActiveUpload() async {
    final target = _activeTarget;
    _transfer.cancelActiveUpload();
    if (target != null) {
      await _source.invokeAction({
        'action': 'cancel_upload',
        'fileId': target.fileId,
      });
    }
  }

  @override
  Future<PatientFileReadAccess> readAccess(
    String fileId, {
    required bool preview,
  }) async {
    final response = await _source.invokeAction({
      'action': 'create_read_url',
      'fileId': fileId,
      'accessIntent': preview ? 'preview' : 'download',
      'requestId': _requestId(),
    });
    final rawUrl = Uri.parse(response['url'] as String);
    final url = rawUrl.hasScheme
        ? rawUrl
        : _config.supabaseUrl?.resolveUri(rawUrl);
    if (url == null) {
      throw const PatientFileOperationException(
        PatientFileOperationIssue.storageUnavailable,
      );
    }
    return PatientFileReadAccess(
      url: url,
      mimeType: response['mimeType'] as String,
      filename: response['filename'] as String,
      expiresIn: Duration(seconds: response['expiresIn'] as int),
    );
  }

  String _requestId() {
    final random = Random.secure();
    final bytes = List<int>.generate(16, (_) => random.nextInt(256));
    bytes[6] = (bytes[6] & 0x0f) | 0x40;
    bytes[8] = (bytes[8] & 0x3f) | 0x80;
    final value = bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
    return '${value.substring(0, 8)}-${value.substring(8, 12)}-'
        '${value.substring(12, 16)}-${value.substring(16, 20)}-'
        '${value.substring(20)}';
  }

  @override
  Future<void> archive(String fileId, String reason) => _source.invokeAction({
    'action': 'archive_file',
    'fileId': fileId,
    'reason': reason,
  });

  @override
  Future<void> restore(String fileId) =>
      _source.invokeAction({'action': 'restore_file', 'fileId': fileId});

  @override
  Future<void> reconcilePending(String clinicId) => _source.invokeAction({
    'action': 'reconcile_pending_uploads',
    'clinicId': clinicId,
  });

  PatientFile _file(Map<String, dynamic> row) => PatientFile(
    id: row['id'] as String,
    clinicId: row['clinic_id'] as String,
    patientId: row['patient_id'] as String,
    appointmentId: row['appointment_id'] as String?,
    clinicalSessionId: row['clinical_session_id'] as String?,
    replacesFileId: row['replaces_file_id'] as String?,
    category: PatientFileCategory.fromApi(row['category']),
    description: row['description'] as String?,
    originalFilename: row['original_filename'] as String,
    mimeType: row['detected_mime_type'] as String,
    sizeBytes: (row['size_bytes'] as num).toInt(),
    status: PatientFileStatus.fromApi(row['status']),
    uploadedBy: row['uploaded_by'] as String,
    availableAt: _date(row['available_at'])!,
    archivedAt: _date(row['archived_at']),
    archivedBy: row['archived_by'] as String?,
    archiveReason: row['archive_reason'] as String?,
    createdAt: _date(row['created_at'])!,
  );

  DateTime? _date(Object? value) =>
      value is String ? DateTime.parse(value).toUtc() : null;
}

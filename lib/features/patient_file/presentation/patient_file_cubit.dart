import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';

import '../../../core/error/app_failure.dart';
import '../domain/patient_file_models.dart';
import '../domain/patient_file_repository.dart';

enum PatientFileLoadStatus { initial, loading, ready, failure }

class PatientFileState {
  const PatientFileState({
    this.status = PatientFileLoadStatus.initial,
    this.patientId,
    this.clinicId,
    this.files = const [],
    this.selectedFileId,
    this.includeArchived = false,
    this.category,
    this.hasMore = false,
    this.loadingMore = false,
    this.uploading = false,
    this.uploadedBytes = 0,
    this.uploadTotalBytes = 0,
    this.mutating = false,
    this.failure,
    this.issue,
  });

  final PatientFileLoadStatus status;
  final String? patientId;
  final String? clinicId;
  final List<PatientFile> files;
  final String? selectedFileId;
  final bool includeArchived;
  final PatientFileCategory? category;
  final bool hasMore;
  final bool loadingMore;
  final bool uploading;
  final int uploadedBytes;
  final int uploadTotalBytes;
  final bool mutating;
  final AppFailure? failure;
  final PatientFileOperationIssue? issue;

  PatientFile? get selectedFile {
    for (final file in files) {
      if (file.id == selectedFileId) return file;
    }
    return null;
  }

  double get uploadProgress => uploadTotalBytes == 0
      ? 0
      : (uploadedBytes / uploadTotalBytes).clamp(0, 1);

  PatientFileState copyWith({
    PatientFileLoadStatus? status,
    String? patientId,
    String? clinicId,
    List<PatientFile>? files,
    String? selectedFileId,
    bool clearSelectedFileId = false,
    bool? includeArchived,
    PatientFileCategory? category,
    bool clearCategory = false,
    bool? hasMore,
    bool? loadingMore,
    bool? uploading,
    int? uploadedBytes,
    int? uploadTotalBytes,
    bool? mutating,
    AppFailure? failure,
    bool clearFailure = false,
    PatientFileOperationIssue? issue,
    bool clearIssue = false,
  }) => PatientFileState(
    status: status ?? this.status,
    patientId: patientId ?? this.patientId,
    clinicId: clinicId ?? this.clinicId,
    files: files ?? this.files,
    selectedFileId: clearSelectedFileId
        ? null
        : selectedFileId ?? this.selectedFileId,
    includeArchived: includeArchived ?? this.includeArchived,
    category: clearCategory ? null : category ?? this.category,
    hasMore: hasMore ?? this.hasMore,
    loadingMore: loadingMore ?? this.loadingMore,
    uploading: uploading ?? this.uploading,
    uploadedBytes: uploadedBytes ?? this.uploadedBytes,
    uploadTotalBytes: uploadTotalBytes ?? this.uploadTotalBytes,
    mutating: mutating ?? this.mutating,
    failure: clearFailure ? null : failure ?? this.failure,
    issue: clearIssue ? null : issue ?? this.issue,
  );
}

@lazySingleton
class PatientFileCubit extends Cubit<PatientFileState> {
  PatientFileCubit(this._repository) : super(const PatientFileState());

  static const _pageSize = 20;
  final PatientFileRepository _repository;
  int _request = 0;

  Future<void> load(
    String patientId,
    String clinicId, {
    String? preferredFileId,
  }) async {
    final request = ++_request;
    emit(
      state.copyWith(
        status: PatientFileLoadStatus.loading,
        patientId: patientId,
        clinicId: clinicId,
        files: const [],
        clearSelectedFileId: true,
        hasMore: false,
        clearFailure: true,
        clearIssue: true,
      ),
    );
    try {
      await _repository.reconcilePending(clinicId);
      final files = await _repository.files(
        patientId: patientId,
        includeArchived: state.includeArchived,
        category: state.category,
        offset: 0,
        limit: _pageSize,
      );
      if (!isClosed && request == _request) {
        emit(
          state.copyWith(
            status: PatientFileLoadStatus.ready,
            files: files,
            selectedFileId: _selection(files, preferredFileId),
            clearSelectedFileId: files.isEmpty,
            hasMore: files.length == _pageSize,
          ),
        );
      }
    } on PatientFileOperationException catch (error) {
      _issue(request, error.issue);
    } on AppFailure catch (error) {
      _failure(request, error);
    } on Object {
      _failure(request, const UnknownFailure());
    }
  }

  Future<void> setFilters({
    required bool includeArchived,
    PatientFileCategory? category,
    bool clearCategory = false,
  }) async {
    final patientId = state.patientId;
    final clinicId = state.clinicId;
    if (patientId == null || clinicId == null || state.uploading) return;
    emit(
      state.copyWith(
        includeArchived: includeArchived,
        category: category,
        clearCategory: clearCategory,
      ),
    );
    await load(patientId, clinicId);
  }

  void select(String fileId) => emit(state.copyWith(selectedFileId: fileId));

  Future<void> loadMore() async {
    final patientId = state.patientId;
    if (patientId == null || !state.hasMore || state.loadingMore) return;
    final request = ++_request;
    emit(state.copyWith(loadingMore: true, clearFailure: true));
    try {
      final more = await _repository.files(
        patientId: patientId,
        includeArchived: state.includeArchived,
        category: state.category,
        offset: state.files.length,
        limit: _pageSize,
      );
      if (!isClosed && request == _request) {
        emit(
          state.copyWith(
            files: [...state.files, ...more],
            loadingMore: false,
            hasMore: more.length == _pageSize,
          ),
        );
      }
    } on AppFailure catch (error) {
      _failure(request, error, loadingMore: false);
    } on Object {
      _failure(request, const UnknownFailure(), loadingMore: false);
    }
  }

  Future<bool> upload(PatientFileDraft draft, SelectedPatientFile file) async {
    final clinicId = state.clinicId;
    if (clinicId == null || state.uploading || state.mutating) return false;
    final request = ++_request;
    emit(
      state.copyWith(
        uploading: true,
        uploadedBytes: 0,
        uploadTotalBytes: file.sizeBytes,
        clearFailure: true,
        clearIssue: true,
      ),
    );
    try {
      final id = await _repository.upload(
        draft: draft,
        file: file,
        onProgress: (sent, total) {
          if (!isClosed && request == _request) {
            emit(state.copyWith(uploadedBytes: sent, uploadTotalBytes: total));
          }
        },
      );
      if (isClosed || request != _request) return false;
      emit(state.copyWith(uploading: false));
      await load(draft.patientId, clinicId, preferredFileId: id);
      return state.status == PatientFileLoadStatus.ready;
    } on PatientFileOperationException catch (error) {
      _issue(request, error.issue, uploading: false);
    } on AppFailure catch (error) {
      _failure(request, error, uploading: false);
    } on Object {
      _failure(request, const UnknownFailure(), uploading: false);
    }
    return false;
  }

  Future<void> cancelUpload() async {
    if (!state.uploading) return;
    final request = ++_request;
    emit(state.copyWith(uploading: false));
    try {
      await _repository.cancelActiveUpload();
    } on Object {
      if (!isClosed && request == _request) {
        emit(state.copyWith(uploading: false));
      }
    }
  }

  Future<PatientFileReadAccess?> readAccess(
    String fileId, {
    required bool preview,
  }) async {
    final request = ++_request;
    emit(state.copyWith(mutating: true, clearFailure: true, clearIssue: true));
    try {
      final access = await _repository.readAccess(fileId, preview: preview);
      if (!isClosed && request == _request) {
        emit(state.copyWith(mutating: false));
        return access;
      }
    } on PatientFileOperationException catch (error) {
      _issue(request, error.issue, mutating: false);
    } on AppFailure catch (error) {
      _failure(request, error, mutating: false);
    } on Object {
      _failure(request, const UnknownFailure(), mutating: false);
    }
    return null;
  }

  Future<bool> archive(String fileId, String reason) =>
      _mutate(fileId, () => _repository.archive(fileId, reason));

  Future<bool> restore(String fileId) =>
      _mutate(fileId, () => _repository.restore(fileId));

  Future<bool> _mutate(String fileId, Future<void> Function() action) async {
    final patientId = state.patientId;
    final clinicId = state.clinicId;
    if (patientId == null || clinicId == null || state.mutating) return false;
    final request = ++_request;
    emit(state.copyWith(mutating: true, clearFailure: true, clearIssue: true));
    try {
      await action();
      if (isClosed || request != _request) return false;
      emit(state.copyWith(mutating: false));
      await load(patientId, clinicId, preferredFileId: fileId);
      return state.status == PatientFileLoadStatus.ready;
    } on PatientFileOperationException catch (error) {
      _issue(request, error.issue, mutating: false);
    } on AppFailure catch (error) {
      _failure(request, error, mutating: false);
    } on Object {
      _failure(request, const UnknownFailure(), mutating: false);
    }
    return false;
  }

  String? _selection(List<PatientFile> files, String? preferred) {
    if (preferred != null && files.any((item) => item.id == preferred)) {
      return preferred;
    }
    return files.firstOrNull?.id;
  }

  void _issue(
    int request,
    PatientFileOperationIssue issue, {
    bool? uploading,
    bool? mutating,
  }) {
    if (!isClosed && request == _request) {
      emit(
        state.copyWith(
          status: PatientFileLoadStatus.failure,
          issue: issue,
          uploading: uploading ?? state.uploading,
          mutating: mutating ?? state.mutating,
          clearFailure: true,
        ),
      );
    }
  }

  void _failure(
    int request,
    AppFailure failure, {
    bool? uploading,
    bool? mutating,
    bool? loadingMore,
  }) {
    if (!isClosed && request == _request) {
      emit(
        state.copyWith(
          status: PatientFileLoadStatus.failure,
          failure: failure,
          uploading: uploading ?? state.uploading,
          mutating: mutating ?? state.mutating,
          loadingMore: loadingMore ?? state.loadingMore,
          clearIssue: true,
        ),
      );
    }
  }

  void clear() {
    _request++;
    emit(const PatientFileState());
  }
}

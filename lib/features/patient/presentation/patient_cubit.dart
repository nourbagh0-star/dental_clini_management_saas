import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';

import '../../../core/error/app_failure.dart';
import '../domain/patient_models.dart';
import '../domain/patient_repository.dart';

enum PatientStatus { initial, loading, ready, failure }

class PatientState {
  const PatientState({
    this.status = PatientStatus.initial,
    this.clinicId,
    this.query = '',
    this.patients = const [],
    this.mutating = false,
    this.failure,
    this.issue,
  });
  final PatientStatus status;
  final String? clinicId;
  final String query;
  final List<Patient> patients;
  final bool mutating;
  final AppFailure? failure;
  final PatientOperationIssue? issue;

  PatientState copyWith({
    PatientStatus? status,
    String? clinicId,
    String? query,
    List<Patient>? patients,
    bool? mutating,
    AppFailure? failure,
    PatientOperationIssue? issue,
    bool clearFailure = false,
    bool clearIssue = false,
  }) => PatientState(
    status: status ?? this.status,
    clinicId: clinicId ?? this.clinicId,
    query: query ?? this.query,
    patients: patients ?? this.patients,
    mutating: mutating ?? this.mutating,
    failure: clearFailure ? null : failure ?? this.failure,
    issue: clearIssue ? null : issue ?? this.issue,
  );
}

@lazySingleton
class PatientCubit extends Cubit<PatientState> {
  PatientCubit(this._repository) : super(const PatientState());
  final PatientRepository _repository;
  final Map<String, List<Patient>> _cache = {};
  int _request = 0;

  Future<void> load(
    String clinicId, {
    String query = '',
    bool force = false,
  }) async {
    final request = ++_request;
    final cacheKey = '$clinicId:$query';
    final cached = _cache[cacheKey];
    if (cached != null && !force) {
      emit(
        PatientState(
          status: PatientStatus.ready,
          clinicId: clinicId,
          query: query,
          patients: cached,
        ),
      );
    } else {
      emit(
        state.copyWith(
          status: PatientStatus.loading,
          clinicId: clinicId,
          query: query,
          clearFailure: true,
          clearIssue: true,
        ),
      );
    }
    try {
      final patients = await _repository.search(
        clinicId: clinicId,
        query: query,
      );
      _cache[cacheKey] = patients;
      if (!isClosed && request == _request) {
        emit(
          PatientState(
            status: PatientStatus.ready,
            clinicId: clinicId,
            query: query,
            patients: patients,
          ),
        );
      }
    } on PatientOperationException catch (error) {
      if (cached == null || force) _issue(request, error.issue);
    } on AppFailure catch (error) {
      if (cached == null || force) _failure(request, error);
    } on Object {
      if (cached == null || force) _failure(request, const UnknownFailure());
    }
  }

  Future<bool> create(PatientDraft draft) async {
    final clinicId = state.clinicId;
    if (clinicId == null || state.mutating) return false;
    final request = ++_request;
    emit(state.copyWith(mutating: true, clearFailure: true, clearIssue: true));
    try {
      await _repository.create(clinicId: clinicId, input: draft);
      if (isClosed || request != _request) return false;
      await load(clinicId, query: state.query, force: true);
      return state.status == PatientStatus.ready;
    } on PatientOperationException catch (error) {
      _issue(request, error.issue, mutating: false);
    } on AppFailure catch (error) {
      _failure(request, error, mutating: false);
    } on Object {
      _failure(request, const UnknownFailure(), mutating: false);
    }
    return false;
  }

  Future<bool> setArchived(String patientId, bool isArchived) async {
    final clinicId = state.clinicId;
    if (clinicId == null || state.mutating) return false;
    final request = ++_request;
    emit(state.copyWith(mutating: true, clearFailure: true, clearIssue: true));
    try {
      await _repository.setArchived(
        patientId: patientId,
        isArchived: isArchived,
      );
      if (isClosed || request != _request) return false;
      await load(clinicId, query: state.query, force: true);
      return state.status == PatientStatus.ready;
    } on PatientOperationException catch (error) {
      _issue(request, error.issue, mutating: false);
    } on AppFailure catch (error) {
      _failure(request, error, mutating: false);
    } on Object {
      _failure(request, const UnknownFailure(), mutating: false);
    }
    return false;
  }

  void _issue(int request, PatientOperationIssue issue, {bool? mutating}) {
    if (!isClosed && request == _request) {
      emit(
        state.copyWith(
          status: PatientStatus.failure,
          issue: issue,
          mutating: mutating ?? state.mutating,
          clearFailure: true,
        ),
      );
    }
  }

  void _failure(int request, AppFailure failure, {bool? mutating}) {
    if (!isClosed && request == _request) {
      emit(
        state.copyWith(
          status: PatientStatus.failure,
          failure: failure,
          mutating: mutating ?? state.mutating,
          clearIssue: true,
        ),
      );
    }
  }
}

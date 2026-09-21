import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';

import '../../../core/error/app_failure.dart';
import '../domain/patient_models.dart';
import '../domain/patient_repository.dart';

class PatientMedicalState {
  const PatientMedicalState({
    this.patientId,
    this.loading = false,
    this.saving = false,
    this.profile,
    this.failure,
  });
  final String? patientId;
  final bool loading;
  final bool saving;
  final PatientMedicalProfile? profile;
  final AppFailure? failure;
  PatientMedicalState copyWith({
    String? patientId,
    bool? loading,
    bool? saving,
    PatientMedicalProfile? profile,
    AppFailure? failure,
    bool clearFailure = false,
  }) => PatientMedicalState(
    patientId: patientId ?? this.patientId,
    loading: loading ?? this.loading,
    saving: saving ?? this.saving,
    profile: profile ?? this.profile,
    failure: clearFailure ? null : failure ?? this.failure,
  );
}

@lazySingleton
class PatientMedicalCubit extends Cubit<PatientMedicalState> {
  PatientMedicalCubit(this._repository) : super(const PatientMedicalState());
  final PatientRepository _repository;
  Future<void> load(String patientId) async {
    emit(state.copyWith(loading: true, clearFailure: true));
    try {
      final profile = await _repository.medicalProfile(patientId);
      emit(
        PatientMedicalState(
          patientId: patientId,
          profile: profile,
        ),
      );
    } on AppFailure catch (error) {
      emit(PatientMedicalState(patientId: patientId, failure: error));
    } on Object {
      emit(PatientMedicalState(patientId: patientId, failure: const UnknownFailure()));
    }
  }

  Future<void> save(String patientId, PatientMedicalProfile profile) async {
    emit(state.copyWith(saving: true, clearFailure: true));
    try {
      await _repository.upsertMedicalProfile(
        patientId: patientId,
        profile: profile,
      );
      emit(PatientMedicalState(patientId: patientId, profile: profile));
    } on AppFailure catch (error) {
      emit(state.copyWith(saving: false, failure: error));
    } on Object {
      emit(state.copyWith(saving: false, failure: const UnknownFailure()));
    }
  }
}

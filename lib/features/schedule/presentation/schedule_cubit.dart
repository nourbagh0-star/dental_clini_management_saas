import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';

import '../../../core/error/app_failure.dart';
import '../domain/schedule_models.dart';
import '../domain/schedule_repository.dart';

enum ScheduleStatus { initial, loading, ready, failure }

class ScheduleState {
  const ScheduleState({
    this.status = ScheduleStatus.initial,
    this.clinicId,
    this.versions = const [],
    this.exceptions = const [],
    this.dentists = const [],
    this.mutating = false,
    this.failure,
    this.issue,
  });

  final ScheduleStatus status;
  final String? clinicId;
  final List<DoctorScheduleVersion> versions;
  final List<DoctorScheduleException> exceptions;
  final List<ScheduleDentist> dentists;
  final bool mutating;
  final AppFailure? failure;
  final ScheduleOperationIssue? issue;

  ScheduleState copyWith({
    ScheduleStatus? status,
    String? clinicId,
    List<DoctorScheduleVersion>? versions,
    List<DoctorScheduleException>? exceptions,
    List<ScheduleDentist>? dentists,
    bool? mutating,
    AppFailure? failure,
    ScheduleOperationIssue? issue,
    bool clearFailure = false,
    bool clearIssue = false,
  }) => ScheduleState(
    status: status ?? this.status,
    clinicId: clinicId ?? this.clinicId,
    versions: versions ?? this.versions,
    exceptions: exceptions ?? this.exceptions,
    dentists: dentists ?? this.dentists,
    mutating: mutating ?? this.mutating,
    failure: clearFailure ? null : failure ?? this.failure,
    issue: clearIssue ? null : issue ?? this.issue,
  );
}

@lazySingleton
class ScheduleCubit extends Cubit<ScheduleState> {
  ScheduleCubit(this._repository) : super(const ScheduleState());

  final ScheduleRepository _repository;
  int _request = 0;

  Future<void> load(String clinicId) async {
    final request = ++_request;
    emit(
      state.copyWith(
        status: ScheduleStatus.loading,
        clinicId: clinicId,
        clearFailure: true,
        clearIssue: true,
      ),
    );
    try {
      final data = await Future.wait([
        _repository.getScheduleVersions(clinicId),
        _repository.getScheduleExceptions(clinicId),
        _repository.getManageableDentists(clinicId),
      ]);
      if (isClosed || request != _request) return;
      emit(
        ScheduleState(
          status: ScheduleStatus.ready,
          clinicId: clinicId,
          versions: data[0] as List<DoctorScheduleVersion>,
          exceptions: data[1] as List<DoctorScheduleException>,
          dentists: data[2] as List<ScheduleDentist>,
        ),
      );
    } on ScheduleOperationException catch (error) {
      _emitIssue(request, error.issue);
    } on AppFailure catch (error) {
      _emitFailure(request, error);
    } on Object {
      _emitFailure(request, const UnknownFailure());
    }
  }

  Future<bool> replaceWeeklySchedule({
    required String dentistMemberId,
    required String effectiveFrom,
    required List<DoctorWorkingPeriod> periods,
    bool confirmAffectedAppointments = false,
    String? appointmentImpactReason,
  }) => _mutate(
    () => _repository.replaceWeeklySchedule(
      dentistMemberId: dentistMemberId,
      effectiveFrom: effectiveFrom,
      periods: periods,
      confirmAffectedAppointments: confirmAffectedAppointments,
      appointmentImpactReason: appointmentImpactReason,
    ),
  );

  Future<ScheduleImpactPreview?> previewWeeklyImpact({
    required String dentistMemberId,
    required String effectiveFrom,
    required List<DoctorWorkingPeriod> periods,
  }) async {
    try {
      return await _repository.previewWeeklyImpact(
        dentistMemberId: dentistMemberId,
        effectiveFrom: effectiveFrom,
        periods: periods,
      );
    } on Object {
      return null;
    }
  }

  Future<bool> createException({
    required String dentistMemberId,
    required ScheduleExceptionKind kind,
    required DateTime startsAt,
    required DateTime endsAt,
    String? reason,
    bool confirmAffectedAppointments = false,
    String? appointmentImpactReason,
  }) => _mutate(
    () => _repository.createException(
      dentistMemberId: dentistMemberId,
      kind: kind,
      startsAt: startsAt,
      endsAt: endsAt,
      reason: reason,
      confirmAffectedAppointments: confirmAffectedAppointments,
      appointmentImpactReason: appointmentImpactReason,
    ),
  );

  Future<ScheduleImpactPreview?> previewExceptionImpact({
    required String dentistMemberId,
    required DateTime startsAt,
    required DateTime endsAt,
  }) async {
    try {
      return await _repository.previewExceptionImpact(
        dentistMemberId: dentistMemberId,
        startsAt: startsAt,
        endsAt: endsAt,
      );
    } on Object {
      return null;
    }
  }

  Future<bool> updateException({
    required String exceptionId,
    required ScheduleExceptionKind kind,
    required DateTime startsAt,
    required DateTime endsAt,
    String? reason,
  }) => _mutate(
    () => _repository.updateException(
      exceptionId: exceptionId,
      kind: kind,
      startsAt: startsAt,
      endsAt: endsAt,
      reason: reason,
    ),
  );

  Future<bool> deleteException(String exceptionId) =>
      _mutate(() => _repository.deleteException(exceptionId));

  Future<bool> _mutate(Future<Object?> Function() action) async {
    final clinicId = state.clinicId;
    if (clinicId == null || state.mutating) return false;
    final request = ++_request;
    emit(state.copyWith(mutating: true, clearFailure: true, clearIssue: true));
    try {
      await action();
      if (isClosed || request != _request) return false;
      await load(clinicId);
      return state.status == ScheduleStatus.ready;
    } on ScheduleOperationException catch (error) {
      _emitIssue(request, error.issue, mutating: false);
    } on AppFailure catch (error) {
      _emitFailure(request, error, mutating: false);
    } on Object {
      _emitFailure(request, const UnknownFailure(), mutating: false);
    }
    return false;
  }

  void _emitIssue(int request, ScheduleOperationIssue issue, {bool? mutating}) {
    if (!isClosed && request == _request) {
      emit(
        state.copyWith(
          status: ScheduleStatus.failure,
          mutating: mutating ?? state.mutating,
          issue: issue,
          clearFailure: true,
        ),
      );
    }
  }

  void _emitFailure(int request, AppFailure failure, {bool? mutating}) {
    if (!isClosed && request == _request) {
      emit(
        state.copyWith(
          status: ScheduleStatus.failure,
          mutating: mutating ?? state.mutating,
          failure: failure,
          clearIssue: true,
        ),
      );
    }
  }

  void clear() {
    _request++;
    emit(const ScheduleState());
  }
}

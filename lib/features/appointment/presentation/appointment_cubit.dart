import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';

import '../../../core/error/app_failure.dart';
import '../domain/appointment_models.dart';
import '../domain/appointment_repository.dart';

enum AppointmentLoadStatus { initial, loading, ready, failure }

class AppointmentState {
  const AppointmentState({
    this.status = AppointmentLoadStatus.initial,
    this.clinicId,
    this.from,
    this.until,
    this.appointments = const [],
    this.mutating = false,
    this.failure,
    this.issue,
  });
  final AppointmentLoadStatus status;
  final String? clinicId;
  final DateTime? from;
  final DateTime? until;
  final List<Appointment> appointments;
  final bool mutating;
  final AppFailure? failure;
  final AppointmentOperationIssue? issue;

  AppointmentState copyWith({
    AppointmentLoadStatus? status,
    String? clinicId,
    DateTime? from,
    DateTime? until,
    List<Appointment>? appointments,
    bool? mutating,
    AppFailure? failure,
    AppointmentOperationIssue? issue,
    bool clearFailure = false,
    bool clearIssue = false,
  }) => AppointmentState(
    status: status ?? this.status,
    clinicId: clinicId ?? this.clinicId,
    from: from ?? this.from,
    until: until ?? this.until,
    appointments: appointments ?? this.appointments,
    mutating: mutating ?? this.mutating,
    failure: clearFailure ? null : failure ?? this.failure,
    issue: clearIssue ? null : issue ?? this.issue,
  );
}

@lazySingleton
class AppointmentCubit extends Cubit<AppointmentState> {
  AppointmentCubit(this._repository) : super(const AppointmentState());
  final AppointmentRepository _repository;
  final Map<String, List<Appointment>> _rangeCache = {};
  int _request = 0;

  Future<void> load({
    required String clinicId,
    required DateTime from,
    required DateTime until,
    bool force = false,
  }) async {
    final request = ++_request;
    final cacheKey =
        '$clinicId:${from.millisecondsSinceEpoch}:${until.millisecondsSinceEpoch}';
    final cached = _rangeCache[cacheKey];
    if (cached != null && !force) {
      emit(
        state.copyWith(
          status: AppointmentLoadStatus.ready,
          clinicId: clinicId,
          from: from,
          until: until,
          appointments: cached,
        ),
      );
    } else {
      emit(
        state.copyWith(
          status: AppointmentLoadStatus.loading,
          clinicId: clinicId,
          from: from,
          until: until,
          clearFailure: true,
          clearIssue: true,
        ),
      );
    }
    try {
      final appointments = await _repository.listRange(
        clinicId: clinicId,
        from: from,
        until: until,
      );
      _rangeCache[cacheKey] = appointments;
      if (!isClosed && request == _request) {
        emit(
          AppointmentState(
            status: AppointmentLoadStatus.ready,
            clinicId: clinicId,
            from: from,
            until: until,
            appointments: appointments,
          ),
        );
      }
    } on AppointmentOperationException catch (error) {
      if (cached == null || force) _issue(request, error.issue);
    } on AppFailure catch (error) {
      if (cached == null || force) _failure(request, error);
    } on Object {
      if (cached == null || force) _failure(request, const UnknownFailure());
    }
  }

  Future<bool> create(AppointmentDraft draft) =>
      _mutate(() => _repository.create(draft));

  Future<bool> reschedule({
    required String appointmentId,
    required DateTime startsAt,
    required DateTime endsAt,
    String? overrideReason,
  }) => _mutate(
    () => _repository.reschedule(
      appointmentId: appointmentId,
      startsAt: startsAt,
      endsAt: endsAt,
      overrideReason: overrideReason,
    ),
  );

  Future<bool> transition({
    required String appointmentId,
    required AppointmentStatus status,
    String? cancellationReason,
  }) => _mutate(
    () => _repository.transition(
      appointmentId: appointmentId,
      status: status,
      cancellationReason: cancellationReason,
    ),
  );

  Future<bool> savePreparationNote({
    required String appointmentId,
    required String note,
  }) => _mutate(
    () => _repository.savePreparationNote(
      appointmentId: appointmentId,
      note: note,
    ),
  );

  Future<bool> _mutate(Future<void> Function() action) async {
    final clinicId = state.clinicId;
    final from = state.from;
    final until = state.until;
    if (clinicId == null || from == null || until == null || state.mutating) {
      return false;
    }
    final request = ++_request;
    emit(state.copyWith(mutating: true, clearFailure: true, clearIssue: true));
    try {
      await action();
      if (isClosed || request != _request) return false;
      await load(clinicId: clinicId, from: from, until: until, force: true);
      return state.status == AppointmentLoadStatus.ready;
    } on AppointmentOperationException catch (error) {
      _issue(request, error.issue, mutating: false);
    } on AppFailure catch (error) {
      _failure(request, error, mutating: false);
    } on Object {
      _failure(request, const UnknownFailure(), mutating: false);
    }
    return false;
  }

  void _issue(int request, AppointmentOperationIssue issue, {bool? mutating}) {
    if (!isClosed && request == _request) {
      emit(
        state.copyWith(
          status: AppointmentLoadStatus.failure,
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
          status: AppointmentLoadStatus.failure,
          failure: failure,
          mutating: mutating ?? state.mutating,
          clearIssue: true,
        ),
      );
    }
  }
}

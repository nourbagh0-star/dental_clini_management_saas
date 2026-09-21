import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';

import '../../../core/error/app_failure.dart';
import '../domain/odontogram_models.dart';
import '../domain/odontogram_repository.dart';

enum OdontogramLoadStatus { initial, loading, ready, failure }

class OdontogramState {
  const OdontogramState({
    this.status = OdontogramLoadStatus.initial,
    this.patientId,
    this.active = const [],
    this.history = const [],
    this.historyHasMore = false,
    this.loadingMore = false,
    this.mutating = false,
    this.failure,
    this.issue,
  });

  final OdontogramLoadStatus status;
  final String? patientId;
  final List<ToothCondition> active;
  final List<ToothCondition> history;
  final bool historyHasMore;
  final bool loadingMore;
  final bool mutating;
  final AppFailure? failure;
  final OdontogramOperationIssue? issue;

  OdontogramState copyWith({
    OdontogramLoadStatus? status,
    String? patientId,
    List<ToothCondition>? active,
    List<ToothCondition>? history,
    bool? historyHasMore,
    bool? loadingMore,
    bool? mutating,
    AppFailure? failure,
    OdontogramOperationIssue? issue,
    bool clearFailure = false,
    bool clearIssue = false,
  }) => OdontogramState(
    status: status ?? this.status,
    patientId: patientId ?? this.patientId,
    active: active ?? this.active,
    history: history ?? this.history,
    historyHasMore: historyHasMore ?? this.historyHasMore,
    loadingMore: loadingMore ?? this.loadingMore,
    mutating: mutating ?? this.mutating,
    failure: clearFailure ? null : failure ?? this.failure,
    issue: clearIssue ? null : issue ?? this.issue,
  );
}

@lazySingleton
class OdontogramCubit extends Cubit<OdontogramState> {
  OdontogramCubit(this._repository) : super(const OdontogramState());
  final OdontogramRepository _repository;
  static const _pageSize = 25;
  int _request = 0;

  Future<void> load(String patientId) async {
    final request = ++_request;
    emit(
      state.copyWith(
        status: OdontogramLoadStatus.loading,
        patientId: patientId,
        clearFailure: true,
        clearIssue: true,
      ),
    );
    try {
      final active = await _repository.activeConditions(patientId);
      final history = await _repository.history(
        patientId: patientId,
        offset: 0,
        limit: _pageSize,
      );
      if (!isClosed && request == _request) {
        emit(
          OdontogramState(
            status: OdontogramLoadStatus.ready,
            patientId: patientId,
            active: active,
            history: history,
            historyHasMore: history.length == _pageSize,
          ),
        );
      }
    } on OdontogramOperationException catch (error) {
      _issue(request, error.issue);
    } on AppFailure catch (error) {
      _failure(request, error);
    } on Object {
      _failure(request, const UnknownFailure());
    }
  }

  Future<void> loadMoreHistory() async {
    final patientId = state.patientId;
    if (patientId == null || !state.historyHasMore || state.loadingMore) return;
    final request = ++_request;
    emit(state.copyWith(loadingMore: true, clearFailure: true));
    try {
      final more = await _repository.history(
        patientId: patientId,
        offset: state.history.length,
        limit: _pageSize,
      );
      if (!isClosed && request == _request) {
        emit(
          state.copyWith(
            history: [...state.history, ...more],
            historyHasMore: more.length == _pageSize,
            loadingMore: false,
          ),
        );
      }
    } on AppFailure catch (error) {
      _failure(request, error, loadingMore: false);
    } on Object {
      _failure(request, const UnknownFailure(), loadingMore: false);
    }
  }

  Future<bool> create({
    required String patientId,
    required ToothConditionDraft draft,
  }) => _mutate(
    patientId,
    () => _repository.createCondition(patientId: patientId, draft: draft),
  );

  Future<bool> resolve({
    required String patientId,
    required String conditionId,
  }) => _mutate(patientId, () => _repository.resolveCondition(conditionId));

  Future<bool> markInError({
    required String patientId,
    required String conditionId,
    required String reason,
  }) => _mutate(
    patientId,
    () => _repository.markConditionInError(
      conditionId: conditionId,
      reason: reason,
    ),
  );

  Future<bool> _mutate(String patientId, Future<void> Function() action) async {
    if (state.mutating) return false;
    final request = ++_request;
    emit(state.copyWith(mutating: true, clearFailure: true, clearIssue: true));
    try {
      await action();
      if (isClosed || request != _request) return false;
      await load(patientId);
      return state.status == OdontogramLoadStatus.ready;
    } on OdontogramOperationException catch (error) {
      _issue(request, error.issue, mutating: false);
    } on AppFailure catch (error) {
      _failure(request, error, mutating: false);
    } on Object {
      _failure(request, const UnknownFailure(), mutating: false);
    }
    return false;
  }

  void _issue(int request, OdontogramOperationIssue issue, {bool? mutating}) {
    if (!isClosed && request == _request) {
      emit(
        state.copyWith(
          status: OdontogramLoadStatus.failure,
          issue: issue,
          mutating: mutating ?? state.mutating,
          clearFailure: true,
        ),
      );
    }
  }

  void _failure(
    int request,
    AppFailure failure, {
    bool? mutating,
    bool? loadingMore,
  }) {
    if (!isClosed && request == _request) {
      emit(
        state.copyWith(
          status: OdontogramLoadStatus.failure,
          failure: failure,
          mutating: mutating ?? state.mutating,
          loadingMore: loadingMore ?? state.loadingMore,
          clearIssue: true,
        ),
      );
    }
  }
}

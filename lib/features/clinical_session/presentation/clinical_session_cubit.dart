import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';

import '../../../core/error/app_failure.dart';
import '../domain/clinical_session_models.dart';
import '../domain/clinical_session_repository.dart';

enum ClinicalSessionLoadStatus { initial, loading, ready, failure }

class ClinicalSessionState {
  const ClinicalSessionState({
    this.status = ClinicalSessionLoadStatus.initial,
    this.patientId,
    this.sessions = const [],
    this.selectedSessionId,
    this.amendments = const [],
    this.eligibleAppointments = const [],
    this.hasMore = false,
    this.loadingMore = false,
    this.mutating = false,
    this.failure,
    this.issue,
  });

  final ClinicalSessionLoadStatus status;
  final String? patientId;
  final List<ClinicalSession> sessions;
  final String? selectedSessionId;
  final List<ClinicalSessionAmendment> amendments;
  final List<EligibleSessionAppointment> eligibleAppointments;
  final bool hasMore;
  final bool loadingMore;
  final bool mutating;
  final AppFailure? failure;
  final ClinicalSessionOperationIssue? issue;

  ClinicalSession? get selectedSession {
    for (final session in sessions) {
      if (session.id == selectedSessionId) return session;
    }
    return null;
  }

  ClinicalSessionState copyWith({
    ClinicalSessionLoadStatus? status,
    String? patientId,
    List<ClinicalSession>? sessions,
    String? selectedSessionId,
    bool clearSelectedSessionId = false,
    List<ClinicalSessionAmendment>? amendments,
    List<EligibleSessionAppointment>? eligibleAppointments,
    bool? hasMore,
    bool? loadingMore,
    bool? mutating,
    AppFailure? failure,
    bool clearFailure = false,
    ClinicalSessionOperationIssue? issue,
    bool clearIssue = false,
  }) => ClinicalSessionState(
    status: status ?? this.status,
    patientId: patientId ?? this.patientId,
    sessions: sessions ?? this.sessions,
    selectedSessionId: clearSelectedSessionId
        ? null
        : selectedSessionId ?? this.selectedSessionId,
    amendments: amendments ?? this.amendments,
    eligibleAppointments: eligibleAppointments ?? this.eligibleAppointments,
    hasMore: hasMore ?? this.hasMore,
    loadingMore: loadingMore ?? this.loadingMore,
    mutating: mutating ?? this.mutating,
    failure: clearFailure ? null : failure ?? this.failure,
    issue: clearIssue ? null : issue ?? this.issue,
  );
}

@lazySingleton
class ClinicalSessionCubit extends Cubit<ClinicalSessionState> {
  ClinicalSessionCubit(this._repository) : super(const ClinicalSessionState());

  final ClinicalSessionRepository _repository;
  static const _pageSize = 20;
  int _request = 0;

  Future<void> load(String patientId, {String? preferredSessionId}) async {
    final request = ++_request;
    emit(
      ClinicalSessionState(
        status: ClinicalSessionLoadStatus.loading,
        patientId: patientId,
      ),
    );
    try {
      final result = await Future.wait<Object>([
        _repository.sessions(patientId: patientId, offset: 0, limit: _pageSize),
        _repository.eligibleAppointments(patientId),
      ]);
      if (isClosed || request != _request) return;
      final sessions = result[0] as List<ClinicalSession>;
      final selectedId = _selection(sessions, preferredSessionId);
      final amendments = selectedId == null
          ? const <ClinicalSessionAmendment>[]
          : await _repository.amendments(selectedId);
      if (!isClosed && request == _request) {
        emit(
          ClinicalSessionState(
            status: ClinicalSessionLoadStatus.ready,
            patientId: patientId,
            sessions: sessions,
            selectedSessionId: selectedId,
            amendments: amendments,
            eligibleAppointments: result[1] as List<EligibleSessionAppointment>,
            hasMore: sessions.length == _pageSize,
          ),
        );
      }
    } on ClinicalSessionOperationException catch (error) {
      _issue(request, error.issue);
    } on AppFailure catch (error) {
      _failure(request, error);
    } on Object {
      _failure(request, const UnknownFailure());
    }
  }

  Future<void> select(String sessionId) async {
    if (state.selectedSessionId == sessionId || state.mutating) return;
    final request = ++_request;
    emit(
      state.copyWith(
        status: ClinicalSessionLoadStatus.loading,
        selectedSessionId: sessionId,
        amendments: const [],
        clearFailure: true,
        clearIssue: true,
      ),
    );
    try {
      final amendments = await _repository.amendments(sessionId);
      if (!isClosed && request == _request) {
        emit(
          state.copyWith(
            status: ClinicalSessionLoadStatus.ready,
            selectedSessionId: sessionId,
            amendments: amendments,
          ),
        );
      }
    } on AppFailure catch (error) {
      _failure(request, error);
    } on Object {
      _failure(request, const UnknownFailure());
    }
  }

  Future<void> loadMore() async {
    final patientId = state.patientId;
    if (patientId == null || !state.hasMore || state.loadingMore) return;
    final request = ++_request;
    emit(state.copyWith(loadingMore: true, clearFailure: true));
    try {
      final more = await _repository.sessions(
        patientId: patientId,
        offset: state.sessions.length,
        limit: _pageSize,
      );
      if (!isClosed && request == _request) {
        emit(
          state.copyWith(
            sessions: [...state.sessions, ...more],
            hasMore: more.length == _pageSize,
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

  Future<bool> create(ClinicalSessionDraft draft) async {
    if (state.mutating) return false;
    final request = ++_request;
    emit(state.copyWith(mutating: true, clearFailure: true, clearIssue: true));
    try {
      final id = await _repository.createSession(draft);
      if (isClosed || request != _request) return false;
      await load(draft.patientId, preferredSessionId: id);
      return state.status == ClinicalSessionLoadStatus.ready;
    } on ClinicalSessionOperationException catch (error) {
      _issue(request, error.issue, mutating: false);
    } on AppFailure catch (error) {
      _failure(request, error, mutating: false);
    } on Object {
      _failure(request, const UnknownFailure(), mutating: false);
    }
    return false;
  }

  Future<bool> saveDraft({
    required String sessionId,
    required String? clinicalNotes,
    required String? recommendations,
    required int expectedRevision,
  }) => _mutate(
    sessionId,
    () => _repository.updateDraft(
      sessionId: sessionId,
      clinicalNotes: clinicalNotes,
      recommendations: recommendations,
      expectedRevision: expectedRevision,
    ),
  );

  Future<bool> finalize(String sessionId, int expectedRevision) => _mutate(
    sessionId,
    () => _repository.finalizeSession(sessionId, expectedRevision),
  );

  Future<bool> markInError({
    required String sessionId,
    required int expectedRevision,
    required String reason,
  }) => _mutate(
    sessionId,
    () => _repository.markInError(
      sessionId: sessionId,
      expectedRevision: expectedRevision,
      reason: reason,
    ),
  );

  Future<bool> addAmendment({
    required String sessionId,
    required String amendmentText,
    required String reason,
  }) => _mutate(
    sessionId,
    () => _repository.addAmendment(
      sessionId: sessionId,
      amendmentText: amendmentText,
      reason: reason,
    ),
  );

  Future<bool> _mutate(
    String selectedId,
    Future<void> Function() action,
  ) async {
    final patientId = state.patientId;
    if (patientId == null || state.mutating) return false;
    final request = ++_request;
    emit(state.copyWith(mutating: true, clearFailure: true, clearIssue: true));
    try {
      await action();
      if (isClosed || request != _request) return false;
      await load(patientId, preferredSessionId: selectedId);
      return state.status == ClinicalSessionLoadStatus.ready;
    } on ClinicalSessionOperationException catch (error) {
      _issue(request, error.issue, mutating: false);
    } on AppFailure catch (error) {
      _failure(request, error, mutating: false);
    } on Object {
      _failure(request, const UnknownFailure(), mutating: false);
    }
    return false;
  }

  String? _selection(List<ClinicalSession> sessions, String? preferred) {
    if (preferred != null && sessions.any((item) => item.id == preferred)) {
      return preferred;
    }
    return sessions.firstOrNull?.id;
  }

  void _issue(
    int request,
    ClinicalSessionOperationIssue issue, {
    bool? mutating,
  }) {
    if (!isClosed && request == _request) {
      emit(
        state.copyWith(
          status: ClinicalSessionLoadStatus.failure,
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
          status: ClinicalSessionLoadStatus.failure,
          failure: failure,
          mutating: mutating ?? state.mutating,
          loadingMore: loadingMore ?? state.loadingMore,
          clearIssue: true,
        ),
      );
    }
  }

  void clear() {
    _request++;
    emit(const ClinicalSessionState());
  }
}

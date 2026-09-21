import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';

import '../../../core/auth/session_coordinator.dart';
import '../../../core/error/app_failure.dart';
import '../../auth/domain/auth_models.dart';
import '../domain/dashboard_models.dart';
import '../domain/dashboard_repository.dart';

enum DashboardLoadStatus { initial, loading, ready, failure }

class DashboardState {
  const DashboardState({
    this.status = DashboardLoadStatus.initial,
    this.clinicId,
    this.snapshot,
    this.refreshing = false,
    this.failure,
    this.refreshFailure,
  });

  final DashboardLoadStatus status;
  final String? clinicId;
  final DashboardSnapshot? snapshot;
  final bool refreshing;
  final AppFailure? failure;
  final AppFailure? refreshFailure;
}

@lazySingleton
class DashboardCubit extends Cubit<DashboardState> {
  DashboardCubit(this._repository, this._session)
    : super(const DashboardState()) {
    _sessionSubscription = _session.changes.listen((value) {
      if (value.stage != AuthStage.signedIn) clear();
    });
  }

  final DashboardRepository _repository;
  final SessionCoordinator _session;
  late final StreamSubscription<AuthViewState> _sessionSubscription;
  int _request = 0;

  Future<void> load(String clinicId) async {
    if (state.status == DashboardLoadStatus.loading &&
        state.clinicId == clinicId) {
      return;
    }
    final request = ++_request;
    emit(
      DashboardState(status: DashboardLoadStatus.loading, clinicId: clinicId),
    );
    try {
      final snapshot = await _repository.load(clinicId);
      if (!isClosed && request == _request && snapshot.clinicId == clinicId) {
        emit(
          DashboardState(
            status: DashboardLoadStatus.ready,
            clinicId: clinicId,
            snapshot: snapshot,
          ),
        );
      }
    } on AppFailure catch (failure) {
      if (!isClosed && request == _request) {
        emit(
          DashboardState(
            status: DashboardLoadStatus.failure,
            clinicId: clinicId,
            failure: failure,
          ),
        );
      }
    } on Object {
      if (!isClosed && request == _request) {
        emit(
          DashboardState(
            status: DashboardLoadStatus.failure,
            clinicId: clinicId,
            failure: const UnknownFailure(),
          ),
        );
      }
    }
  }

  Future<void> refresh() async {
    final clinicId = state.clinicId;
    final current = state.snapshot;
    if (clinicId == null || current == null || state.refreshing) return;
    final request = ++_request;
    emit(
      DashboardState(
        status: DashboardLoadStatus.ready,
        clinicId: clinicId,
        snapshot: current,
        refreshing: true,
      ),
    );
    try {
      final snapshot = await _repository.load(clinicId);
      if (!isClosed && request == _request && snapshot.clinicId == clinicId) {
        emit(
          DashboardState(
            status: DashboardLoadStatus.ready,
            clinicId: clinicId,
            snapshot: snapshot,
          ),
        );
      }
    } on AppFailure catch (failure) {
      if (!isClosed && request == _request) {
        emit(
          DashboardState(
            status: DashboardLoadStatus.ready,
            clinicId: clinicId,
            snapshot: current,
            refreshFailure: failure,
          ),
        );
      }
    } on Object {
      if (!isClosed && request == _request) {
        emit(
          DashboardState(
            status: DashboardLoadStatus.ready,
            clinicId: clinicId,
            snapshot: current,
            refreshFailure: const UnknownFailure(),
          ),
        );
      }
    }
  }

  void clear() {
    _request++;
    if (!isClosed) emit(const DashboardState());
  }

  @disposeMethod
  @override
  Future<void> close() async {
    _request++;
    await _sessionSubscription.cancel();
    return super.close();
  }
}

import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';

import '../../../core/auth/session_coordinator.dart';
import '../../../core/error/app_failure.dart';
import '../../auth/domain/auth_models.dart';
import '../domain/audit_models.dart';
import '../domain/audit_repository.dart';

enum AuditLoadStatus { initial, loading, ready, failure }

class AuditState {
  const AuditState({
    this.status = AuditLoadStatus.initial,
    this.clinicId,
    this.filter,
    this.page,
    this.refreshing = false,
    this.loadingMore = false,
    this.failure,
    this.secondaryFailure,
  });

  final AuditLoadStatus status;
  final String? clinicId;
  final AuditFilter? filter;
  final AuditPage? page;
  final bool refreshing;
  final bool loadingMore;
  final AppFailure? failure;
  final AppFailure? secondaryFailure;
}

@lazySingleton
class AuditCubit extends Cubit<AuditState> {
  AuditCubit(this._repository, this._session) : super(const AuditState()) {
    _subscription = _session.changes.listen((value) {
      if (value.stage != AuthStage.signedIn) clear();
    });
  }

  final AuditRepository _repository;
  final SessionCoordinator _session;
  late final StreamSubscription<AuthViewState> _subscription;
  int _request = 0;

  Future<void> load(String clinicId, AuditFilter filter) async {
    if (state.status == AuditLoadStatus.loading &&
        state.clinicId == clinicId &&
        identical(state.filter, filter)) {
      return;
    }
    final request = ++_request;
    emit(
      AuditState(
        status: AuditLoadStatus.loading,
        clinicId: clinicId,
        filter: filter,
      ),
    );
    try {
      await _repository.recordAccess(
        clinicId: clinicId,
        intent: AuditAccessIntent.auditLog,
        subjectId: clinicId,
      );
      final page = await _repository.page(clinicId: clinicId, filter: filter);
      if (!isClosed && request == _request && page.clinicId == clinicId) {
        emit(
          AuditState(
            status: AuditLoadStatus.ready,
            clinicId: clinicId,
            filter: filter,
            page: page,
          ),
        );
      }
    } on AppFailure catch (failure) {
      _initialFailure(request, clinicId, filter, failure);
    } on Object {
      _initialFailure(request, clinicId, filter, const UnknownFailure());
    }
  }

  Future<void> applyFilter(AuditFilter filter) async {
    final clinicId = state.clinicId;
    if (clinicId == null) return;
    final request = ++_request;
    emit(
      AuditState(
        status: AuditLoadStatus.loading,
        clinicId: clinicId,
        filter: filter,
      ),
    );
    try {
      final page = await _repository.page(clinicId: clinicId, filter: filter);
      if (!isClosed && request == _request && page.clinicId == clinicId) {
        emit(
          AuditState(
            status: AuditLoadStatus.ready,
            clinicId: clinicId,
            filter: filter,
            page: page,
          ),
        );
      }
    } on AppFailure catch (failure) {
      _initialFailure(request, clinicId, filter, failure);
    } on Object {
      _initialFailure(request, clinicId, filter, const UnknownFailure());
    }
  }

  Future<void> refresh() async {
    final clinicId = state.clinicId;
    final filter = state.filter;
    final current = state.page;
    if (clinicId == null ||
        filter == null ||
        current == null ||
        state.refreshing) {
      return;
    }
    final request = ++_request;
    emit(
      AuditState(
        status: AuditLoadStatus.ready,
        clinicId: clinicId,
        filter: filter,
        page: current,
        refreshing: true,
      ),
    );
    try {
      final page = await _repository.page(clinicId: clinicId, filter: filter);
      if (!isClosed && request == _request && page.clinicId == clinicId) {
        emit(
          AuditState(
            status: AuditLoadStatus.ready,
            clinicId: clinicId,
            filter: filter,
            page: page,
          ),
        );
      }
    } on AppFailure catch (failure) {
      _secondaryFailure(request, clinicId, filter, current, failure);
    } on Object {
      _secondaryFailure(
        request,
        clinicId,
        filter,
        current,
        const UnknownFailure(),
      );
    }
  }

  Future<void> loadMore() async {
    final clinicId = state.clinicId;
    final filter = state.filter;
    final current = state.page;
    if (clinicId == null ||
        filter == null ||
        current == null ||
        !current.hasMore ||
        current.nextCursor == null ||
        state.loadingMore) {
      return;
    }
    final request = ++_request;
    emit(
      AuditState(
        status: AuditLoadStatus.ready,
        clinicId: clinicId,
        filter: filter,
        page: current,
        loadingMore: true,
      ),
    );
    try {
      final next = await _repository.page(
        clinicId: clinicId,
        filter: filter,
        cursor: current.nextCursor,
      );
      if (!isClosed && request == _request && next.clinicId == clinicId) {
        emit(
          AuditState(
            status: AuditLoadStatus.ready,
            clinicId: clinicId,
            filter: filter,
            page: AuditPage(
              clinicId: next.clinicId,
              clinicTimeZone: next.clinicTimeZone,
              fromDate: next.fromDate,
              toDateExclusive: next.toDateExclusive,
              items: [...current.items, ...next.items],
              actors: next.actors,
              hasMore: next.hasMore,
              nextCursor: next.nextCursor,
            ),
          ),
        );
      }
    } on AppFailure catch (failure) {
      _secondaryFailure(request, clinicId, filter, current, failure);
    } on Object {
      _secondaryFailure(
        request,
        clinicId,
        filter,
        current,
        const UnknownFailure(),
      );
    }
  }

  void _initialFailure(
    int request,
    String clinicId,
    AuditFilter filter,
    AppFailure failure,
  ) {
    if (!isClosed && request == _request) {
      emit(
        AuditState(
          status: AuditLoadStatus.failure,
          clinicId: clinicId,
          filter: filter,
          failure: failure,
        ),
      );
    }
  }

  void _secondaryFailure(
    int request,
    String clinicId,
    AuditFilter filter,
    AuditPage page,
    AppFailure failure,
  ) {
    if (!isClosed && request == _request) {
      emit(
        AuditState(
          status: AuditLoadStatus.ready,
          clinicId: clinicId,
          filter: filter,
          page: page,
          secondaryFailure: failure,
        ),
      );
    }
  }

  void clear() {
    _request++;
    if (!isClosed) emit(const AuditState());
  }

  @disposeMethod
  @override
  Future<void> close() async {
    _request++;
    await _subscription.cancel();
    return super.close();
  }
}

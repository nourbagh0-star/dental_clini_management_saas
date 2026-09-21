import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';

import '../../../core/auth/session_coordinator.dart';
import '../../../core/error/app_failure.dart';
import '../../../core/storage/active_clinic_store.dart';
import '../../auth/domain/auth_models.dart';
import '../domain/clinic_models.dart';
import '../domain/clinic_repository.dart';

@lazySingleton
class ClinicCubit extends Cubit<ClinicState> {
  ClinicCubit(this._repository, this._store, this._session)
    : super(const ClinicState()) {
    _subscription = _session.changes.listen(_onSessionChanged);
    _onSessionChanged(_session.state);
  }

  final ClinicRepository _repository;
  final ActiveClinicStore _store;
  final SessionCoordinator _session;
  late final StreamSubscription<AuthViewState> _subscription;
  String? _currentUserId;
  int _request = 0;

  void _onSessionChanged(AuthViewState sessionState) {
    // A privacy lock masks the UI but is not an account change. Keep the
    // in-memory and user-scoped active clinic so unlock returns to the same
    // safe workspace without preserving it for a different account.
    if (sessionState.stage == AuthStage.locked) return;
    final identity = sessionState.stage == AuthStage.signedIn
        ? sessionState.identity
        : null;
    if (identity == null) {
      final formerUserId = _currentUserId;
      _currentUserId = null;
      _request++;
      if (formerUserId != null) unawaited(_clearFormerUser(formerUserId));
      if (!isClosed) emit(const ClinicState());
      return;
    }
    if (_currentUserId != identity.id) {
      _currentUserId = identity.id;
      unawaited(load());
    }
  }

  Future<void> _clearFormerUser(String userId) async {
    try {
      await _store.clearForUser(userId);
    } on AppFailure {
      // The selection is only a convenience. A stale local identifier is
      // still checked against RLS-filtered memberships before it is used.
    }
  }

  Future<void> load() async {
    final userId = _currentUserId;
    if (userId == null || isClosed) return;
    final request = ++_request;
    emit(state.copyWith(status: ClinicStatus.loading, clearFailure: true));
    try {
      final memberships = await _repository.getMyActiveMemberships();
      if (request != _request || userId != _currentUserId || isClosed) return;
      if (memberships.isEmpty) {
        emit(const ClinicState(status: ClinicStatus.empty, memberships: []));
        return;
      }
      String? selected;
      try {
        final remembered = await _store.readForUser(userId);
        if (memberships.any((item) => item.clinic.id == remembered)) {
          selected = remembered;
        }
      } on AppFailure {
        // Continue safely: the server-derived membership list is authoritative.
      }
      if (selected == null && memberships.length == 1) {
        selected = memberships.single.clinic.id;
        await _remember(userId, selected);
      }
      if (request != _request || userId != _currentUserId || isClosed) return;
      emit(
        ClinicState(
          status: ClinicStatus.ready,
          memberships: memberships,
          activeClinicId: selected,
        ),
      );
    } on AppFailure catch (failure) {
      if (request == _request && userId == _currentUserId && !isClosed) {
        emit(ClinicState(status: ClinicStatus.failure, failure: failure));
      }
    } on Object {
      if (request == _request && userId == _currentUserId && !isClosed) {
        emit(
          const ClinicState(
            status: ClinicStatus.failure,
            failure: UnknownFailure(),
          ),
        );
      }
    }
  }

  Future<void> selectClinic(String clinicId) async {
    final userId = _currentUserId;
    if (userId == null ||
        !state.memberships.any((item) => item.clinic.id == clinicId)) {
      return;
    }
    try {
      await _remember(userId, clinicId);
      if (!isClosed && userId == _currentUserId) {
        emit(state.copyWith(activeClinicId: clinicId, clearFailure: true));
      }
    } on AppFailure catch (failure) {
      if (!isClosed && userId == _currentUserId) {
        emit(state.copyWith(failure: failure));
      }
    }
  }

  Future<void> createClinic({
    required String name,
    required String ownerDisplayName,
    required String currencyCode,
    required String timeZone,
  }) async {
    final userId = _currentUserId;
    if (userId == null || state.creating) return;
    emit(state.copyWith(creating: true, clearFailure: true));
    try {
      final clinic = await _repository.createClinic(
        name: name,
        ownerDisplayName: ownerDisplayName,
        currencyCode: currencyCode,
        timeZone: timeZone,
      );
      if (userId != _currentUserId || isClosed) return;
      await _remember(userId, clinic.id);
      await load();
    } on AppFailure catch (failure) {
      if (!isClosed && userId == _currentUserId) {
        emit(state.copyWith(creating: false, failure: failure));
      }
    } on Object {
      if (!isClosed && userId == _currentUserId) {
        emit(state.copyWith(creating: false, failure: const UnknownFailure()));
      }
    }
  }

  Future<void> _remember(String userId, String clinicId) =>
      _store.writeForUser(userId, clinicId);

  @disposeMethod
  @override
  Future<void> close() async {
    _request++;
    await _subscription.cancel();
    return super.close();
  }
}

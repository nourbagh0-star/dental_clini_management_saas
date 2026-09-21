import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:injectable/injectable.dart';

import '../../../core/error/app_failure.dart';
import '../domain/staff_models.dart';
import '../domain/staff_repository.dart';

part 'staff_cubit.freezed.dart';

enum StaffStatus { initial, loading, ready, failure }

@Freezed(toStringOverride: false)
abstract class StaffState with _$StaffState {
  const factory StaffState({
    @Default(StaffStatus.initial) StaffStatus status,
    String? clinicId,
    @Default(<StaffMember>[]) List<StaffMember> members,
    @Default(<StaffInvitation>[]) List<StaffInvitation> invitations,
    @Default(false) bool mutating,
    AppFailure? failure,
    StaffOperationIssue? issue,
  }) = _StaffState;
}

@lazySingleton
class StaffCubit extends Cubit<StaffState> {
  StaffCubit(this._repository) : super(const StaffState());

  final StaffRepository _repository;
  int _request = 0;

  Future<bool> createAccount({
    required String clinicId,
    required String displayName,
    required String email,
    required Set<StaffRole> roles,
    required String temporaryPassword,
    required String ownerPassword,
  }) => _mutate(
    () => _repository.createAccount(
      clinicId: clinicId,
      displayName: displayName,
      email: email,
      roles: roles,
      temporaryPassword: temporaryPassword,
      ownerPassword: ownerPassword,
    ),
  );

  Future<void> load(String clinicId) async {
    final request = ++_request;
    emit(
      state.copyWith(
        status: StaffStatus.loading,
        clinicId: clinicId,
        failure: null,
        issue: null,
      ),
    );
    try {
      final result = await Future.wait([
        _repository.getStaffMembers(clinicId),
        _repository.getInvitations(clinicId),
      ]);
      if (isClosed || request != _request) return;
      emit(
        StaffState(
          status: StaffStatus.ready,
          clinicId: clinicId,
          members: result[0] as List<StaffMember>,
          invitations: result[1] as List<StaffInvitation>,
        ),
      );
    } on StaffOperationException catch (error) {
      _emitIssue(request, error.issue);
    } on AppFailure catch (error) {
      _emitFailure(request, error);
    } on Object {
      _emitFailure(request, const UnknownFailure());
    }
  }

  Future<bool> createInvitation({
    required String clinicId,
    required String email,
    required Set<StaffRole> roles,
    required Uri appOrigin,
    String? ownerPassword,
  }) => _mutate(
    () => _repository.createInvitation(
      clinicId: clinicId,
      email: email,
      roles: roles,
      appOrigin: appOrigin,
      ownerPassword: ownerPassword,
    ),
  );

  Future<bool> resendInvitation({
    required String invitationId,
    required Uri appOrigin,
    String? ownerPassword,
  }) async {
    final clinicId = state.clinicId;
    if (clinicId == null) return false;
    return _mutate(
      () => _repository.resendInvitation(
        clinicId: clinicId,
        invitationId: invitationId,
        appOrigin: appOrigin,
        ownerPassword: ownerPassword,
      ),
    );
  }

  Future<bool> revokeInvitation({
    required String invitationId,
    String? ownerPassword,
  }) async {
    final clinicId = state.clinicId;
    if (clinicId == null) return false;
    return _mutate(
      () => _repository.revokeInvitation(
        clinicId: clinicId,
        invitationId: invitationId,
        ownerPassword: ownerPassword,
      ),
    );
  }

  Future<bool> replaceMemberRoles({
    required String memberId,
    required Set<StaffRole> roles,
    String? ownerPassword,
  }) async {
    final clinicId = state.clinicId;
    if (clinicId == null) return false;
    return _mutate(
      () => _repository.replaceMemberRoles(
        clinicId: clinicId,
        memberId: memberId,
        roles: roles,
        ownerPassword: ownerPassword,
      ),
    );
  }

  Future<bool> setMemberActive({
    required String memberId,
    required bool isActive,
    String? ownerPassword,
  }) async {
    final clinicId = state.clinicId;
    if (clinicId == null) return false;
    return _mutate(
      () => _repository.setMemberActive(
        clinicId: clinicId,
        memberId: memberId,
        isActive: isActive,
        ownerPassword: ownerPassword,
      ),
    );
  }

  Future<String?> acceptInvitation(String token) async {
    if (state.mutating) return null;
    final request = ++_request;
    emit(state.copyWith(mutating: true, failure: null, issue: null));
    try {
      final clinicId = await _repository.acceptInvitation(token);
      if (!isClosed && request == _request) {
        emit(state.copyWith(mutating: false));
      }
      return clinicId;
    } on StaffOperationException catch (error) {
      _emitIssue(request, error.issue, mutating: false);
    } on AppFailure catch (error) {
      _emitFailure(request, error, mutating: false);
    } on Object {
      _emitFailure(request, const UnknownFailure(), mutating: false);
    }
    return null;
  }

  Future<bool> _mutate(Future<Object?> Function() action) async {
    final clinicId = state.clinicId;
    if (clinicId == null || state.mutating) return false;
    final request = ++_request;
    emit(state.copyWith(mutating: true, failure: null, issue: null));
    try {
      await action();
      if (isClosed || request != _request) return false;
      await load(clinicId);
      return state.status == StaffStatus.ready;
    } on StaffOperationException catch (error) {
      _emitIssue(request, error.issue, mutating: false);
    } on AppFailure catch (error) {
      _emitFailure(request, error, mutating: false);
    } on Object {
      _emitFailure(request, const UnknownFailure(), mutating: false);
    }
    return false;
  }

  void _emitIssue(int request, StaffOperationIssue issue, {bool? mutating}) {
    if (!isClosed && request == _request) {
      emit(
        state.copyWith(
          status: StaffStatus.failure,
          mutating: mutating ?? state.mutating,
          issue: issue,
          failure: null,
        ),
      );
    }
  }

  void _emitFailure(int request, AppFailure failure, {bool? mutating}) {
    if (!isClosed && request == _request) {
      emit(
        state.copyWith(
          status: StaffStatus.failure,
          mutating: mutating ?? state.mutating,
          failure: failure,
          issue: null,
        ),
      );
    }
  }

  void clear() {
    _request++;
    emit(const StaffState());
  }
}

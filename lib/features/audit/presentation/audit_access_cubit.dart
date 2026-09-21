import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';

import '../../../core/error/app_failure.dart';
import '../domain/audit_models.dart';
import '../domain/audit_repository.dart';

enum AuditAccessStatus { initial, recording, allowed, failure }

class AuditAccessState {
  const AuditAccessState({
    this.status = AuditAccessStatus.initial,
    this.key,
    this.failure,
  });
  final AuditAccessStatus status;
  final String? key;
  final AppFailure? failure;
}

@lazySingleton
class AuditAccessCubit extends Cubit<AuditAccessState> {
  AuditAccessCubit(this._repository) : super(const AuditAccessState());

  final AuditRepository _repository;
  int _request = 0;

  Future<void> record({
    required String clinicId,
    required AuditAccessIntent intent,
    required String subjectId,
  }) async {
    final key = '$clinicId:${intent.apiValue}:$subjectId';
    if (state.status == AuditAccessStatus.recording && state.key == key) return;
    final request = ++_request;
    emit(AuditAccessState(status: AuditAccessStatus.recording, key: key));
    try {
      await _repository.recordAccess(
        clinicId: clinicId,
        intent: intent,
        subjectId: subjectId,
      );
      if (!isClosed && request == _request) {
        emit(AuditAccessState(status: AuditAccessStatus.allowed, key: key));
      }
    } on AppFailure catch (failure) {
      if (!isClosed && request == _request) {
        emit(
          AuditAccessState(
            status: AuditAccessStatus.failure,
            key: key,
            failure: failure,
          ),
        );
      }
    } on Object {
      if (!isClosed && request == _request) {
        emit(
          AuditAccessState(
            status: AuditAccessStatus.failure,
            key: key,
            failure: const UnknownFailure(),
          ),
        );
      }
    }
  }
}

import 'audit_models.dart';

abstract interface class AuditRepository {
  Future<AuditPage> page({
    required String clinicId,
    required AuditFilter filter,
    AuditCursor? cursor,
    int limit = 50,
  });

  Future<void> recordAccess({
    required String clinicId,
    required AuditAccessIntent intent,
    required String subjectId,
    String? requestId,
    int? resultCount,
    int? pageSize,
    bool? searchPresent,
  });
}

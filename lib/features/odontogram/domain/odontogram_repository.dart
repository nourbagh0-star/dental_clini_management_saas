import 'odontogram_models.dart';

abstract class OdontogramRepository {
  Future<List<ToothCondition>> activeConditions(String patientId);
  Future<List<ToothCondition>> history({
    required String patientId,
    required int offset,
    required int limit,
  });
  Future<void> createCondition({
    required String patientId,
    required ToothConditionDraft draft,
  });
  Future<void> resolveCondition(String conditionId);
  Future<void> markConditionInError({
    required String conditionId,
    required String reason,
  });
}

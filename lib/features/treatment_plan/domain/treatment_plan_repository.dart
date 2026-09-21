import 'treatment_plan_models.dart';

abstract class TreatmentPlanRepository {
  Future<List<ClinicProcedure>> procedures(String clinicId);
  Future<List<TreatmentPlan>> plans(String patientId);
  Future<List<TreatmentPlanItem>> items(String planId);
  Future<void> createProcedure(String clinicId, ProcedureDraft draft);
  Future<void> updateProcedure(String procedureId, ProcedureDraft draft);
  Future<void> setProcedureActive(String procedureId, bool active);
  Future<void> createPlan({
    required String patientId,
    required String dentistMemberId,
    String? notes,
  });
  Future<void> updateDraftPlan(String planId, String? notes);
  Future<void> transitionPlan(String planId, TreatmentPlanStatus status);
  Future<void> addItem(String planId, TreatmentPlanItemDraft draft);
  Future<void> updateDraftItem(String itemId, TreatmentPlanItemDraft draft);
  Future<void> transitionItem(String itemId, TreatmentPlanItemStatus status);
  Future<void> reorderItems(String planId, List<String> itemIds);
}

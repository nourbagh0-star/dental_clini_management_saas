import 'package:injectable/injectable.dart';

import '../../../core/value/money.dart';
import '../domain/treatment_plan_models.dart';
import '../domain/treatment_plan_repository.dart';
import 'treatment_plan_data_source.dart';

@LazySingleton(as: TreatmentPlanRepository)
class SupabaseTreatmentPlanRepository implements TreatmentPlanRepository {
  SupabaseTreatmentPlanRepository(this._source);
  final TreatmentPlanDataSource _source;

  @override
  Future<List<ClinicProcedure>> procedures(String clinicId) async =>
      (await _source.procedureRows(
        clinicId,
      )).map(_procedure).toList(growable: false);
  @override
  Future<List<TreatmentPlan>> plans(String patientId) async =>
      (await _source.planRows(patientId)).map(_plan).toList(growable: false);
  @override
  Future<List<TreatmentPlanItem>> items(String planId) async =>
      (await _source.itemRows(planId)).map(_item).toList(growable: false);

  @override
  Future<void> createProcedure(String clinicId, ProcedureDraft draft) =>
      _source.invokeAction({
        'action': 'create_procedure',
        'clinicId': clinicId,
        'procedure': _procedureInput(draft),
      });
  @override
  Future<void> updateProcedure(String procedureId, ProcedureDraft draft) =>
      _source.invokeAction({
        'action': 'update_procedure',
        'procedureId': procedureId,
        'procedure': _procedureInput(draft),
      });
  @override
  Future<void> setProcedureActive(String procedureId, bool active) =>
      _source.invokeAction({
        'action': 'set_procedure_active',
        'procedureId': procedureId,
        'active': active,
      });
  @override
  Future<void> createPlan({
    required String patientId,
    required String dentistMemberId,
    String? notes,
  }) => _source.invokeAction({
    'action': 'create_plan',
    'patientId': patientId,
    'dentistMemberId': dentistMemberId,
    'notes': notes,
  });
  @override
  Future<void> updateDraftPlan(String planId, String? notes) =>
      _source.invokeAction({
        'action': 'update_draft_plan',
        'planId': planId,
        'notes': notes,
      });
  @override
  Future<void> transitionPlan(String planId, TreatmentPlanStatus status) =>
      _source.invokeAction({
        'action': 'transition_plan',
        'planId': planId,
        'status': status.name,
      });
  @override
  Future<void> addItem(String planId, TreatmentPlanItemDraft draft) =>
      _source.invokeAction({
        'action': 'add_plan_item',
        'planId': planId,
        'item': _itemInput(draft),
      });
  @override
  Future<void> updateDraftItem(String itemId, TreatmentPlanItemDraft draft) =>
      _source.invokeAction({
        'action': 'update_draft_plan_item',
        'itemId': itemId,
        'item': _itemInput(draft),
      });
  @override
  Future<void> transitionItem(String itemId, TreatmentPlanItemStatus status) =>
      _source.invokeAction({
        'action': 'transition_plan_item',
        'itemId': itemId,
        'status': status.apiValue,
      });
  @override
  Future<void> reorderItems(String planId, List<String> itemIds) =>
      _source.invokeAction({
        'action': 'reorder_draft_plan_items',
        'planId': planId,
        'itemIds': itemIds,
      });

  Map<String, Object> _procedureInput(ProcedureDraft draft) => {
    'name': draft.name,
    'category': draft.category,
    'defaultPrice': draft.defaultPrice.toDecimalString(),
    'durationMinutes': draft.durationMinutes,
  };
  Map<String, Object?> _itemInput(TreatmentPlanItemDraft draft) => {
    'procedureId': draft.procedureId,
    'toothNumber': draft.toothNumber,
    'description': draft.description,
    'estimatedPrice': draft.estimatedPrice?.toDecimalString(),
    'assignedDentistId': draft.assignedDentistId,
  };
  ClinicProcedure _procedure(Map<String, dynamic> row) => ClinicProcedure(
    id: row['id'] as String,
    clinicId: row['clinic_id'] as String,
    name: row['name'] as String,
    category: row['category'] as String,
    defaultPrice: Money.parseCanonical(row['default_price'] as String),
    durationMinutes: row['duration_minutes'] as int,
    active: row['active'] as bool,
  );
  TreatmentPlan _plan(Map<String, dynamic> row) => TreatmentPlan(
    id: row['id'] as String,
    clinicId: row['clinic_id'] as String,
    patientId: row['patient_id'] as String,
    dentistMemberId: row['dentist_member_id'] as String,
    status: TreatmentPlanStatus.fromApi(row['status']),
    notes: row['notes'] as String?,
    totalEstimatedCost: Money.parseCanonical(
      row['total_estimated_cost'] as String,
    ),
    updatedAt: DateTime.parse(row['updated_at'] as String).toUtc(),
  );
  TreatmentPlanItem _item(Map<String, dynamic> row) => TreatmentPlanItem(
    id: row['id'] as String,
    treatmentPlanId: row['treatment_plan_id'] as String,
    procedureId: row['procedure_id'] as String,
    toothNumber: row['tooth_number'] as int?,
    description: row['description'] as String?,
    estimatedPrice: Money.parseCanonical(row['estimated_price'] as String),
    status: TreatmentPlanItemStatus.fromApi(row['status']),
    assignedDentistId: row['assigned_dentist_id'] as String?,
    sortOrder: row['sort_order'] as int,
  );
}

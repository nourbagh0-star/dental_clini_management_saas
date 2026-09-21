import '../../../core/value/money.dart';

enum TreatmentPlanStatus {
  draft,
  active,
  completed,
  cancelled;

  String get label => switch (this) {
    TreatmentPlanStatus.draft => 'Draft',
    TreatmentPlanStatus.active => 'Active',
    TreatmentPlanStatus.completed => 'Completed',
    TreatmentPlanStatus.cancelled => 'Cancelled',
  };

  static TreatmentPlanStatus fromApi(Object? value) => switch (value) {
    'active' => TreatmentPlanStatus.active,
    'completed' => TreatmentPlanStatus.completed,
    'cancelled' => TreatmentPlanStatus.cancelled,
    _ => TreatmentPlanStatus.draft,
  };
}

enum TreatmentPlanItemStatus {
  planned,
  approved,
  inProgress,
  completed,
  cancelled;

  String get apiValue =>
      this == TreatmentPlanItemStatus.inProgress ? 'in_progress' : name;
  String get label => switch (this) {
    TreatmentPlanItemStatus.planned => 'Planned',
    TreatmentPlanItemStatus.approved => 'Approved',
    TreatmentPlanItemStatus.inProgress => 'In progress',
    TreatmentPlanItemStatus.completed => 'Completed',
    TreatmentPlanItemStatus.cancelled => 'Cancelled',
  };

  static TreatmentPlanItemStatus fromApi(Object? value) => switch (value) {
    'approved' => TreatmentPlanItemStatus.approved,
    'in_progress' => TreatmentPlanItemStatus.inProgress,
    'completed' => TreatmentPlanItemStatus.completed,
    'cancelled' => TreatmentPlanItemStatus.cancelled,
    _ => TreatmentPlanItemStatus.planned,
  };
}

class ClinicProcedure {
  const ClinicProcedure({
    required this.id,
    required this.clinicId,
    required this.name,
    required this.category,
    required this.defaultPrice,
    required this.durationMinutes,
    required this.active,
  });
  final String id;
  final String clinicId;
  final String name;
  final String category;
  final Money defaultPrice;
  final int durationMinutes;
  final bool active;
}

class ProcedureDraft {
  const ProcedureDraft({
    required this.name,
    required this.category,
    required this.defaultPrice,
    required this.durationMinutes,
  });
  final String name;
  final String category;
  final Money defaultPrice;
  final int durationMinutes;
}

class TreatmentPlan {
  const TreatmentPlan({
    required this.id,
    required this.clinicId,
    required this.patientId,
    required this.dentistMemberId,
    required this.status,
    required this.totalEstimatedCost,
    required this.updatedAt,
    this.notes,
  });
  final String id;
  final String clinicId;
  final String patientId;
  final String dentistMemberId;
  final TreatmentPlanStatus status;
  final String? notes;
  final Money totalEstimatedCost;
  final DateTime updatedAt;
}

class TreatmentPlanItem {
  const TreatmentPlanItem({
    required this.id,
    required this.treatmentPlanId,
    required this.procedureId,
    required this.estimatedPrice,
    required this.status,
    required this.sortOrder,
    this.toothNumber,
    this.description,
    this.assignedDentistId,
  });
  final String id;
  final String treatmentPlanId;
  final String procedureId;
  final int? toothNumber;
  final String? description;
  final Money estimatedPrice;
  final TreatmentPlanItemStatus status;
  final String? assignedDentistId;
  final int sortOrder;
}

class TreatmentPlanItemDraft {
  const TreatmentPlanItemDraft({
    required this.procedureId,
    this.toothNumber,
    this.description,
    this.estimatedPrice,
    this.assignedDentistId,
  });
  final String procedureId;
  final int? toothNumber;
  final String? description;
  final Money? estimatedPrice;
  final String? assignedDentistId;
}

enum TreatmentPlanOperationIssue {
  forbidden,
  unavailable,
  invalidInput,
  draftOnly,
  activeRequired,
  itemsRequired,
  activePlanExists,
  invalidTransition,
}

class TreatmentPlanOperationException implements Exception {
  const TreatmentPlanOperationException(this.issue);
  final TreatmentPlanOperationIssue issue;
}

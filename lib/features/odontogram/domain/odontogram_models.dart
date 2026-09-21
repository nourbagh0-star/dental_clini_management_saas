enum ToothSurface {
  whole,
  mesial,
  distal,
  occlusal,
  buccal,
  lingual;

  String get apiValue => name;

  String get label => switch (this) {
    ToothSurface.whole => 'Whole tooth',
    ToothSurface.mesial => 'Mesial',
    ToothSurface.distal => 'Distal',
    ToothSurface.occlusal => 'Occlusal',
    ToothSurface.buccal => 'Buccal',
    ToothSurface.lingual => 'Lingual',
  };

  static ToothSurface fromApi(Object? value) => switch (value) {
    'mesial' => ToothSurface.mesial,
    'distal' => ToothSurface.distal,
    'occlusal' => ToothSurface.occlusal,
    'buccal' => ToothSurface.buccal,
    'lingual' => ToothSurface.lingual,
    _ => ToothSurface.whole,
  };
}

enum ToothConditionType {
  caries,
  filling,
  crown,
  rootCanal,
  fracture,
  missing,
  extractionRequired,
  implant;

  String get apiValue => switch (this) {
    ToothConditionType.rootCanal => 'root_canal',
    ToothConditionType.extractionRequired => 'extraction_required',
    _ => name,
  };

  String get label => switch (this) {
    ToothConditionType.caries => 'Caries',
    ToothConditionType.filling => 'Filling',
    ToothConditionType.crown => 'Crown',
    ToothConditionType.rootCanal => 'Root canal',
    ToothConditionType.fracture => 'Fracture',
    ToothConditionType.missing => 'Missing',
    ToothConditionType.extractionRequired => 'Extraction required',
    ToothConditionType.implant => 'Implant',
  };

  bool get wholeToothOnly => switch (this) {
    ToothConditionType.missing ||
    ToothConditionType.rootCanal ||
    ToothConditionType.extractionRequired ||
    ToothConditionType.implant => true,
    _ => false,
  };

  static ToothConditionType fromApi(Object? value) => switch (value) {
    'filling' => ToothConditionType.filling,
    'crown' => ToothConditionType.crown,
    'root_canal' => ToothConditionType.rootCanal,
    'fracture' => ToothConditionType.fracture,
    'missing' => ToothConditionType.missing,
    'extraction_required' => ToothConditionType.extractionRequired,
    'implant' => ToothConditionType.implant,
    _ => ToothConditionType.caries,
  };
}

enum ToothConditionStatus {
  active,
  resolved,
  enteredInError;

  String get label => switch (this) {
    ToothConditionStatus.active => 'Active',
    ToothConditionStatus.resolved => 'Resolved',
    ToothConditionStatus.enteredInError => 'Entered in error',
  };

  static ToothConditionStatus fromApi(Object? value) => switch (value) {
    'resolved' => ToothConditionStatus.resolved,
    'entered_in_error' => ToothConditionStatus.enteredInError,
    _ => ToothConditionStatus.active,
  };
}

enum Dentition { permanent, primary }

class ToothCondition {
  const ToothCondition({
    required this.id,
    required this.patientId,
    required this.toothNumber,
    required this.surface,
    required this.type,
    required this.status,
    required this.createdAt,
    this.notes,
    this.resolvedAt,
    this.errorReason,
    this.markedInErrorAt,
  });

  final String id;
  final String patientId;
  final int toothNumber;
  final ToothSurface surface;
  final ToothConditionType type;
  final ToothConditionStatus status;
  final DateTime createdAt;
  final String? notes;
  final DateTime? resolvedAt;
  final String? errorReason;
  final DateTime? markedInErrorAt;

  Dentition get dentition =>
      toothNumber >= 50 ? Dentition.primary : Dentition.permanent;
}

class ToothConditionDraft {
  const ToothConditionDraft({
    required this.toothNumber,
    required this.surface,
    required this.type,
    this.notes,
  });

  final int toothNumber;
  final ToothSurface surface;
  final ToothConditionType type;
  final String? notes;
}

enum OdontogramOperationIssue {
  forbidden,
  unavailable,
  invalidInput,
  missingToothConflict,
  duplicateActiveCondition,
  conditionNotActive,
}

class OdontogramOperationException implements Exception {
  const OdontogramOperationException(this.issue);
  final OdontogramOperationIssue issue;
}

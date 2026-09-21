import 'package:injectable/injectable.dart';

import '../domain/odontogram_models.dart';
import '../domain/odontogram_repository.dart';
import 'odontogram_data_source.dart';

@LazySingleton(as: OdontogramRepository)
class SupabaseOdontogramRepository implements OdontogramRepository {
  SupabaseOdontogramRepository(this._source);
  final OdontogramDataSource _source;

  @override
  Future<List<ToothCondition>> activeConditions(String patientId) async =>
      (await _source.activeRows(
        patientId,
      )).map(_condition).toList(growable: false);

  @override
  Future<List<ToothCondition>> history({
    required String patientId,
    required int offset,
    required int limit,
  }) async => (await _source.historyRows(
    patientId: patientId,
    offset: offset,
    limit: limit,
  )).map(_condition).toList(growable: false);

  @override
  Future<void> createCondition({
    required String patientId,
    required ToothConditionDraft draft,
  }) => _source.invokeAction({
    'action': 'create_condition',
    'patientId': patientId,
    'condition': {
      'toothNumber': draft.toothNumber,
      'surface': draft.surface.apiValue,
      'conditionType': draft.type.apiValue,
      'notes': draft.notes,
    },
  });

  @override
  Future<void> resolveCondition(String conditionId) => _source.invokeAction({
    'action': 'resolve_condition',
    'conditionId': conditionId,
  });

  @override
  Future<void> markConditionInError({
    required String conditionId,
    required String reason,
  }) => _source.invokeAction({
    'action': 'mark_condition_in_error',
    'conditionId': conditionId,
    'reason': reason,
  });

  ToothCondition _condition(Map<String, dynamic> row) => ToothCondition(
    id: row['id'] as String,
    patientId: row['patient_id'] as String,
    toothNumber: row['tooth_number'] as int,
    surface: ToothSurface.fromApi(row['surface']),
    type: ToothConditionType.fromApi(row['condition_type']),
    status: ToothConditionStatus.fromApi(row['status']),
    notes: row['notes'] as String?,
    createdAt: DateTime.parse(row['created_at'] as String).toUtc(),
    resolvedAt: _date(row['resolved_at']),
    errorReason: row['error_reason'] as String?,
    markedInErrorAt: _date(row['marked_in_error_at']),
  );

  DateTime? _date(Object? value) =>
      value is String ? DateTime.tryParse(value)?.toUtc() : null;
}

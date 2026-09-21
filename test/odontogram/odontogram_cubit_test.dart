import 'package:dental_clini_management_saas/features/odontogram/domain/odontogram_models.dart';
import 'package:dental_clini_management_saas/features/odontogram/domain/odontogram_repository.dart';
import 'package:dental_clini_management_saas/features/odontogram/presentation/odontogram_cubit.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('OdontogramCubit', () {
    test(
      'loads active conditions and the first page of preserved history',
      () async {
        final repository = _MemoryOdontogramRepository()
          ..active = [_condition(id: 'active')]
          ..historyItems = [
            _condition(id: 'active'),
            _condition(id: 'resolved'),
          ];
        final cubit = OdontogramCubit(repository);
        addTearDown(cubit.close);

        await cubit.load('patient-1');

        expect(cubit.state.status, OdontogramLoadStatus.ready);
        expect(cubit.state.active.single.id, 'active');
        expect(cubit.state.history, hasLength(2));
        expect(cubit.state.historyHasMore, isFalse);
      },
    );

    test('refreshes the chart after a dentist resolves a condition', () async {
      final repository = _MemoryOdontogramRepository()
        ..active = [_condition(id: 'active')]
        ..historyItems = [_condition(id: 'active')];
      final cubit = OdontogramCubit(repository);
      addTearDown(cubit.close);
      await cubit.load('patient-1');

      final succeeded = await cubit.resolve(
        patientId: 'patient-1',
        conditionId: 'active',
      );

      expect(succeeded, isTrue);
      expect(repository.resolved, ['active']);
      expect(repository.activeReads, 2);
    });

    test(
      'preserves a safe typed conflict message for a missing tooth',
      () async {
        final repository = _MemoryOdontogramRepository()
          ..createFailure = const OdontogramOperationException(
            OdontogramOperationIssue.missingToothConflict,
          );
        final cubit = OdontogramCubit(repository);
        addTearDown(cubit.close);
        await cubit.load('patient-1');

        final succeeded = await cubit.create(
          patientId: 'patient-1',
          draft: const ToothConditionDraft(
            toothNumber: 16,
            surface: ToothSurface.whole,
            type: ToothConditionType.missing,
          ),
        );

        expect(succeeded, isFalse);
        expect(
          cubit.state.issue,
          OdontogramOperationIssue.missingToothConflict,
        );
      },
    );
  });

  test(
    'primary teeth and whole-tooth-only conditions use safe domain rules',
    () {
      expect(_condition(toothNumber: 54).dentition, Dentition.primary);
      expect(ToothConditionType.implant.wholeToothOnly, isTrue);
      expect(ToothConditionType.caries.wholeToothOnly, isFalse);
      expect(
        ToothConditionType.fromApi('extraction_required'),
        ToothConditionType.extractionRequired,
      );
    },
  );
}

ToothCondition _condition({String id = 'condition', int toothNumber = 16}) =>
    ToothCondition(
      id: id,
      patientId: 'patient-1',
      toothNumber: toothNumber,
      surface: ToothSurface.occlusal,
      type: ToothConditionType.caries,
      status: id == 'resolved'
          ? ToothConditionStatus.resolved
          : ToothConditionStatus.active,
      createdAt: DateTime.utc(2026),
    );

class _MemoryOdontogramRepository implements OdontogramRepository {
  List<ToothCondition> active = const [];
  List<ToothCondition> historyItems = const [];
  final resolved = <String>[];
  int activeReads = 0;
  Object? createFailure;

  @override
  Future<List<ToothCondition>> activeConditions(String patientId) async {
    activeReads++;
    return active;
  }

  @override
  Future<void> createCondition({
    required String patientId,
    required ToothConditionDraft draft,
  }) async {
    if (createFailure != null) throw createFailure!;
  }

  @override
  Future<List<ToothCondition>> history({
    required String patientId,
    required int offset,
    required int limit,
  }) async => historyItems.skip(offset).take(limit).toList(growable: false);

  @override
  Future<void> markConditionInError({
    required String conditionId,
    required String reason,
  }) async {}

  @override
  Future<void> resolveCondition(String conditionId) async {
    resolved.add(conditionId);
    active = const [];
  }
}

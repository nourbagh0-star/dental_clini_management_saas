import 'package:bloc_test/bloc_test.dart';
import 'package:dental_clini_management_saas/features/treatment_plan/domain/standard_dental_procedures.dart';
import 'package:dental_clini_management_saas/features/treatment_plan/domain/treatment_plan_models.dart';
import 'package:dental_clini_management_saas/features/treatment_plan/domain/treatment_plan_repository.dart';
import 'package:dental_clini_management_saas/features/treatment_plan/presentation/treatment_plan_cubit.dart';
import 'package:dental_clini_management_saas/core/value/money.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late _FakeRepository repository;

  setUp(() => repository = _FakeRepository());

  blocTest<TreatmentPlanCubit, TreatmentPlanState>(
    'loads the active plan and its ordered items',
    build: () => TreatmentPlanCubit(repository),
    act: (cubit) => cubit.loadPatient('clinic-1', 'patient-1'),
    verify: (cubit) {
      expect(cubit.state.status, TreatmentPlanLoadStatus.ready);
      expect(cubit.state.selectedPlanId, 'active-plan');
      expect(cubit.state.items.single.id, 'item-1');
    },
  );

  blocTest<TreatmentPlanCubit, TreatmentPlanState>(
    'refreshes the catalogue after an owner creates a procedure',
    build: () => TreatmentPlanCubit(repository),
    act: (cubit) async {
      await cubit.loadCatalogue('clinic-1');
      await cubit.createProcedure(
        'clinic-1',
        const ProcedureDraft(
          name: 'Cleaning',
          category: 'Hygiene',
          defaultPrice: Money.fromMinorUnits(120000),
          durationMinutes: 30,
        ),
      );
    },
    verify: (cubit) {
      expect(repository.createdProcedure, isTrue);
      expect(cubit.state.status, TreatmentPlanLoadStatus.ready);
      expect(cubit.state.procedures.single.name, 'Cleaning');
    },
  );

  blocTest<TreatmentPlanCubit, TreatmentPlanState>(
    'imports a batch of procedures and refreshes the catalogue',
    build: () => TreatmentPlanCubit(repository),
    act: (cubit) async {
      await cubit.loadCatalogue('clinic-1');
      await cubit.createProceduresBatch('clinic-1', [
        const ProcedureDraft(
          name: 'Exam',
          category: 'Preventive',
          defaultPrice: Money.fromMinorUnits(3000),
          durationMinutes: 30,
        ),
        const ProcedureDraft(
          name: 'Cleaning',
          category: 'Preventive',
          defaultPrice: Money.fromMinorUnits(5000),
          durationMinutes: 45,
        ),
      ]);
    },
    verify: (cubit) {
      expect(repository.createdCount, 2);
      expect(cubit.state.status, TreatmentPlanLoadStatus.ready);
    },
  );

  test('StandardDentalProcedures provides localized templates for EN, AR, and RU', () {
    final enDrafts = StandardDentalProcedures.draftsForLocale('en');
    final arDrafts = StandardDentalProcedures.draftsForLocale('ar');
    final ruDrafts = StandardDentalProcedures.draftsForLocale('ru');

    expect(enDrafts.length, greaterThanOrEqualTo(15));
    expect(arDrafts.length, enDrafts.length);
    expect(ruDrafts.length, enDrafts.length);

    expect(enDrafts.first.name, 'Comprehensive Dental Examination');
    expect(arDrafts.first.name, 'فحص واستشارة أسنان شاملة');
    expect(ruDrafts.first.name, 'Первичный осмотр и консультация');
  });
}

class _FakeRepository implements TreatmentPlanRepository {
  bool createdProcedure = false;
  int createdCount = 0;

  @override
  Future<List<ClinicProcedure>> procedures(String clinicId) async =>
      createdProcedure
      ? const [
          ClinicProcedure(
            id: 'procedure-1',
            clinicId: 'clinic-1',
            name: 'Cleaning',
            category: 'Hygiene',
            defaultPrice: Money.fromMinorUnits(120000),
            durationMinutes: 30,
            active: true,
          ),
        ]
      : const [];

  @override
  Future<List<TreatmentPlan>> plans(String patientId) async => [
    TreatmentPlan(
      id: 'draft-plan',
      clinicId: 'clinic-1',
      patientId: patientId,
      dentistMemberId: 'dentist-1',
      status: TreatmentPlanStatus.draft,
      totalEstimatedCost: Money.zero,
      updatedAt: DateTime.utc(2026, 9, 9),
    ),
    TreatmentPlan(
      id: 'active-plan',
      clinicId: 'clinic-1',
      patientId: patientId,
      dentistMemberId: 'dentist-1',
      status: TreatmentPlanStatus.active,
      totalEstimatedCost: Money.fromMinorUnits(120000),
      updatedAt: DateTime.utc(2026, 9, 8),
    ),
  ];

  @override
  Future<List<TreatmentPlanItem>> items(String planId) async => const [
    TreatmentPlanItem(
      id: 'item-1',
      treatmentPlanId: 'active-plan',
      procedureId: 'procedure-1',
      estimatedPrice: Money.fromMinorUnits(120000),
      status: TreatmentPlanItemStatus.approved,
      sortOrder: 0,
    ),
  ];

  @override
  Future<void> createProcedure(String clinicId, ProcedureDraft draft) async {
    createdProcedure = true;
    createdCount++;
  }

  @override
  Future<void> addItem(String planId, TreatmentPlanItemDraft draft) async {}

  @override
  Future<void> createPlan({
    required String patientId,
    required String dentistMemberId,
    String? notes,
  }) async {}

  @override
  Future<void> reorderItems(String planId, List<String> itemIds) async {}

  @override
  Future<void> setProcedureActive(String procedureId, bool active) async {}

  @override
  Future<void> transitionItem(
    String itemId,
    TreatmentPlanItemStatus status,
  ) async {}

  @override
  Future<void> transitionPlan(
    String planId,
    TreatmentPlanStatus status,
  ) async {}

  @override
  Future<void> updateDraftItem(
    String itemId,
    TreatmentPlanItemDraft draft,
  ) async {}

  @override
  Future<void> updateDraftPlan(String planId, String? notes) async {}

  @override
  Future<void> updateProcedure(
    String procedureId,
    ProcedureDraft draft,
  ) async {}
}

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';

import '../../../core/error/app_failure.dart';
import '../domain/treatment_plan_models.dart';
import '../domain/treatment_plan_repository.dart';

enum TreatmentPlanLoadStatus { initial, loading, ready, failure }

class TreatmentPlanState {
  const TreatmentPlanState({
    this.status = TreatmentPlanLoadStatus.initial,
    this.clinicId,
    this.patientId,
    this.procedures = const [],
    this.plans = const [],
    this.selectedPlanId,
    this.items = const [],
    this.mutating = false,
    this.failure,
    this.issue,
  });

  final TreatmentPlanLoadStatus status;
  final String? clinicId;
  final String? patientId;
  final List<ClinicProcedure> procedures;
  final List<TreatmentPlan> plans;
  final String? selectedPlanId;
  final List<TreatmentPlanItem> items;
  final bool mutating;
  final AppFailure? failure;
  final TreatmentPlanOperationIssue? issue;

  TreatmentPlan? get selectedPlan {
    for (final plan in plans) {
      if (plan.id == selectedPlanId) return plan;
    }
    return null;
  }

  TreatmentPlanState copyWith({
    TreatmentPlanLoadStatus? status,
    String? clinicId,
    String? patientId,
    bool clearPatientId = false,
    List<ClinicProcedure>? procedures,
    List<TreatmentPlan>? plans,
    String? selectedPlanId,
    bool clearSelectedPlanId = false,
    List<TreatmentPlanItem>? items,
    bool? mutating,
    AppFailure? failure,
    bool clearFailure = false,
    TreatmentPlanOperationIssue? issue,
    bool clearIssue = false,
  }) => TreatmentPlanState(
    status: status ?? this.status,
    clinicId: clinicId ?? this.clinicId,
    patientId: clearPatientId ? null : patientId ?? this.patientId,
    procedures: procedures ?? this.procedures,
    plans: plans ?? this.plans,
    selectedPlanId: clearSelectedPlanId
        ? null
        : selectedPlanId ?? this.selectedPlanId,
    items: items ?? this.items,
    mutating: mutating ?? this.mutating,
    failure: clearFailure ? null : failure ?? this.failure,
    issue: clearIssue ? null : issue ?? this.issue,
  );
}

@lazySingleton
class TreatmentPlanCubit extends Cubit<TreatmentPlanState> {
  TreatmentPlanCubit(this._repository) : super(const TreatmentPlanState());

  final TreatmentPlanRepository _repository;
  int _request = 0;

  Future<void> loadCatalogue(String clinicId) async {
    final request = ++_request;
    emit(
      TreatmentPlanState(
        status: TreatmentPlanLoadStatus.loading,
        clinicId: clinicId,
        procedures: state.clinicId == clinicId ? state.procedures : const [],
      ),
    );
    try {
      final procedures = await _repository.procedures(clinicId);
      if (!isClosed && request == _request) {
        emit(
          TreatmentPlanState(
            status: TreatmentPlanLoadStatus.ready,
            clinicId: clinicId,
            procedures: procedures,
          ),
        );
      }
    } on AppFailure catch (error) {
      _failure(request, error);
    } on Object {
      _failure(request, const UnknownFailure());
    }
  }

  Future<void> loadPatient(String clinicId, String patientId) async {
    final request = ++_request;
    emit(
      TreatmentPlanState(
        status: TreatmentPlanLoadStatus.loading,
        clinicId: clinicId,
        patientId: patientId,
      ),
    );
    try {
      final result = await Future.wait<Object>([
        _repository.procedures(clinicId),
        _repository.plans(patientId),
      ]);
      if (isClosed || request != _request) return;
      final procedures = result[0] as List<ClinicProcedure>;
      final plans = result[1] as List<TreatmentPlan>;
      final selectedPlanId = _preferredPlanId(plans);
      final items = selectedPlanId == null
          ? const <TreatmentPlanItem>[]
          : await _repository.items(selectedPlanId);
      if (!isClosed && request == _request) {
        emit(
          TreatmentPlanState(
            status: TreatmentPlanLoadStatus.ready,
            clinicId: clinicId,
            patientId: patientId,
            procedures: procedures,
            plans: plans,
            selectedPlanId: selectedPlanId,
            items: items,
          ),
        );
      }
    } on TreatmentPlanOperationException catch (error) {
      _issue(request, error.issue);
    } on AppFailure catch (error) {
      _failure(request, error);
    } on Object {
      _failure(request, const UnknownFailure());
    }
  }

  Future<void> selectPlan(String planId) async {
    if (state.selectedPlanId == planId ||
        state.status == TreatmentPlanLoadStatus.loading) {
      return;
    }
    final request = ++_request;
    emit(
      state.copyWith(
        status: TreatmentPlanLoadStatus.loading,
        selectedPlanId: planId,
        items: const [],
        clearFailure: true,
        clearIssue: true,
      ),
    );
    try {
      final items = await _repository.items(planId);
      if (!isClosed && request == _request) {
        emit(
          state.copyWith(
            status: TreatmentPlanLoadStatus.ready,
            selectedPlanId: planId,
            items: items,
          ),
        );
      }
    } on AppFailure catch (error) {
      _failure(request, error);
    } on Object {
      _failure(request, const UnknownFailure());
    }
  }

  Future<bool> createProcedure(String clinicId, ProcedureDraft draft) =>
      _mutate(() => _repository.createProcedure(clinicId, draft));

  Future<bool> createProceduresBatch(
    String clinicId,
    List<ProcedureDraft> drafts,
  ) => _mutate(() async {
    for (final draft in drafts) {
      await _repository.createProcedure(clinicId, draft);
    }
  });

  Future<bool> updateProcedure(String id, ProcedureDraft draft) =>
      _mutate(() => _repository.updateProcedure(id, draft));

  Future<bool> setProcedureActive(String id, bool active) =>
      _mutate(() => _repository.setProcedureActive(id, active));

  Future<bool> createPlan({
    required String patientId,
    required String dentistMemberId,
    String? notes,
  }) => _mutate(
    () => _repository.createPlan(
      patientId: patientId,
      dentistMemberId: dentistMemberId,
      notes: notes,
    ),
  );

  Future<bool> updateDraftPlan(String planId, String? notes) =>
      _mutate(() => _repository.updateDraftPlan(planId, notes));

  Future<bool> transitionPlan(String planId, TreatmentPlanStatus status) =>
      _mutate(() => _repository.transitionPlan(planId, status));

  Future<bool> addItem(String planId, TreatmentPlanItemDraft draft) =>
      _mutate(() => _repository.addItem(planId, draft));

  Future<bool> updateDraftItem(String itemId, TreatmentPlanItemDraft draft) =>
      _mutate(() => _repository.updateDraftItem(itemId, draft));

  Future<bool> transitionItem(String itemId, TreatmentPlanItemStatus status) =>
      _mutate(() => _repository.transitionItem(itemId, status));

  Future<bool> reorderItems(String planId, List<String> itemIds) =>
      _mutate(() => _repository.reorderItems(planId, itemIds));

  Future<bool> _mutate(Future<void> Function() action) async {
    if (state.mutating) return false;
    final request = ++_request;
    emit(state.copyWith(mutating: true, clearFailure: true, clearIssue: true));
    try {
      await action();
      if (isClosed || request != _request) return false;
      await _reload();
      return state.status == TreatmentPlanLoadStatus.ready;
    } on TreatmentPlanOperationException catch (error) {
      _issue(request, error.issue, mutating: false);
    } on AppFailure catch (error) {
      _failure(request, error, mutating: false);
    } on Object {
      _failure(request, const UnknownFailure(), mutating: false);
    }
    return false;
  }

  Future<void> _reload() async {
    final clinicId = state.clinicId;
    final patientId = state.patientId;
    final previousSelected = state.selectedPlanId;
    if (clinicId == null) return;
    if (patientId == null) {
      await loadCatalogue(clinicId);
      return;
    }
    final result = await Future.wait<Object>([
      _repository.procedures(clinicId),
      _repository.plans(patientId),
    ]);
    final procedures = result[0] as List<ClinicProcedure>;
    final plans = result[1] as List<TreatmentPlan>;
    final selectedPlanId = plans.any((plan) => plan.id == previousSelected)
        ? previousSelected
        : _preferredPlanId(plans);
    final items = selectedPlanId == null
        ? const <TreatmentPlanItem>[]
        : await _repository.items(selectedPlanId);
    if (!isClosed) {
      emit(
        TreatmentPlanState(
          status: TreatmentPlanLoadStatus.ready,
          clinicId: clinicId,
          patientId: patientId,
          procedures: procedures,
          plans: plans,
          selectedPlanId: selectedPlanId,
          items: items,
        ),
      );
    }
  }

  String? _preferredPlanId(List<TreatmentPlan> plans) {
    for (final plan in plans) {
      if (plan.status == TreatmentPlanStatus.active) return plan.id;
    }
    return plans.firstOrNull?.id;
  }

  void _issue(
    int request,
    TreatmentPlanOperationIssue issue, {
    bool? mutating,
  }) {
    if (!isClosed && request == _request) {
      emit(
        state.copyWith(
          status: TreatmentPlanLoadStatus.failure,
          mutating: mutating ?? state.mutating,
          issue: issue,
          clearFailure: true,
        ),
      );
    }
  }

  void _failure(int request, AppFailure failure, {bool? mutating}) {
    if (!isClosed && request == _request) {
      emit(
        state.copyWith(
          status: TreatmentPlanLoadStatus.failure,
          mutating: mutating ?? state.mutating,
          failure: failure,
          clearIssue: true,
        ),
      );
    }
  }

  void clear() {
    _request++;
    emit(const TreatmentPlanState());
  }
}

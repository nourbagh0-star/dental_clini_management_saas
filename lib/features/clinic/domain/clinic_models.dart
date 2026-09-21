import '../../../core/error/app_failure.dart';

class Clinic {
  const Clinic({
    required this.id,
    required this.name,
    required this.currencyCode,
    required this.timeZone,
  });

  final String id;
  final String name;
  final String currencyCode;
  final String timeZone;
}

class ClinicMembership {
  const ClinicMembership({
    required this.clinic,
    required this.roles,
    this.memberId,
  });

  final Clinic clinic;
  final Set<String> roles;
  final String? memberId;

  bool get isOwner => roles.contains('owner');
}

enum ClinicStatus { initial, loading, empty, ready, failure }

class ClinicState {
  const ClinicState({
    this.status = ClinicStatus.initial,
    this.memberships = const [],
    this.activeClinicId,
    this.creating = false,
    this.failure,
  });

  final ClinicStatus status;
  final List<ClinicMembership> memberships;
  final String? activeClinicId;
  final bool creating;
  final AppFailure? failure;

  Clinic? get activeClinic {
    for (final membership in memberships) {
      if (membership.clinic.id == activeClinicId) return membership.clinic;
    }
    return null;
  }

  ClinicMembership? get activeMembership {
    for (final membership in memberships) {
      if (membership.clinic.id == activeClinicId) return membership;
    }
    return null;
  }

  ClinicState copyWith({
    ClinicStatus? status,
    List<ClinicMembership>? memberships,
    String? activeClinicId,
    bool clearActiveClinicId = false,
    bool? creating,
    AppFailure? failure,
    bool clearFailure = false,
  }) => ClinicState(
    status: status ?? this.status,
    memberships: memberships ?? this.memberships,
    activeClinicId: clearActiveClinicId
        ? null
        : activeClinicId ?? this.activeClinicId,
    creating: creating ?? this.creating,
    failure: clearFailure ? null : failure ?? this.failure,
  );
}

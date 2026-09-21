import 'package:freezed_annotation/freezed_annotation.dart';

part 'staff_models.freezed.dart';

enum StaffRole {
  owner,
  dentist,
  assistant,
  receptionist;

  String get apiValue => name;

  static StaffRole? fromApi(Object? value) => switch (value) {
    'owner' => StaffRole.owner,
    'dentist' => StaffRole.dentist,
    'assistant' => StaffRole.assistant,
    'receptionist' => StaffRole.receptionist,
    _ => null,
  };
}

enum StaffInvitationStatus {
  pending,
  accepted,
  revoked,
  expired;

  static StaffInvitationStatus? fromApi(Object? value) => switch (value) {
    'pending' => StaffInvitationStatus.pending,
    'accepted' => StaffInvitationStatus.accepted,
    'revoked' => StaffInvitationStatus.revoked,
    'expired' => StaffInvitationStatus.expired,
    _ => null,
  };
}

/// Stable, non-sensitive outcomes emitted by the protected staff API.
enum StaffOperationIssue {
  invalidInput,
  ownerReauthenticationRequired,
  invitationUnavailable,
  memberUnavailable,
  accountUnavailable,
}

class StaffOperationException implements Exception {
  const StaffOperationException(this.issue);

  final StaffOperationIssue issue;

  @override
  String toString() => 'StaffOperationException(${issue.name})';
}

@Freezed(toStringOverride: false)
abstract class StaffMember with _$StaffMember {
  const factory StaffMember({
    required String id,
    required String userId,
    required String displayName,
    required String email,
    required bool isActive,
    required Set<StaffRole> roles,
    DateTime? deactivatedAt,
  }) = _StaffMember;
}

@Freezed(toStringOverride: false)
abstract class StaffInvitation with _$StaffInvitation {
  const factory StaffInvitation({
    required String id,
    required String clinicId,
    required String email,
    required Set<StaffRole> roles,
    required StaffInvitationStatus status,
    required DateTime createdAt,
    required DateTime expiresAt,
    required DateTime lastSentAt,
    required int resendCount,
    DateTime? acceptedAt,
    DateTime? revokedAt,
  }) = _StaffInvitation;
}

@Freezed(toStringOverride: false)
abstract class StaffInvitationDelivery with _$StaffInvitationDelivery {
  const factory StaffInvitationDelivery({
    required String invitationId,
    required DateTime expiresAt,
  }) = _StaffInvitationDelivery;
}

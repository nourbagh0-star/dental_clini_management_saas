import 'package:freezed_annotation/freezed_annotation.dart';

part 'auth_models.freezed.dart';

enum AuthStage {
  restoring,
  signedOut,
  awaitingVerification,
  signedIn,
  locked,
  recoveryPending,
  recoveryAuthorized,
  restorationFailed,
  passwordChangeRequired,
}

enum AuthIssue {
  emailConfirmed,
  invalidConfirmationLink,
  confirmationLinkSent,
  credentials,
  unconfirmed,
  invalidCode,
  weakPassword,
  rateLimited,
  network,
  storage,
  unavailable,
  unknown,
  revocationUnconfirmed,
  passwordChangedRevocationUnconfirmed,
  passwordChanged,
  recoverySent,
  passwordChangeRequired,
}

class AuthOperationException implements Exception {
  const AuthOperationException(this.issue);
  final AuthIssue issue;
  @override
  String toString() => 'AuthOperationException(${issue.name})';
}

@Freezed(toStringOverride: false)
abstract class AuthIdentity with _$AuthIdentity {
  const factory AuthIdentity({required String id, required String email}) =
      _AuthIdentity;
}

@Freezed(toStringOverride: false)
abstract class AuthViewState with _$AuthViewState {
  const factory AuthViewState({
    @Default(AuthStage.restoring) AuthStage stage,
    AuthIdentity? identity,
    @Default('') String email,
    @Default(false) bool busy,
    @Default(false) bool hidden,
    AuthIssue? issue,
  }) = _AuthViewState;
}

enum AuthAction {
  confirmEmailLink,
  recoveryLink,
  login,
  register,
  verifyEmail,
  resend,
  recover,
  verifyRecovery,
  resetPassword,
  changeInitialPassword,
  unlock,
  restore,
}

/// Single-use input: never serialize or retain secrets in state/diagnostics.
class AuthInput {
  AuthInput({this.email = '', this._secret = ''});
  final String email;
  String _secret;
  String takeSecret() {
    final value = _secret;
    _secret = '';
    return value;
  }

  void clear() {
    _secret = '';
  }

  @override
  String toString() => 'AuthInput(redacted)';
}

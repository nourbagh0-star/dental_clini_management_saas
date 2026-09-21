import '../../../../app/localization/generated/app_localizations.dart';
import '../../domain/auth_models.dart';

String authIssueMessage(AuthIssue issue, AppLocalizations l) => switch (issue) {
  AuthIssue.emailConfirmed => l.emailConfirmed,
  AuthIssue.invalidConfirmationLink => l.invalidConfirmationLink,
  AuthIssue.confirmationLinkSent => l.confirmationLinkSent,
  AuthIssue.credentials => l.authCredentials,
  AuthIssue.unconfirmed => l.authUnconfirmed,
  AuthIssue.invalidCode => l.authInvalidCode,
  AuthIssue.weakPassword => l.authWeakPassword,
  AuthIssue.rateLimited => l.authRateLimited,
  AuthIssue.network => l.networkFailure,
  AuthIssue.storage => l.authStorage,
  AuthIssue.unavailable => l.authUnavailable,
  AuthIssue.unknown => l.unknownFailure,
  AuthIssue.revocationUnconfirmed => l.authRevocation,
  AuthIssue.passwordChangedRevocationUnconfirmed => l.authResetPartial,
  AuthIssue.passwordChanged => l.authResetDone,
  AuthIssue.recoverySent => l.recoveryLinkSent,
  AuthIssue.passwordChangeRequired => l.initialPasswordHelp,
};

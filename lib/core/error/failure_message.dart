import '../../app/localization/generated/app_localizations.dart';
import 'app_failure.dart';

String failureMessage(AppFailure failure, AppLocalizations l10n) =>
    switch (failure) {
      NetworkFailure() => l10n.networkFailure,
      AuthenticationFailure() => l10n.authenticationFailure,
      AuthorizationFailure() => l10n.authorizationFailure,
      ValidationFailure() => l10n.validationFailure,
      ServerFailure() => l10n.serverFailure,
      NotFoundFailure() => l10n.notFoundFailure,
      UnknownFailure() => l10n.unknownFailure,
    };

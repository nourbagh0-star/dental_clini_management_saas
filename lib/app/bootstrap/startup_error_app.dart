import 'package:flutter/material.dart';

import '../../core/widgets/message_page.dart';
import '../localization/generated/app_localizations.dart';
import '../theme/app_theme.dart';

class StartupErrorApp extends StatelessWidget {
  const StartupErrorApp({
    required this.configurationError,
    required this.onRetry,
    super.key,
  });
  final bool configurationError;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) => MaterialApp(
    debugShowCheckedModeBanner: false,
    theme: AppTheme.light,
    darkTheme: AppTheme.dark,
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    home: Builder(
      builder: (context) {
        final l10n = AppLocalizations.of(context);
        return MessagePage(
          title: l10n.startupTitle,
          message: configurationError
              ? l10n.configurationBody
              : l10n.startupBody,
          actionLabel: l10n.retryLabel,
          onAction: onRetry,
        );
      },
    ),
  );
}

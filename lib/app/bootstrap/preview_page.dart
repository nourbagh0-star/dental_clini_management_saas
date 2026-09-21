import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../localization/generated/app_localizations.dart';
import '../theme/app_theme.dart';
import '../theme/appearance.dart';
import '../theme/appearance_cubit.dart';

class PreviewPage extends StatelessWidget {
  const PreviewPage({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(l10n.appTitle)),
      body: SafeArea(
        child: Align(
          alignment: Alignment.topCenter,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(AppSpacing.large),
            child: ConstrainedBox(
              constraints: const BoxConstraints(
                maxWidth: AppSpacing.contentWidth,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: AppSpacing.large),
                  Text(
                    l10n.demoLabel,
                    style: theme.textTheme.labelLarge?.copyWith(
                      color: theme.colorScheme.primary,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.medium),
                  Text(l10n.welcomeTitle, style: theme.textTheme.headlineLarge),
                  const SizedBox(height: AppSpacing.medium),
                  Text(l10n.welcomeBody, style: theme.textTheme.bodyLarge),
                  const SizedBox(height: AppSpacing.large),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(AppSpacing.large),
                      child: Text(l10n.demoNotice),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.extraLarge),
                  const _AppearancePanel(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _AppearancePanel extends StatelessWidget {
  const _AppearancePanel();

  @override
  Widget build(
    BuildContext context,
  ) => BlocBuilder<AppearanceCubit, AppearanceState>(
    builder: (context, state) {
      final l10n = AppLocalizations.of(context);
      final cubit = context.read<AppearanceCubit>();
      final controls = [
        DropdownButtonFormField<AppThemeMode>(
          key: ValueKey('theme-${state.preferences.theme.name}'),
          initialValue: state.preferences.theme,
          isExpanded: true,
          decoration: InputDecoration(labelText: l10n.themeLabel),
          items: [
            DropdownMenuItem(
              value: AppThemeMode.system,
              child: Text(l10n.systemLabel),
            ),
            DropdownMenuItem(
              value: AppThemeMode.light,
              child: Text(l10n.lightLabel),
            ),
            DropdownMenuItem(
              value: AppThemeMode.dark,
              child: Text(l10n.darkLabel),
            ),
          ],
          onChanged: state.busy ? null : (value) => cubit.change(theme: value),
        ),
        DropdownButtonFormField<AppLanguage>(
          key: ValueKey('language-${state.preferences.language.name}'),
          initialValue: state.preferences.language,
          isExpanded: true,
          decoration: InputDecoration(labelText: l10n.languageLabel),
          items: [
            DropdownMenuItem(
              value: AppLanguage.system,
              child: Text(l10n.systemLabel),
            ),
            DropdownMenuItem(
              value: AppLanguage.english,
              child: Text(l10n.englishLabel),
            ),
            DropdownMenuItem(
              value: AppLanguage.russian,
              child: Text(l10n.russianLabel),
            ),
            DropdownMenuItem(
              value: AppLanguage.arabic,
              child: Text(l10n.arabicLabel),
            ),
          ],
          onChanged: state.busy
              ? null
              : (value) => cubit.change(language: value),
        ),
      ];
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.appearanceTitle,
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: AppSpacing.large),
          LayoutBuilder(
            builder: (context, constraints) => constraints.maxWidth >= 600
                ? Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(child: controls[0]),
                      const SizedBox(width: AppSpacing.medium),
                      Expanded(child: controls[1]),
                    ],
                  )
                : Column(
                    children: [
                      controls[0],
                      const SizedBox(height: AppSpacing.large),
                      controls[1],
                    ],
                  ),
          ),
          if (state.storageFailed) ...[
            const SizedBox(height: AppSpacing.medium),
            Semantics(
              liveRegion: true,
              child: Text(
                l10n.storageWarning,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            ),
          ],
        ],
      );
    },
  );
}

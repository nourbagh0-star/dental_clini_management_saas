import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../app/localization/generated/app_localizations.dart';
import '../../../../app/theme/appearance.dart';
import '../../../../app/theme/appearance_cubit.dart';

class AuthAppearanceActions extends StatelessWidget {
  const AuthAppearanceActions({super.key});
  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final cubit = context.read<AppearanceCubit>();
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        PopupMenuButton<AppLanguage>(
          tooltip: l.languageLabel,
          icon: const Icon(Icons.language),
          onSelected: (value) => cubit.change(language: value),
          itemBuilder: (_) => [
            PopupMenuItem(
              value: AppLanguage.system,
              child: Text(l.systemLabel),
            ),
            PopupMenuItem(
              value: AppLanguage.english,
              child: Text(l.englishLabel),
            ),
            PopupMenuItem(
              value: AppLanguage.russian,
              child: Text(l.russianLabel),
            ),
            PopupMenuItem(
              value: AppLanguage.arabic,
              child: Text(l.arabicLabel),
            ),
          ],
        ),
        PopupMenuButton<AppThemeMode>(
          tooltip: l.themeLabel,
          icon: const Icon(Icons.contrast),
          onSelected: (value) => cubit.change(theme: value),
          itemBuilder: (_) => [
            PopupMenuItem(
              value: AppThemeMode.system,
              child: Text(l.systemLabel),
            ),
            PopupMenuItem(value: AppThemeMode.light, child: Text(l.lightLabel)),
            PopupMenuItem(value: AppThemeMode.dark, child: Text(l.darkLabel)),
          ],
        ),
      ],
    );
  }
}

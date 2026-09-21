import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/localization/generated/app_localizations.dart';
import '../../../../app/theme/app_theme.dart';
import '../../../../app/theme/appearance.dart';
import '../../../../app/theme/appearance_cubit.dart';
import '../../../../core/widgets/workspace_page.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../../clinic/presentation/clinic_cubit.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final appearance = context.watch<AppearanceCubit>().state;
    final clinic = context.watch<ClinicCubit>().state;
    final auth = context.watch<AuthBloc>().state;
    return WorkspacePage(
      title: Text(l10n.settingsTitle),
      scrollable: true,
      maximumWidth: AppSpacing.contentWidth,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _SettingsSection(
            title: l10n.appearanceTitle,
            icon: Icons.palette_outlined,
            children: [
              DropdownButtonFormField<AppThemeMode>(
                isExpanded: true,
                key: const ValueKey('settings-theme'),
                initialValue: appearance.preferences.theme,
                decoration: InputDecoration(labelText: l10n.themeLabel),
                items: [
                  DropdownMenuItem(
                    value: AppThemeMode.system,
                    child: Text(l10n.themeSystemLabel),
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
                onChanged: appearance.busy
                    ? null
                    : (value) {
                        if (value != null) {
                          context.read<AppearanceCubit>().change(theme: value);
                        }
                      },
              ),
              const SizedBox(height: AppSpacing.medium),
              DropdownButtonFormField<AppLanguage>(
                isExpanded: true,
                key: const ValueKey('settings-language'),
                initialValue: appearance.preferences.language,
                decoration: InputDecoration(labelText: l10n.languageLabel),
                items: [
                  DropdownMenuItem(
                    value: AppLanguage.system,
                    child: Text(l10n.languageSystemLabel),
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
                onChanged: appearance.busy
                    ? null
                    : (value) {
                        if (value != null) {
                          context.read<AppearanceCubit>().change(
                            language: value,
                          );
                        }
                      },
              ),
              if (appearance.storageFailed) ...[
                const SizedBox(height: AppSpacing.medium),
                Semantics(liveRegion: true, child: Text(l10n.storageWarning)),
              ],
            ],
          ),
          const SizedBox(height: AppSpacing.medium),
          _SettingsSection(
            title: l10n.clinicSectionTitle,
            icon: Icons.local_hospital_outlined,
            children: [
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(
                  clinic.activeClinic?.name ?? l10n.chooseClinicFirst,
                ),
                subtitle: clinic.activeClinic == null
                    ? null
                    : Text(
                        l10n.clinicTimeZoneValue(clinic.activeClinic!.timeZone),
                      ),
              ),
              if (clinic.memberships.length > 1)
                Align(
                  alignment: AlignmentDirectional.centerStart,
                  child: OutlinedButton.icon(
                    onPressed: () => context.go('/clinics/select'),
                    icon: const Icon(Icons.swap_horiz),
                    label: Text(l10n.switchClinicLabel),
                  ),
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.medium),
          _SettingsSection(
            title: l10n.privacySectionTitle,
            icon: Icons.lock_outline,
            children: [
              Align(
                alignment: AlignmentDirectional.centerStart,
                child: OutlinedButton.icon(
                  onPressed: () =>
                      context.read<AuthBloc>().add(AuthLockRequested()),
                  icon: const Icon(Icons.lock_outline),
                  label: Text(l10n.lockLabel),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.medium),
          _SettingsSection(
            title: l10n.accountSectionTitle,
            icon: Icons.account_circle_outlined,
            children: [
              if ((auth.identity?.email ?? auth.email).isNotEmpty)
                SelectableText(auth.identity?.email ?? auth.email),
              const SizedBox(height: AppSpacing.medium),
              Align(
                alignment: AlignmentDirectional.centerStart,
                child: OutlinedButton.icon(
                  onPressed: () =>
                      context.read<AuthBloc>().add(AuthLogoutRequested()),
                  icon: const Icon(Icons.logout),
                  label: Text(l10n.logoutLabel),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.medium),
          _SettingsSection(
            title: l10n.applicationSectionTitle,
            icon: Icons.info_outline,
            children: [Text(l10n.developmentMvpLabel)],
          ),
        ],
      ),
    );
  }
}

class _SettingsSection extends StatelessWidget {
  const _SettingsSection({
    required this.title,
    required this.icon,
    required this.children,
  });

  final String title;
  final IconData icon;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) => Card(
    child: Padding(
      padding: const EdgeInsets.all(AppSpacing.large),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Icon(icon),
              const SizedBox(width: AppSpacing.small),
              Expanded(
                child: Text(
                  title,
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.large),
          ...children,
        ],
      ),
    ),
  );
}

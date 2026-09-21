import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/localization/generated/app_localizations.dart';
import '../../../../app/theme/app_theme.dart';
import '../../../clinic/presentation/clinic_cubit.dart';
import '../../domain/patient_models.dart';
import '../patient_medical_cubit.dart';

/// High-visibility clinical safety banner displaying critical medical alerts,
/// drug allergies, chronic conditions, or NKDA status across the clinical workflow.
class PatientMedicalAlertBanner extends StatefulWidget {
  const PatientMedicalAlertBanner({
    required this.patientId,
    this.padding,
    super.key,
  });

  final String patientId;
  final EdgeInsetsGeometry? padding;

  @override
  State<PatientMedicalAlertBanner> createState() =>
      _PatientMedicalAlertBannerState();
}

class _PatientMedicalAlertBannerState extends State<PatientMedicalAlertBanner> {
  @override
  void initState() {
    super.initState();
    _checkAndLoad();
  }

  @override
  void didUpdateWidget(PatientMedicalAlertBanner oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.patientId != widget.patientId) {
      _checkAndLoad();
    }
  }

  void _checkAndLoad() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      try {
        final cubit = context.read<PatientMedicalCubit>();
        if (cubit.state.patientId != widget.patientId && !cubit.state.loading) {
          cubit.load(widget.patientId);
        }
      } catch (_) {
        // PatientMedicalCubit not in tree (e.g. isolated test)
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    PatientMedicalCubit? cubit;
    try {
      cubit = context.watch<PatientMedicalCubit>();
    } catch (_) {
      cubit = null;
    }
    if (cubit == null) {
      return const SizedBox.shrink();
    }

    final l = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final roles =
        context.watch<ClinicCubit>().state.activeMembership?.roles ??
        const <String>{};
    final canRead =
        roles.contains('owner') ||
        roles.contains('dentist') ||
        roles.contains('assistant');
    final canEdit = roles.contains('owner') || roles.contains('dentist');

    if (!canRead) {
      return const SizedBox.shrink();
    }

    return BlocBuilder<PatientMedicalCubit, PatientMedicalState>(
      bloc: cubit,
      builder: (context, state) {
        if (state.loading && state.patientId != widget.patientId) {
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: AppSpacing.small),
            child: LinearProgressIndicator(),
          );
        }

        // Only display profile if it matches the current patient
        final profile =
            state.patientId == widget.patientId ? state.profile : null;

        if (profile != null && profile.hasAlerts) {
          return _buildAlertBanner(context, l, theme, profile, canEdit);
        }

        if (profile == null || profile.isEmpty) {
          return _buildUnscreenedBanner(context, l, theme, canEdit);
        }

        return _buildCleanBanner(context, l, theme, canEdit);
      },
    );
  }

  Widget _buildAlertBanner(
    BuildContext context,
    AppLocalizations l,
    ThemeData theme,
    PatientMedicalProfile profile,
    bool canEdit,
  ) {
    final errorColor = theme.colorScheme.error;
    final hasAllergies =
        profile.allergies != null &&
        profile.allergies!.trim().isNotEmpty;
    final hasChronic =
        profile.chronicConditions != null &&
        profile.chronicConditions!.trim().isNotEmpty;
    final hasNotes =
        profile.importantMedicalNotes != null &&
        profile.importantMedicalNotes!.trim().isNotEmpty;

    return Container(
      margin: widget.padding ?? EdgeInsets.zero,
      decoration: BoxDecoration(
        color: theme.colorScheme.errorContainer.withValues(alpha: 0.28),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: errorColor.withValues(alpha: 0.6),
          width: 1.5,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.medium),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.warning_amber_rounded,
                  color: errorColor,
                  size: 22,
                ),
                const SizedBox(width: AppSpacing.small),
                Expanded(
                  child: Text(
                    l.medicalAlertsTitle,
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: errorColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                TextButton.icon(
                  onPressed: () =>
                      context.go('/patients/${widget.patientId}/medical'),
                  icon: const Icon(Icons.edit_outlined, size: 16),
                  label: Text(l.editLabel),
                  style: TextButton.styleFrom(
                    foregroundColor: errorColor,
                    visualDensity: VisualDensity.compact,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.small),
            if (hasAllergies) ...[
              _buildAlertField(
                icon: Icons.dangerous_outlined,
                label: l.allergiesLabel,
                value: profile.allergies!,
                color: errorColor,
                theme: theme,
              ),
              if (hasChronic || hasNotes) const SizedBox(height: 6),
            ],
            if (hasChronic) ...[
              _buildAlertField(
                icon: Icons.monitor_heart_outlined,
                label: l.chronicConditionsLabel,
                value: profile.chronicConditions!,
                color: errorColor,
                theme: theme,
              ),
              if (hasNotes) const SizedBox(height: 6),
            ],
            if (hasNotes) ...[
              _buildAlertField(
                icon: Icons.info_outline,
                label: l.importantMedicalNotesLabel,
                value: profile.importantMedicalNotes!,
                color: theme.colorScheme.onSurface,
                theme: theme,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildAlertField({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
    required ThemeData theme,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 16, color: color),
        const SizedBox(width: AppSpacing.small),
        Expanded(
          child: Text.rich(
            TextSpan(
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurface,
              ),
              children: [
                TextSpan(
                  text: '$label: ',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                TextSpan(text: value),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildUnscreenedBanner(
    BuildContext context,
    AppLocalizations l,
    ThemeData theme,
    bool canEdit,
  ) {
    return Container(
      margin: widget.padding ?? EdgeInsets.zero,
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.35),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: theme.colorScheme.outlineVariant.withValues(alpha: 0.6),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.medium,
          vertical: AppSpacing.small,
        ),
        child: Row(
          children: [
            Icon(
              Icons.health_and_safety_outlined,
              color: theme.colorScheme.secondary,
              size: 22,
            ),
            const SizedBox(width: AppSpacing.small),
            Expanded(
              child: Text(
                l.unscreenedMedicalHelp,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ),
            const SizedBox(width: AppSpacing.small),
            if (canEdit)
              OutlinedButton(
                onPressed: () =>
                    context.go('/patients/${widget.patientId}/medical'),
                style: OutlinedButton.styleFrom(
                  visualDensity: VisualDensity.compact,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                ),
                child: Text(l.screenMedicalLabel),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildCleanBanner(
    BuildContext context,
    AppLocalizations l,
    ThemeData theme,
    bool canEdit,
  ) {
    const safeGreen = Color(0xFF1B873F);
    return Container(
      margin: widget.padding ?? EdgeInsets.zero,
      decoration: BoxDecoration(
        color: safeGreen.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: safeGreen.withValues(alpha: 0.35),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.medium,
          vertical: AppSpacing.small,
        ),
        child: Row(
          children: [
            const Icon(
              Icons.verified_outlined,
              color: safeGreen,
              size: 20,
            ),
            const SizedBox(width: AppSpacing.small),
            Expanded(
              child: Text(
                l.noKnownAllergies,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: safeGreen,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            IconButton(
              onPressed: () =>
                  context.go('/patients/${widget.patientId}/medical'),
              icon: const Icon(Icons.edit_outlined, size: 16),
              tooltip: l.editLabel,
              visualDensity: VisualDensity.compact,
            ),
          ],
        ),
      ),
    );
  }
}

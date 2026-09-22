import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/localization/generated/app_localizations.dart';
import '../../../../app/theme/app_theme.dart';
import '../../../../core/export/csv_export_helper.dart';
import '../../../appointment/domain/appointment_models.dart';
import '../../../appointment/presentation/appointment_cubit.dart';
import '../../../billing/presentation/billing_cubit.dart';
import '../../../clinic/presentation/clinic_cubit.dart';
import '../../../patient/presentation/patient_cubit.dart';
import '../dashboard_cubit.dart';

/// Clinic and Financial Analytics overview with 1-tap CSV export capabilities.
class AnalyticsPage extends StatefulWidget {
  const AnalyticsPage({super.key});

  @override
  State<AnalyticsPage> createState() => _AnalyticsPageState();
}

class _AnalyticsPageState extends State<AnalyticsPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _initData());
  }

  void _initData() {
    final clinicState = context.read<ClinicCubit>().state;
    final clinicId = clinicState.activeClinicId;
    if (clinicId == null) return;

    final roles = clinicState.activeMembership?.roles ?? const <String>{};

    context.read<DashboardCubit>().load(clinicId);

    final patientState = context.read<PatientCubit>().state;
    if (patientState.patients.isEmpty) {
      context.read<PatientCubit>().load(clinicId);
    }

    final appointmentState = context.read<AppointmentCubit>().state;
    if (appointmentState.appointments.isEmpty) {
      final now = DateTime.now();
      context.read<AppointmentCubit>().load(
            clinicId: clinicId,
            from: now.subtract(const Duration(days: 180)),
            until: now.add(const Duration(days: 90)),
          );
    }

    final billingState = context.read<BillingCubit>().state;
    if (billingState.invoices.isEmpty) {
      context.read<BillingCubit>().load(
            clinicId: clinicId,
            patientId: null,
            roles: roles,
          );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l = AppLocalizations.of(context);

    final patientState = context.watch<PatientCubit>().state;
    final appointmentState = context.watch<AppointmentCubit>().state;
    final billingState = context.watch<BillingCubit>().state;

    final appointments = appointmentState.appointments;
    final patients = patientState.patients;
    final invoices = billingState.invoices;

    // Calculate appointment attendance metrics
    final completedCount = appointments
        .where((a) => a.status == AppointmentStatus.completed)
        .length;
    final cancelledCount = appointments
        .where((a) => a.status == AppointmentStatus.cancelled)
        .length;
    final noShowCount = appointments
        .where((a) => a.status == AppointmentStatus.noShow)
        .length;
    final scheduledCount = appointments
        .where((a) => a.status == AppointmentStatus.scheduled || a.status == AppointmentStatus.confirmed)
        .length;

    final attendedDenominator = completedCount + cancelledCount + noShowCount;
    final attendancePercentage = attendedDenominator > 0
        ? (completedCount / attendedDenominator) * 100
        : 100.0;

    // Financial totals
    final totalBilled = invoices.fold<double>(
      0.0,
      (sum, inv) => sum + (inv.total.minorUnits / 100.0),
    );
    final totalCollected = invoices.fold<double>(
      0.0,
      (sum, inv) => sum + (inv.paidAmount.minorUnits / 100.0),
    );
    final totalOutstanding = invoices.fold<double>(
      0.0,
      (sum, inv) => sum + (inv.outstandingBalance.minorUnits / 100.0),
    );
    final currency = invoices.isNotEmpty ? invoices.first.currencyCode : '';

    return Scaffold(
      appBar: AppBar(
        title: Text(l.analyticsAndReportsTitle),
        leading: BackButton(
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go('/dashboard');
            }
          },
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.medium),
        children: [
          // 1. Attendance Performance Card
          Card(
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: BorderSide(
                color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5),
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.medium),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.primaryContainer,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(
                          Icons.insights_rounded,
                          color: theme.colorScheme.primary,
                          size: 22,
                        ),
                      ),
                      const SizedBox(width: AppSpacing.small),
                      Expanded(
                        child: Text(
                          l.attendanceRate,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      Text(
                        '${attendancePercentage.toStringAsFixed(1)}%',
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: attendancePercentage >= 75
                              ? const Color(0xFF2E7D32)
                              : theme.colorScheme.error,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.medium),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: LinearProgressIndicator(
                      value: (attendancePercentage / 100.0).clamp(0.0, 1.0),
                      minHeight: 10,
                      backgroundColor: theme.colorScheme.surfaceContainerHighest,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        attendancePercentage >= 75
                            ? const Color(0xFF2E7D32)
                            : theme.colorScheme.primary,
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.medium),
                  Wrap(
                    spacing: AppSpacing.small,
                    runSpacing: AppSpacing.small,
                    children: [
                      _MetricChip(
                        label: l.appointmentStatusCompleted,
                        count: completedCount,
                        color: const Color(0xFF2E7D32),
                      ),
                      _MetricChip(
                        label: l.appointmentStatusScheduled,
                        count: scheduledCount,
                        color: theme.colorScheme.primary,
                      ),
                      _MetricChip(
                        label: l.appointmentStatusCancelled,
                        count: cancelledCount,
                        color: theme.colorScheme.outline,
                      ),
                      _MetricChip(
                        label: l.appointmentStatusNoShow,
                        count: noShowCount,
                        color: theme.colorScheme.error,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.medium),

          // 2. Financial Overview Card
          Card(
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: BorderSide(
                color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5),
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.medium),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.tertiaryContainer,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(
                          Icons.account_balance_wallet_outlined,
                          color: theme.colorScheme.onTertiaryContainer,
                          size: 22,
                        ),
                      ),
                      const SizedBox(width: AppSpacing.small),
                      Expanded(
                        child: Text(
                          l.financialSummaryTitle,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.medium),
                  Row(
                    children: [
                      Expanded(
                        child: _FinancialStat(
                          title: l.billingTitle,
                          amount: totalBilled.toStringAsFixed(2),
                          currency: currency,
                          textColor: theme.colorScheme.onSurface,
                        ),
                      ),
                      Expanded(
                        child: _FinancialStat(
                          title: l.invoicePaidLabel,
                          amount: totalCollected.toStringAsFixed(2),
                          currency: currency,
                          textColor: const Color(0xFF2E7D32),
                        ),
                      ),
                      Expanded(
                        child: _FinancialStat(
                          title: l.dashboardOutstandingPayments,
                          amount: totalOutstanding.toStringAsFixed(2),
                          currency: currency,
                          textColor: totalOutstanding > 0
                              ? theme.colorScheme.error
                              : theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.medium),

          // 3. Data Export Center Card
          Card(
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: BorderSide(
                color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5),
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.medium),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.secondaryContainer,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(
                          Icons.file_download_outlined,
                          color: theme.colorScheme.onSecondaryContainer,
                          size: 22,
                        ),
                      ),
                      const SizedBox(width: AppSpacing.small),
                      Expanded(
                        child: Text(
                          l.exportCenterTitle,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.medium),

                  // Patients Export Tile
                  _ExportTile(
                    title: l.exportPatientsLabel,
                    subtitle: '${patients.length}',
                    icon: Icons.people_outline_rounded,
                    onExport: () {
                      final csv = CsvExportHelper.exportPatients(patients);
                      CsvExportHelper.copyToClipboard(context, csv);
                    },
                  ),
                  const Divider(height: 16),

                  // Appointments Export Tile
                  _ExportTile(
                    title: l.exportAppointmentsLabel,
                    subtitle: '${appointments.length}',
                    icon: Icons.event_note_outlined,
                    onExport: () {
                      final csv = CsvExportHelper.exportAppointments(appointments);
                      CsvExportHelper.copyToClipboard(context, csv);
                    },
                  ),
                  const Divider(height: 16),

                  // Invoices Export Tile
                  _ExportTile(
                    title: l.exportInvoicesLabel,
                    subtitle: '${invoices.length}',
                    icon: Icons.receipt_long_outlined,
                    onExport: () {
                      final csv = CsvExportHelper.exportInvoices(invoices);
                      CsvExportHelper.copyToClipboard(context, csv);
                    },
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MetricChip extends StatelessWidget {
  const _MetricChip({
    required this.label,
    required this.count,
    required this.color,
  });

  final String label;
  final int count;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
          const SizedBox(width: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              '$count',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 11,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _FinancialStat extends StatelessWidget {
  const _FinancialStat({
    required this.title,
    required this.amount,
    required this.currency,
    required this.textColor,
  });

  final String title;
  final String amount;
  final String currency;
  final Color textColor;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: theme.textTheme.labelMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 4),
        Text(
          currency.isNotEmpty ? '$amount $currency' : amount,
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.bold,
            color: textColor,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }
}

class _ExportTile extends StatelessWidget {
  const _ExportTile({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.onExport,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final VoidCallback onExport;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l = AppLocalizations.of(context);

    return Row(
      children: [
        Icon(icon, size: 22, color: theme.colorScheme.primary),
        const SizedBox(width: AppSpacing.small),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                subtitle,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
        FilledButton.tonalIcon(
          onPressed: onExport,
          icon: const Icon(Icons.copy_rounded, size: 16),
          label: Text(l.copyToClipboard),
          style: FilledButton.styleFrom(
            visualDensity: VisualDensity.compact,
          ),
        ),
      ],
    );
  }
}

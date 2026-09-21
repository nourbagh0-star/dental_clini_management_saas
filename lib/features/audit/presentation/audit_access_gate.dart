import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../app/localization/generated/app_localizations.dart';
import '../../../app/theme/app_theme.dart';
import '../../../core/error/failure_message.dart';
import '../../clinic/presentation/clinic_cubit.dart';
import '../domain/audit_models.dart';
import 'audit_access_cubit.dart';

class AuditAccessGate extends StatefulWidget {
  const AuditAccessGate({
    required this.intent,
    required this.subjectId,
    required this.child,
    super.key,
  });

  final AuditAccessIntent intent;
  final String subjectId;
  final Widget child;

  @override
  State<AuditAccessGate> createState() => _AuditAccessGateState();
}

class _AuditAccessGateState extends State<AuditAccessGate> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _record());
  }

  void _record() {
    if (!mounted) return;
    final clinicId = context.read<ClinicCubit>().state.activeClinicId;
    if (clinicId != null) {
      context.read<AuditAccessCubit>().record(
        clinicId: clinicId,
        intent: widget.intent,
        subjectId: widget.subjectId,
      );
    }
  }

  @override
  Widget build(BuildContext context) =>
      BlocBuilder<AuditAccessCubit, AuditAccessState>(
        builder: (context, state) {
          final clinicId = context.read<ClinicCubit>().state.activeClinicId;
          final key = clinicId == null
              ? null
              : '$clinicId:${widget.intent.apiValue}:${widget.subjectId}';
          if (state.key == key && state.status == AuditAccessStatus.allowed) {
            return widget.child;
          }
          if (state.key == key && state.status == AuditAccessStatus.failure) {
            final l = AppLocalizations.of(context);
            return Scaffold(
              appBar: AppBar(),
              body: Center(
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.large),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.shield_outlined, size: 48),
                      const SizedBox(height: AppSpacing.medium),
                      Text(
                        state.failure == null
                            ? l.auditUnavailable
                            : failureMessage(state.failure!, l),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: AppSpacing.medium),
                      FilledButton.icon(
                        onPressed: _record,
                        icon: const Icon(Icons.refresh),
                        label: Text(l.retryLabel),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        },
      );
}

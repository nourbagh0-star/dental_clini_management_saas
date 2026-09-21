import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import 'localization/generated/app_localizations.dart';
import 'theme/app_theme.dart';
import 'theme/appearance.dart';
import 'theme/appearance_cubit.dart';
import '../features/auth/presentation/bloc/auth_bloc.dart';
import '../core/auth/privacy_boundary.dart';
import '../features/clinic/presentation/clinic_cubit.dart';
import '../features/staff/presentation/staff_cubit.dart';
import '../features/schedule/presentation/schedule_cubit.dart';
import '../features/patient/presentation/patient_cubit.dart';
import '../features/patient/presentation/patient_medical_cubit.dart';
import '../features/appointment/presentation/appointment_cubit.dart';
import '../features/odontogram/presentation/odontogram_cubit.dart';
import '../features/treatment_plan/presentation/treatment_plan_cubit.dart';
import '../features/clinical_session/presentation/clinical_session_cubit.dart';
import '../features/patient_file/presentation/patient_file_cubit.dart';
import '../features/billing/presentation/billing_cubit.dart';
import '../features/dashboard/presentation/dashboard_cubit.dart';
import '../features/audit/presentation/audit_cubit.dart';
import '../features/audit/presentation/audit_access_cubit.dart';

class DentaFlowApp extends StatelessWidget {
  const DentaFlowApp({
    required this.appearance,
    required this.router,
    this.auth,
    this.clinic,
    this.staff,
    this.schedule,
    this.patient,
    this.patientMedical,
    this.appointment,
    this.odontogram,
    this.treatmentPlan,
    this.clinicalSession,
    this.patientFile,
    this.billing,
    this.dashboard,
    this.audit,
    this.auditAccess,
    super.key,
  });
  final AppearanceCubit appearance;
  final GoRouter router;
  final AuthBloc? auth;
  final ClinicCubit? clinic;
  final StaffCubit? staff;
  final ScheduleCubit? schedule;
  final PatientCubit? patient;
  final PatientMedicalCubit? patientMedical;
  final AppointmentCubit? appointment;
  final OdontogramCubit? odontogram;
  final TreatmentPlanCubit? treatmentPlan;
  final ClinicalSessionCubit? clinicalSession;
  final PatientFileCubit? patientFile;
  final BillingCubit? billing;
  final DashboardCubit? dashboard;
  final AuditCubit? audit;
  final AuditAccessCubit? auditAccess;

  @override
  Widget build(BuildContext context) {
    final app = BlocProvider.value(
      value: appearance,
      child: BlocBuilder<AppearanceCubit, AppearanceState>(
        builder: (context, state) => MaterialApp.router(
          debugShowCheckedModeBanner: false,
          onGenerateTitle: (context) => AppLocalizations.of(context).appTitle,
          routerConfig: router,
          theme: AppTheme.light,
          darkTheme: AppTheme.dark,
          themeMode: switch (state.preferences.theme) {
            AppThemeMode.system => ThemeMode.system,
            AppThemeMode.light => ThemeMode.light,
            AppThemeMode.dark => ThemeMode.dark,
          },
          locale: switch (state.preferences.language) {
            AppLanguage.system => null,
            AppLanguage.english => const Locale('en'),
            AppLanguage.russian => const Locale('ru'),
            AppLanguage.arabic => const Locale('ar'),
          },
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          builder: (context, child) => auth == null
              ? child!
              : PrivacyBoundary(session: auth!.coordinator, child: child!),
        ),
      ),
    );
    final withAuth = auth == null
        ? app
        : BlocProvider.value(value: auth!, child: app);
    final withClinic = clinic == null
        ? withAuth
        : BlocProvider.value(value: clinic!, child: withAuth);
    final withStaff = staff == null
        ? withClinic
        : BlocProvider.value(value: staff!, child: withClinic);
    final withSchedule = schedule == null
        ? withStaff
        : BlocProvider.value(value: schedule!, child: withStaff);
    final withPatient = patient == null
        ? withSchedule
        : BlocProvider.value(value: patient!, child: withSchedule);
    final withPatientMedical = patientMedical == null
        ? withPatient
        : BlocProvider.value(value: patientMedical!, child: withPatient);
    final withAppointment = appointment == null
        ? withPatientMedical
        : BlocProvider.value(value: appointment!, child: withPatientMedical);
    final withOdontogram = odontogram == null
        ? withAppointment
        : BlocProvider.value(value: odontogram!, child: withAppointment);
    final withTreatmentPlan = treatmentPlan == null
        ? withOdontogram
        : BlocProvider.value(value: treatmentPlan!, child: withOdontogram);
    final withClinicalSession = clinicalSession == null
        ? withTreatmentPlan
        : BlocProvider.value(value: clinicalSession!, child: withTreatmentPlan);
    final withPatientFile = patientFile == null
        ? withClinicalSession
        : BlocProvider.value(value: patientFile!, child: withClinicalSession);
    final withBilling = billing == null
        ? withPatientFile
        : BlocProvider.value(value: billing!, child: withPatientFile);
    final withDashboard = dashboard == null
        ? withBilling
        : BlocProvider.value(value: dashboard!, child: withBilling);
    final withAudit = audit == null
        ? withDashboard
        : BlocProvider.value(value: audit!, child: withDashboard);
    return auditAccess == null
        ? withAudit
        : BlocProvider.value(value: auditAccess!, child: withAudit);
  }
}

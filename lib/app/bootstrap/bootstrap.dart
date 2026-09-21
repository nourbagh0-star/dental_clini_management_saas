import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';

import '../../core/config/app_config.dart';
import '../../core/auth/email_confirmation_link.dart';
import '../router/app_router.dart';
import '../theme/appearance_cubit.dart';
import 'dependencies.dart';
import '../../core/auth/session_coordinator.dart';
import '../../features/auth/domain/auth_models.dart';
import '../../features/auth/presentation/bloc/auth_bloc.dart';
import '../../features/clinic/presentation/clinic_cubit.dart';
import '../../features/clinic/presentation/device_time_zone.dart';
import '../../features/staff/presentation/pending_invitation_token.dart';
import '../../features/staff/presentation/staff_cubit.dart';
import '../../features/schedule/presentation/schedule_cubit.dart';
import '../../features/patient/presentation/patient_cubit.dart';
import '../../features/patient/presentation/patient_medical_cubit.dart';
import '../../features/appointment/presentation/appointment_cubit.dart';
import '../../features/odontogram/presentation/odontogram_cubit.dart';
import '../../features/treatment_plan/presentation/treatment_plan_cubit.dart';
import '../../features/clinical_session/presentation/clinical_session_cubit.dart';
import '../../features/patient_file/presentation/patient_file_cubit.dart';
import '../../features/billing/presentation/billing_cubit.dart';
import '../../features/dashboard/presentation/dashboard_cubit.dart';
import '../../features/audit/presentation/audit_cubit.dart';
import '../../features/audit/presentation/audit_access_cubit.dart';

class AppRuntime {
  AppRuntime(
    this.dependencies,
    this.appearance,
    this.router,
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
  );
  final GetIt dependencies;
  final AppearanceCubit appearance;
  final GoRouter router;
  final AuthBloc auth;
  final ClinicCubit clinic;
  final StaffCubit staff;
  final ScheduleCubit schedule;
  final PatientCubit patient;
  final PatientMedicalCubit patientMedical;
  final AppointmentCubit appointment;
  final OdontogramCubit odontogram;
  final TreatmentPlanCubit treatmentPlan;
  final ClinicalSessionCubit clinicalSession;
  final PatientFileCubit patientFile;
  final BillingCubit billing;
  final DashboardCubit dashboard;
  final AuditCubit audit;
  final AuditAccessCubit auditAccess;

  Future<void> dispose() async {
    router.dispose();
    await auth.close();
    await staff.close();
    await schedule.close();
    await patient.close();
    await patientMedical.close();
    await appointment.close();
    await odontogram.close();
    await treatmentPlan.close();
    await clinicalSession.close();
    await patientFile.close();
    await billing.close();
    await dashboard.close();
    await audit.close();
    await auditAccess.close();
    await appearance.close();
    await dependencies.reset();
  }
}

Future<AppRuntime> bootstrap({AppConfig? config}) async {
  final confirmationToken = takeEmailConfirmationLink();
  final dependencies = GetIt.asNewInstance();
  try {
    final settings = config ?? AppConfig.fromEnvironment();
    configureDependencies(dependencies, settings);
    final appearance = dependencies<AppearanceCubit>();
    await appearance.load();
    final session = dependencies<SessionCoordinator>();
    final isRecovery =
        confirmationToken != null &&
        (confirmationToken.contains('type=recovery') ||
            confirmationToken.contains('recovery'));
    await session.run(
      confirmationToken == null
          ? AuthAction.restore
          : isRecovery
          ? AuthAction.recoveryLink
          : AuthAction.confirmEmailLink,
      AuthInput(secret: confirmationToken ?? ''),
    );
    final auth = dependencies<AuthBloc>();
    final clinic = dependencies<ClinicCubit>();
    final staff = dependencies<StaffCubit>();
    final schedule = dependencies<ScheduleCubit>();
    final patient = dependencies<PatientCubit>();
    final patientMedical = dependencies<PatientMedicalCubit>();
    final appointment = dependencies<AppointmentCubit>();
    final odontogram = dependencies<OdontogramCubit>();
    final treatmentPlan = dependencies<TreatmentPlanCubit>();
    final clinicalSession = dependencies<ClinicalSessionCubit>();
    final patientFile = dependencies<PatientFileCubit>();
    final billing = dependencies<BillingCubit>();
    final dashboard = dependencies<DashboardCubit>();
    final audit = dependencies<AuditCubit>();
    final auditAccess = dependencies<AuditAccessCubit>();
    return AppRuntime(
      dependencies,
      appearance,
      AppRouter.create(
        session: session,
        deviceTimeZone: dependencies<DeviceTimeZone>(),
        pendingInvitation: dependencies<PendingInvitationToken>(),
        initialLocation: isRecovery ? '/reset-password' : '/login',
      ),
      auth,
      clinic,
      staff,
      schedule,
      patient,
      patientMedical,
      appointment,
      odontogram,
      treatmentPlan,
      clinicalSession,
      patientFile,
      billing,
      dashboard,
      audit,
      auditAccess,
    );
  } on Object {
    await dependencies.reset();
    rethrow;
  }
}

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format width=80

// **************************************************************************
// InjectableConfigGenerator
// **************************************************************************

// ignore_for_file: type=lint
// coverage:ignore-file

// ignore_for_file: no_leading_underscores_for_library_prefixes

import 'package:dental_clini_management_saas/app/bootstrap/backend_module.dart'
    as _i500;
import 'package:dental_clini_management_saas/app/theme/appearance_cubit.dart'
    as _i256;
import 'package:dental_clini_management_saas/core/auth/server_session.dart'
    as _i308;
import 'package:dental_clini_management_saas/core/auth/session_coordinator.dart'
    as _i72;
import 'package:dental_clini_management_saas/core/config/app_config.dart'
    as _i253;
import 'package:dental_clini_management_saas/core/network/dio_client.dart'
    as _i772;
import 'package:dental_clini_management_saas/core/network/session_token_provider.dart'
    as _i805;
import 'package:dental_clini_management_saas/core/network/supabase_connection.dart'
    as _i298;
import 'package:dental_clini_management_saas/core/storage/active_clinic_store.dart'
    as _i1008;
import 'package:dental_clini_management_saas/core/storage/auth_session_store.dart'
    as _i489;
import 'package:dental_clini_management_saas/core/storage/preferences_store.dart'
    as _i630;
import 'package:dental_clini_management_saas/features/appointment/data/appointment_data_source.dart'
    as _i471;
import 'package:dental_clini_management_saas/features/appointment/data/supabase_appointment_data_source.dart'
    as _i759;
import 'package:dental_clini_management_saas/features/appointment/data/supabase_appointment_repository.dart'
    as _i163;
import 'package:dental_clini_management_saas/features/appointment/domain/appointment_repository.dart'
    as _i783;
import 'package:dental_clini_management_saas/features/appointment/presentation/appointment_cubit.dart'
    as _i257;
import 'package:dental_clini_management_saas/features/audit/data/audit_data_source.dart'
    as _i50;
import 'package:dental_clini_management_saas/features/audit/data/supabase_audit_data_source.dart'
    as _i962;
import 'package:dental_clini_management_saas/features/audit/data/supabase_audit_repository.dart'
    as _i574;
import 'package:dental_clini_management_saas/features/audit/domain/audit_repository.dart'
    as _i1022;
import 'package:dental_clini_management_saas/features/audit/presentation/audit_access_cubit.dart'
    as _i550;
import 'package:dental_clini_management_saas/features/audit/presentation/audit_cubit.dart'
    as _i977;
import 'package:dental_clini_management_saas/features/auth/data/supabase_auth_data_source.dart'
    as _i413;
import 'package:dental_clini_management_saas/features/auth/data/supabase_auth_repository.dart'
    as _i197;
import 'package:dental_clini_management_saas/features/auth/domain/auth_repository.dart'
    as _i776;
import 'package:dental_clini_management_saas/features/auth/presentation/bloc/auth_bloc.dart'
    as _i338;
import 'package:dental_clini_management_saas/features/billing/data/billing_data_source.dart'
    as _i1071;
import 'package:dental_clini_management_saas/features/billing/data/supabase_billing_data_source.dart'
    as _i690;
import 'package:dental_clini_management_saas/features/billing/data/supabase_billing_repository.dart'
    as _i942;
import 'package:dental_clini_management_saas/features/billing/domain/billing_repository.dart'
    as _i35;
import 'package:dental_clini_management_saas/features/billing/presentation/billing_cubit.dart'
    as _i223;
import 'package:dental_clini_management_saas/features/clinic/data/supabase_clinic_data_source.dart'
    as _i463;
import 'package:dental_clini_management_saas/features/clinic/data/supabase_clinic_repository.dart'
    as _i413;
import 'package:dental_clini_management_saas/features/clinic/domain/clinic_repository.dart'
    as _i618;
import 'package:dental_clini_management_saas/features/clinic/presentation/clinic_cubit.dart'
    as _i182;
import 'package:dental_clini_management_saas/features/clinic/presentation/device_time_zone.dart'
    as _i450;
import 'package:dental_clini_management_saas/features/clinical_session/data/clinical_session_data_source.dart'
    as _i666;
import 'package:dental_clini_management_saas/features/clinical_session/data/supabase_clinical_session_data_source.dart'
    as _i1052;
import 'package:dental_clini_management_saas/features/clinical_session/data/supabase_clinical_session_repository.dart'
    as _i57;
import 'package:dental_clini_management_saas/features/clinical_session/domain/clinical_session_repository.dart'
    as _i867;
import 'package:dental_clini_management_saas/features/clinical_session/presentation/clinical_session_cubit.dart'
    as _i888;
import 'package:dental_clini_management_saas/features/dashboard/data/dashboard_data_source.dart'
    as _i274;
import 'package:dental_clini_management_saas/features/dashboard/data/supabase_dashboard_data_source.dart'
    as _i313;
import 'package:dental_clini_management_saas/features/dashboard/data/supabase_dashboard_repository.dart'
    as _i50;
import 'package:dental_clini_management_saas/features/dashboard/domain/dashboard_repository.dart'
    as _i627;
import 'package:dental_clini_management_saas/features/dashboard/presentation/dashboard_cubit.dart'
    as _i534;
import 'package:dental_clini_management_saas/features/odontogram/data/odontogram_data_source.dart'
    as _i887;
import 'package:dental_clini_management_saas/features/odontogram/data/supabase_odontogram_data_source.dart'
    as _i133;
import 'package:dental_clini_management_saas/features/odontogram/data/supabase_odontogram_repository.dart'
    as _i235;
import 'package:dental_clini_management_saas/features/odontogram/domain/odontogram_repository.dart'
    as _i945;
import 'package:dental_clini_management_saas/features/odontogram/presentation/odontogram_cubit.dart'
    as _i935;
import 'package:dental_clini_management_saas/features/patient/data/patient_data_source.dart'
    as _i556;
import 'package:dental_clini_management_saas/features/patient/data/supabase_patient_data_source.dart'
    as _i855;
import 'package:dental_clini_management_saas/features/patient/data/supabase_patient_repository.dart'
    as _i275;
import 'package:dental_clini_management_saas/features/patient/domain/patient_repository.dart'
    as _i227;
import 'package:dental_clini_management_saas/features/patient/presentation/patient_cubit.dart'
    as _i952;
import 'package:dental_clini_management_saas/features/patient/presentation/patient_medical_cubit.dart'
    as _i502;
import 'package:dental_clini_management_saas/features/patient_file/data/patient_file_data_source.dart'
    as _i473;
import 'package:dental_clini_management_saas/features/patient_file/data/supabase_patient_file_data_source.dart'
    as _i154;
import 'package:dental_clini_management_saas/features/patient_file/data/supabase_patient_file_repository.dart'
    as _i69;
import 'package:dental_clini_management_saas/features/patient_file/data/supabase_tus_file_transfer_client.dart'
    as _i584;
import 'package:dental_clini_management_saas/features/patient_file/domain/file_transfer_client.dart'
    as _i721;
import 'package:dental_clini_management_saas/features/patient_file/domain/patient_file_repository.dart'
    as _i677;
import 'package:dental_clini_management_saas/features/patient_file/presentation/patient_file_cubit.dart'
    as _i622;
import 'package:dental_clini_management_saas/features/schedule/data/schedule_data_source.dart'
    as _i341;
import 'package:dental_clini_management_saas/features/schedule/data/supabase_schedule_data_source.dart'
    as _i1047;
import 'package:dental_clini_management_saas/features/schedule/data/supabase_schedule_repository.dart'
    as _i38;
import 'package:dental_clini_management_saas/features/schedule/domain/schedule_repository.dart'
    as _i938;
import 'package:dental_clini_management_saas/features/schedule/presentation/schedule_cubit.dart'
    as _i205;
import 'package:dental_clini_management_saas/features/staff/data/staff_data_source.dart'
    as _i536;
import 'package:dental_clini_management_saas/features/staff/data/supabase_staff_data_source.dart'
    as _i941;
import 'package:dental_clini_management_saas/features/staff/data/supabase_staff_repository.dart'
    as _i123;
import 'package:dental_clini_management_saas/features/staff/domain/staff_repository.dart'
    as _i880;
import 'package:dental_clini_management_saas/features/staff/presentation/pending_invitation_token.dart'
    as _i310;
import 'package:dental_clini_management_saas/features/staff/presentation/staff_cubit.dart'
    as _i674;
import 'package:dental_clini_management_saas/features/treatment_plan/data/supabase_treatment_plan_data_source.dart'
    as _i149;
import 'package:dental_clini_management_saas/features/treatment_plan/data/supabase_treatment_plan_repository.dart'
    as _i835;
import 'package:dental_clini_management_saas/features/treatment_plan/data/treatment_plan_data_source.dart'
    as _i219;
import 'package:dental_clini_management_saas/features/treatment_plan/domain/treatment_plan_repository.dart'
    as _i377;
import 'package:dental_clini_management_saas/features/treatment_plan/presentation/treatment_plan_cubit.dart'
    as _i802;
import 'package:get_it/get_it.dart' as _i174;
import 'package:injectable/injectable.dart' as _i526;

extension GetItInjectableX on _i174.GetIt {
  // initializes the registration of main-scope dependencies inside of GetIt
  _i174.GetIt init({
    String? environment,
    _i526.EnvironmentFilter? environmentFilter,
  }) {
    final gh = _i526.GetItHelper(this, environment, environmentFilter);
    final backendModule = _$BackendModule();
    gh.lazySingleton<_i310.PendingInvitationToken>(
      () => _i310.PendingInvitationToken(),
    );
    gh.lazySingleton<_i630.PreferencesStore>(
      () => _i630.LocalPreferencesStore(),
    );
    gh.lazySingleton<_i450.DeviceTimeZone>(() => _i450.FlutterDeviceTimeZone());
    gh.lazySingleton<_i1008.ActiveClinicStore>(
      () => _i1008.LocalActiveClinicStore(),
    );
    gh.lazySingleton<_i489.AuthSessionStore>(
      () => backendModule.sessionStore(gh<_i253.AppConfig>()),
    );
    gh.factory<_i256.AppearanceCubit>(
      () => _i256.AppearanceCubit(gh<_i630.PreferencesStore>()),
    );
    gh.lazySingleton<_i298.SupabaseConnection>(
      () => _i298.SupabaseConnection(gh<_i253.AppConfig>()),
      dispose: (i) => i.dispose(),
    );
    gh.lazySingleton<_i413.SupabaseAuthDataSource>(
      () => _i413.SupabaseAuthDataSource(
        gh<_i298.SupabaseConnection>(),
        gh<_i253.AppConfig>(),
      ),
    );
    gh.lazySingleton<_i308.SupabaseServerSession>(
      () => _i308.SupabaseServerSession(
        gh<_i253.AppConfig>(),
        gh<_i298.SupabaseConnection>(),
      ),
      dispose: (i) => i.dispose(),
    );
    gh.lazySingleton<_i197.SupabaseAuthRepository>(
      () => _i197.SupabaseAuthRepository(
        gh<_i413.SupabaseAuthDataSource>(),
        gh<_i489.AuthSessionStore>(),
      ),
    );
    gh.lazySingleton<_i72.SessionCoordinator>(
      () => backendModule.coordinator(
        gh<_i197.SupabaseAuthRepository>(),
        gh<_i308.SupabaseServerSession>(),
        gh<_i253.AppConfig>(),
      ),
      dispose: _i500.disposeCoordinator,
    );
    gh.lazySingleton<_i776.AuthRepository>(
      () => backendModule.authRepository(gh<_i197.SupabaseAuthRepository>()),
    );
    gh.lazySingleton<_i805.SessionTokenProvider>(
      () => backendModule.sessionTokens(gh<_i72.SessionCoordinator>()),
    );
    gh.factory<_i338.AuthBloc>(
      () => _i338.AuthBloc(gh<_i72.SessionCoordinator>()),
    );
    gh.lazySingleton<_i721.FileTransferClient>(
      () => _i584.SupabaseTusFileTransferClient(
        gh<_i253.AppConfig>(),
        gh<_i805.SessionTokenProvider>(),
      ),
      dispose: (i) => i.dispose(),
    );
    gh.lazySingleton<_i772.DioClient>(
      () => _i772.DioClient(
        gh<_i253.AppConfig>(),
        gh<_i805.SessionTokenProvider>(),
      ),
      dispose: (i) => i.dispose(),
    );
    gh.lazySingleton<_i471.AppointmentDataSource>(
      () => _i759.SupabaseAppointmentDataSource(gh<_i772.DioClient>()),
    );
    gh.lazySingleton<_i50.AuditDataSource>(
      () => _i962.SupabaseAuditDataSource(gh<_i772.DioClient>()),
    );
    gh.lazySingleton<_i1071.BillingDataSource>(
      () => _i690.SupabaseBillingDataSource(gh<_i772.DioClient>()),
    );
    gh.lazySingleton<_i35.BillingRepository>(
      () => _i942.SupabaseBillingRepository(
        gh<_i1071.BillingDataSource>(),
        gh<_i253.AppConfig>(),
      ),
    );
    gh.lazySingleton<_i556.PatientDataSource>(
      () => _i855.SupabasePatientDataSource(gh<_i772.DioClient>()),
    );
    gh.lazySingleton<_i223.BillingCubit>(
      () => _i223.BillingCubit(gh<_i35.BillingRepository>()),
    );
    gh.lazySingleton<_i341.ScheduleDataSource>(
      () => _i1047.SupabaseScheduleDataSource(gh<_i772.DioClient>()),
    );
    gh.lazySingleton<_i536.StaffDataSource>(
      () => _i941.SupabaseStaffDataSource(gh<_i772.DioClient>()),
    );
    gh.lazySingleton<_i887.OdontogramDataSource>(
      () => _i133.SupabaseOdontogramDataSource(gh<_i772.DioClient>()),
    );
    gh.lazySingleton<_i1022.AuditRepository>(
      () => _i574.SupabaseAuditRepository(gh<_i50.AuditDataSource>()),
    );
    gh.lazySingleton<_i945.OdontogramRepository>(
      () =>
          _i235.SupabaseOdontogramRepository(gh<_i887.OdontogramDataSource>()),
    );
    gh.lazySingleton<_i666.ClinicalSessionDataSource>(
      () => _i1052.SupabaseClinicalSessionDataSource(gh<_i772.DioClient>()),
    );
    gh.lazySingleton<_i463.SupabaseClinicDataSource>(
      () => _i463.SupabaseClinicDataSource(gh<_i772.DioClient>()),
    );
    gh.lazySingleton<_i219.TreatmentPlanDataSource>(
      () => _i149.SupabaseTreatmentPlanDataSource(gh<_i772.DioClient>()),
    );
    gh.lazySingleton<_i550.AuditAccessCubit>(
      () => _i550.AuditAccessCubit(gh<_i1022.AuditRepository>()),
    );
    gh.lazySingleton<_i473.PatientFileDataSource>(
      () => _i154.SupabasePatientFileDataSource(gh<_i772.DioClient>()),
    );
    gh.lazySingleton<_i274.DashboardDataSource>(
      () => _i313.SupabaseDashboardDataSource(gh<_i772.DioClient>()),
    );
    gh.lazySingleton<_i935.OdontogramCubit>(
      () => _i935.OdontogramCubit(gh<_i945.OdontogramRepository>()),
    );
    gh.lazySingleton<_i977.AuditCubit>(
      () => _i977.AuditCubit(
        gh<_i1022.AuditRepository>(),
        gh<_i72.SessionCoordinator>(),
      ),
      dispose: (i) => i.close(),
    );
    gh.lazySingleton<_i618.ClinicRepository>(
      () =>
          _i413.SupabaseClinicRepository(gh<_i463.SupabaseClinicDataSource>()),
    );
    gh.lazySingleton<_i867.ClinicalSessionRepository>(
      () => _i57.SupabaseClinicalSessionRepository(
        gh<_i666.ClinicalSessionDataSource>(),
      ),
    );
    gh.lazySingleton<_i677.PatientFileRepository>(
      () => _i69.SupabasePatientFileRepository(
        gh<_i473.PatientFileDataSource>(),
        gh<_i721.FileTransferClient>(),
        gh<_i253.AppConfig>(),
      ),
    );
    gh.lazySingleton<_i783.AppointmentRepository>(
      () => _i163.SupabaseAppointmentRepository(
        gh<_i471.AppointmentDataSource>(),
      ),
    );
    gh.lazySingleton<_i377.TreatmentPlanRepository>(
      () => _i835.SupabaseTreatmentPlanRepository(
        gh<_i219.TreatmentPlanDataSource>(),
      ),
    );
    gh.lazySingleton<_i182.ClinicCubit>(
      () => _i182.ClinicCubit(
        gh<_i618.ClinicRepository>(),
        gh<_i1008.ActiveClinicStore>(),
        gh<_i72.SessionCoordinator>(),
      ),
      dispose: (i) => i.close(),
    );
    gh.lazySingleton<_i257.AppointmentCubit>(
      () => _i257.AppointmentCubit(gh<_i783.AppointmentRepository>()),
    );
    gh.lazySingleton<_i227.PatientRepository>(
      () => _i275.SupabasePatientRepository(gh<_i556.PatientDataSource>()),
    );
    gh.lazySingleton<_i938.ScheduleRepository>(
      () => _i38.SupabaseScheduleRepository(gh<_i341.ScheduleDataSource>()),
    );
    gh.lazySingleton<_i627.DashboardRepository>(
      () => _i50.SupabaseDashboardRepository(gh<_i274.DashboardDataSource>()),
    );
    gh.lazySingleton<_i880.StaffRepository>(
      () => _i123.SupabaseStaffRepository(gh<_i536.StaffDataSource>()),
    );
    gh.lazySingleton<_i622.PatientFileCubit>(
      () => _i622.PatientFileCubit(gh<_i677.PatientFileRepository>()),
    );
    gh.lazySingleton<_i888.ClinicalSessionCubit>(
      () => _i888.ClinicalSessionCubit(gh<_i867.ClinicalSessionRepository>()),
    );
    gh.lazySingleton<_i674.StaffCubit>(
      () => _i674.StaffCubit(gh<_i880.StaffRepository>()),
    );
    gh.lazySingleton<_i205.ScheduleCubit>(
      () => _i205.ScheduleCubit(gh<_i938.ScheduleRepository>()),
    );
    gh.lazySingleton<_i952.PatientCubit>(
      () => _i952.PatientCubit(gh<_i227.PatientRepository>()),
    );
    gh.lazySingleton<_i502.PatientMedicalCubit>(
      () => _i502.PatientMedicalCubit(gh<_i227.PatientRepository>()),
    );
    gh.lazySingleton<_i802.TreatmentPlanCubit>(
      () => _i802.TreatmentPlanCubit(gh<_i377.TreatmentPlanRepository>()),
    );
    gh.lazySingleton<_i534.DashboardCubit>(
      () => _i534.DashboardCubit(
        gh<_i627.DashboardRepository>(),
        gh<_i72.SessionCoordinator>(),
      ),
      dispose: (i) => i.close(),
    );
    return this;
  }
}

class _$BackendModule extends _i500.BackendModule {}

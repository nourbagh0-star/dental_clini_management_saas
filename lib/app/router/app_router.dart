import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:go_router/go_router.dart';

import '../../core/widgets/message_page.dart';
import '../bootstrap/preview_page.dart';
import '../localization/generated/app_localizations.dart';
import '../shell/workspace_shell.dart';
import '../../core/auth/session_coordinator.dart';
import '../../features/auth/domain/auth_models.dart';
import '../../features/auth/presentation/pages/auth_page.dart';
import '../../features/clinic/presentation/device_time_zone.dart';
import '../../features/clinic/presentation/pages/clinic_pages.dart';
import '../../features/staff/presentation/pages/staff_pages.dart';
import '../../features/staff/presentation/pending_invitation_token.dart';
import '../../features/schedule/presentation/pages/schedule_page.dart';
import '../../features/patient/presentation/pages/patient_pages.dart';
import '../../features/appointment/presentation/pages/appointment_pages.dart';
import '../../features/odontogram/presentation/pages/dental_chart_page.dart';
import '../../features/treatment_plan/presentation/pages/treatment_plan_page.dart';
import '../../features/treatment_plan/presentation/pages/procedure_catalogue_page.dart';
import '../../features/clinical_session/presentation/pages/clinical_session_pages.dart';
import '../../features/patient_file/presentation/pages/patient_file_pages.dart';
import '../../features/billing/presentation/pages/billing_page.dart';
import '../../features/dashboard/presentation/pages/dashboard_page.dart';
import '../../features/audit/presentation/pages/audit_log_page.dart';
import '../../features/audit/domain/audit_models.dart';
import '../../features/audit/presentation/audit_access_gate.dart';
import '../../features/settings/presentation/pages/settings_page.dart';

abstract final class AppRouter {
  static GoRouter create({
    String? initialLocation,
    SessionCoordinator? session,
    DeviceTimeZone? deviceTimeZone,
    PendingInvitationToken? pendingInvitation,
  }) => GoRouter(
    initialLocation: initialLocation,
    refreshListenable: session == null ? null : _AuthRefresh(session),
    redirect: (context, routerState) {
      if (session == null) return null;
      final uri = routerState.uri;
      final path = uri.path;
      if (path == '/invitations/accept' &&
          uri.fragment.isNotEmpty) {
        pendingInvitation?.captureFragment(uri.fragment);
        return '/invitations/accept';
      }

      // Intercept auth callback tokens from Supabase redirect (path, fragment, or query)
      String? authPayload;
      if (path.startsWith('/access_token=') ||
          path.startsWith('/error=') ||
          path.startsWith('/error_code=')) {
        authPayload = path.substring(1);
      } else if (uri.fragment.contains('access_token=') ||
          uri.fragment.contains('error=') ||
          uri.fragment.contains('error_code=')) {
        authPayload = uri.fragment;
      } else if (uri.query.contains('access_token=') ||
          uri.query.contains('error=') ||
          uri.query.contains('error_code=')) {
        authPayload = uri.query;
      }

      if (authPayload != null) {
        final isRecovery = authPayload.contains('type=recovery');
        final isError = authPayload.contains('error=') ||
            authPayload.contains('error_code=');

        if (isRecovery && !isError) {
          if (session.state.stage != AuthStage.recoveryAuthorized) {
            unawaited(session.run(
              AuthAction.recoveryLink,
              AuthInput(secret: authPayload),
            ));
          }
          return '/reset-password';
        } else if (isError) {
          if (isRecovery) {
            unawaited(session.run(
              AuthAction.recoveryLink,
              AuthInput(secret: authPayload),
            ));
            return '/forgot-password';
          } else {
            unawaited(session.run(
              AuthAction.confirmEmailLink,
              AuthInput(secret: authPayload),
            ));
            return '/login';
          }
        } else if (authPayload.contains('type=signup')) {
          unawaited(session.run(
            AuthAction.confirmEmailLink,
            AuthInput(secret: authPayload),
          ));
          return '/login';
        }
      }

      final stage = session.state.stage;
      if (stage == AuthStage.signedOut && path == '/') return '/login';
      final requiredPath = switch (stage) {
        AuthStage.restoring || AuthStage.restorationFailed => '/restoring',
        AuthStage.locked => '/locked',
        AuthStage.passwordChangeRequired => '/change-initial-password',
        AuthStage.recoveryAuthorized ||
        AuthStage.recoveryPending => '/reset-password',
        AuthStage.awaitingVerification => '/verify-email',
        AuthStage.signedIn => '/clinic-gate',
        AuthStage.signedOut => null,
      };
      if (stage == AuthStage.signedIn &&
          pendingInvitation?.value != null &&
          path != '/invitations/accept') {
        return '/invitations/accept';
      }
      if (stage == AuthStage.signedIn &&
          (const [
                '/clinic-gate',
                '/clinics/create',
                '/clinics/select',
                '/staff',
                '/schedule',
                '/patients',
                '/patients/new',
                '/appointments',
                '/appointments/new',
                '/procedures',
                '/billing',
                '/dashboard',
                '/audit',
                '/settings',
                '/invitations/accept',
              ].contains(path) ||
              path.startsWith('/patients/'))) {
        return null;
      }
      if (requiredPath != null) {
        return path == requiredPath ? null : requiredPath;
      }
      if (const [
        '/',
        '/login',
        '/register',
        '/forgot-password',
      ].contains(path)) {
        return null;
      }
      if (path == '/reset-password') {
        if (stage == AuthStage.recoveryAuthorized ||
            stage == AuthStage.recoveryPending) {
          return null;
        }
        return '/forgot-password';
      }
      if (const [
        '/locked',
        '/account-ready',
        '/change-initial-password',
        '/verify-email',
        '/restoring',
        '/clinic-gate',
        '/clinics/create',
        '/clinics/select',
        '/staff',
        '/schedule',
        '/patients',
        '/patients/new',
        '/appointments',
        '/appointments/new',
        '/procedures',
        '/billing',
        '/dashboard',
        '/audit',
        '/settings',
        '/invitations/accept',
      ].contains(path)) {
        return '/login';
      }
      return null;
    },
    routes: [
      GoRoute(path: '/', builder: (context, state) => const PreviewPage()),
      if (session != null) ...[
        for (final entry in const {
          '/login': AuthPageKind.login,
          '/register': AuthPageKind.register,
          '/verify-email': AuthPageKind.verify,
          '/forgot-password': AuthPageKind.forgot,
          '/reset-password': AuthPageKind.reset,
          '/change-initial-password': AuthPageKind.initialPassword,
          '/locked': AuthPageKind.locked,
          '/account-ready': AuthPageKind.account,
          '/restoring': AuthPageKind.restoring,
        }.entries)
          GoRoute(
            path: entry.key,
            builder: (_, state) =>
                AuthPage(entry.value, key: ValueKey(entry.key)),
          ),
        GoRoute(
          path: '/clinic-gate',
          builder: (context, state) => const ClinicGatePage(),
        ),
        ShellRoute(
          builder: (_, state, child) =>
              WorkspaceShell(location: state.uri.path, child: child),
          routes: [
            GoRoute(path: '/staff', builder: (_, state) => const StaffPage()),
            GoRoute(
              path: '/schedule',
              builder: (_, state) => const DoctorSchedulePage(),
            ),
            GoRoute(
              path: '/patients',
              builder: (_, state) => const PatientsPage(),
            ),
            GoRoute(
              path: '/patients/new',
              builder: (_, state) => const NewPatientPage(),
            ),
            GoRoute(
              path: '/patients/:id',
              builder: (_, state) => AuditAccessGate(
                intent: AuditAccessIntent.patientProfile,
                subjectId: state.pathParameters['id']!,
                child: PatientProfilePage(
                  patientId: state.pathParameters['id']!,
                ),
              ),
            ),
            GoRoute(
              path: '/patients/:id/medical',
              builder: (_, state) => AuditAccessGate(
                intent: AuditAccessIntent.medicalRecord,
                subjectId: state.pathParameters['id']!,
                child: PatientMedicalPage(
                  patientId: state.pathParameters['id']!,
                ),
              ),
            ),
            GoRoute(
              path: '/patients/:id/dental-chart',
              builder: (_, state) => AuditAccessGate(
                intent: AuditAccessIntent.odontogram,
                subjectId: state.pathParameters['id']!,
                child: DentalChartPage(patientId: state.pathParameters['id']!),
              ),
            ),
            GoRoute(
              path: '/patients/:id/treatment-plans',
              builder: (_, state) => AuditAccessGate(
                intent: AuditAccessIntent.treatmentPlan,
                subjectId: state.pathParameters['id']!,
                child: TreatmentPlanPage(
                  patientId: state.pathParameters['id']!,
                ),
              ),
            ),
            GoRoute(
              path: '/patients/:id/visits',
              builder: (_, state) => AuditAccessGate(
                intent: AuditAccessIntent.clinicalSessions,
                subjectId: state.pathParameters['id']!,
                child: ClinicalSessionsPage(
                  patientId: state.pathParameters['id']!,
                  initialAppointmentId:
                      state.uri.queryParameters['appointmentId'],
                ),
              ),
            ),
            GoRoute(
              path: '/patients/:id/files',
              builder: (_, state) => AuditAccessGate(
                intent: AuditAccessIntent.patientFiles,
                subjectId: state.pathParameters['id']!,
                child: PatientFilesPage(patientId: state.pathParameters['id']!),
              ),
            ),
            GoRoute(
              path: '/patients/:id/billing',
              builder: (_, state) =>
                  BillingPage(patientId: state.pathParameters['id']!),
            ),
            GoRoute(
              path: '/billing',
              builder: (_, state) => const BillingPage(),
            ),
            GoRoute(
              path: '/dashboard',
              builder: (_, state) => const DashboardPage(),
            ),
            GoRoute(
              path: '/audit',
              builder: (_, state) => const AuditLogPage(),
            ),
            GoRoute(
              path: '/procedures',
              builder: (_, state) => const ProcedureCataloguePage(),
            ),
            GoRoute(
              path: '/appointments',
              builder: (_, state) => const AppointmentCalendarPage(),
            ),
            GoRoute(
              path: '/appointments/new',
              builder: (_, state) => NewAppointmentPage(
                initialPatientId: state.uri.queryParameters['patientId'],
              ),
            ),
            GoRoute(
              path: '/settings',
              builder: (_, state) => const SettingsPage(),
            ),
          ],
        ),
        GoRoute(
          path: '/invitations/accept',
          builder: (_, state) =>
              InvitationAcceptPage(token: pendingInvitation?.value),
        ),
        GoRoute(
          path: '/clinics/select',
          builder: (context, state) => const ClinicSelectorPage(),
        ),
        GoRoute(
          path: '/clinics/create',
          builder: (context, state) =>
              CreateClinicPage(timeZone: deviceTimeZone!),
        ),
        GoRoute(
          path: '/auth/callback',
          builder: (context, state) => const AuthPage(
            AuthPageKind.reset,
            key: ValueKey('/reset-password'),
          ),
        ),
      ],
    ],
    errorBuilder: (context, state) {
      final raw = state.uri.toString();
      if (raw.contains('type=recovery') || raw.contains('access_token=')) {
        if (session != null &&
            session.state.stage != AuthStage.recoveryAuthorized) {
          final payload = state.uri.fragment.isNotEmpty
              ? state.uri.fragment
              : state.uri.path.startsWith('/')
              ? state.uri.path.substring(1)
              : state.uri.path;
          unawaited(
            session.run(AuthAction.recoveryLink, AuthInput(secret: payload)),
          );
        }
        return const AuthPage(
          AuthPageKind.reset,
          key: ValueKey('/reset-password'),
        );
      }
      final l10n = AppLocalizations.of(context);
      return MessagePage(
        title: l10n.notFoundTitle,
        message: l10n.notFoundBody,
        actionLabel: l10n.backHome,
        onAction: () => context.go('/'),
      );
    },
  );
}

class _AuthRefresh extends ChangeNotifier {
  _AuthRefresh(SessionCoordinator session) {
    _subscription = session.changes.listen(
      (_) => notifyListeners(),
      onDone: dispose,
    );
  }
  late final StreamSubscription<AuthViewState> _subscription;
  @override
  void dispose() {
    unawaited(_subscription.cancel());
    super.dispose();
  }
}

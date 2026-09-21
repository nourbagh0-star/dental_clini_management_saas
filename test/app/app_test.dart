import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:dental_clini_management_saas/app/app.dart';
import 'package:dental_clini_management_saas/app/bootstrap/startup_error_app.dart';
import 'package:dental_clini_management_saas/app/router/app_router.dart';
import 'package:dental_clini_management_saas/app/theme/appearance.dart';
import 'package:dental_clini_management_saas/app/theme/appearance_cubit.dart';

import '../support/fakes.dart';
import '../auth/auth_fakes.dart';
import 'package:dental_clini_management_saas/core/auth/session_coordinator.dart';
import 'package:dental_clini_management_saas/features/auth/domain/auth_models.dart';
import 'package:dental_clini_management_saas/features/auth/presentation/bloc/auth_bloc.dart';

void main() {
  testWidgets('root opens sign-in instead of the preview for the running app', (
    tester,
  ) async {
    final repository = TestAuthRepository();
    final session = SessionCoordinator(
      repository,
      repository,
      TestPrivacySignal(),
      enableTimer: false,
    );
    await session.run(AuthAction.restore, AuthInput());
    final auth = AuthBloc(session);
    final appearance = AppearanceCubit(MemoryPreferences());
    await appearance.change(language: AppLanguage.english);
    final router = AppRouter.create(initialLocation: '/', session: session);
    addTearDown(auth.close);
    addTearDown(router.dispose);
    addTearDown(appearance.close);
    await tester.pumpWidget(
      DentaFlowApp(appearance: appearance, router: router, auth: auth),
    );
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('auth-email')), findsOneWidget);
    expect(find.text('Your clinic, organized.'), findsNothing);
    await tester.pumpWidget(const SizedBox.shrink());
  });
  for (final width in [320.0, 800.0, 1440.0]) {
    testWidgets('demo shell fits width $width with large Russian text', (
      tester,
    ) async {
      tester.view.physicalSize = Size(width, 1000);
      tester.view.devicePixelRatio = 1;
      tester.platformDispatcher.textScaleFactorTestValue = 1.6;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
      final appearance = AppearanceCubit(MemoryPreferences());
      await appearance.change(language: AppLanguage.russian);
      final router = AppRouter.create(initialLocation: '/');
      addTearDown(appearance.close);
      addTearDown(router.dispose);
      await tester.pumpWidget(
        DentaFlowApp(appearance: appearance, router: router),
      );
      await tester.pumpAndSettle();
      expect(find.text('DentaFlow'), findsOneWidget);
      expect(find.text('Ваша клиника — в порядке.'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets(
    'language selection updates the shell and theme updates material',
    (tester) async {
      final store = MemoryPreferences();
      final appearance = AppearanceCubit(store);
      final router = AppRouter.create(initialLocation: '/');
      addTearDown(appearance.close);
      addTearDown(router.dispose);
      await tester.pumpWidget(
        DentaFlowApp(appearance: appearance, router: router),
      );
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.byKey(const ValueKey('language-system')));
      await tester.tap(find.byKey(const ValueKey('language-system')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Русский').last);
      await tester.pumpAndSettle();
      expect(find.text('Ваша клиника — в порядке.'), findsOneWidget);
      await appearance.change(theme: AppThemeMode.dark);
      await tester.pumpAndSettle();
      expect(
        Theme.of(tester.element(find.byType(Scaffold))).brightness,
        Brightness.dark,
      );
      expect(store.value, contains('russian'));
    },
  );

  testWidgets('Arabic selection uses right-to-left layout', (tester) async {
    final appearance = AppearanceCubit(MemoryPreferences());
    final router = AppRouter.create(initialLocation: '/');
    addTearDown(appearance.close);
    addTearDown(router.dispose);
    await appearance.change(language: AppLanguage.arabic);
    await tester.pumpWidget(
      DentaFlowApp(appearance: appearance, router: router),
    );
    await tester.pumpAndSettle();
    expect(
      Directionality.of(tester.element(find.byType(Scaffold))),
      TextDirection.rtl,
    );
    expect(find.text('عيادتك، منظمة.'), findsOneWidget);
  });

  testWidgets('unknown deep link shows a safe page and returns home', (
    tester,
  ) async {
    final appearance = AppearanceCubit(MemoryPreferences());
    await appearance.change(language: AppLanguage.english);
    final router = AppRouter.create(initialLocation: '/patients/private-id');
    addTearDown(appearance.close);
    addTearDown(router.dispose);
    await tester.pumpWidget(
      DentaFlowApp(appearance: appearance, router: router),
    );
    await tester.pumpAndSettle();
    expect(find.text('Page unavailable'), findsOneWidget);
    expect(find.textContaining('private-id'), findsNothing);
    await tester.tap(find.text('Back to workspace'));
    await tester.pumpAndSettle();
    expect(find.text('Your clinic, organized.'), findsOneWidget);
  });

  testWidgets('startup failure offers retry without exception details', (
    tester,
  ) async {
    var retries = 0;
    await tester.pumpWidget(
      StartupErrorApp(configurationError: true, onRetry: () => retries++),
    );
    await tester.pumpAndSettle();
    expect(find.text('Unable to open the workspace'), findsOneWidget);
    await tester.tap(find.text('Try again'));
    expect(retries, 1);
  });

  testWidgets('recovery callback link routes to password reset without Page unavailable', (
    tester,
  ) async {
    final repository = TestAuthRepository();
    final session = SessionCoordinator(
      repository,
      repository,
      TestPrivacySignal(),
      enableTimer: false,
    );
    await session.run(AuthAction.restore, AuthInput());
    final auth = AuthBloc(session);
    final appearance = AppearanceCubit(MemoryPreferences());
    await appearance.change(language: AppLanguage.english);
    final router = AppRouter.create(
      initialLocation: '/access_token=mock-token&type=recovery',
      session: session,
    );
    addTearDown(auth.close);
    addTearDown(router.dispose);
    addTearDown(appearance.close);
    await tester.pumpWidget(
      DentaFlowApp(appearance: appearance, router: router, auth: auth),
    );
    await tester.pumpAndSettle();
    expect(find.text('Page unavailable'), findsNothing);
    expect(find.text('Reset your password'), findsOneWidget);
  });

  testWidgets('expired recovery link safely routes to sign-in or forgot-password without Page unavailable', (
    tester,
  ) async {
    final repository = TestAuthRepository();
    final session = SessionCoordinator(
      repository,
      repository,
      TestPrivacySignal(),
      enableTimer: false,
    );
    await session.run(AuthAction.restore, AuthInput());
    final auth = AuthBloc(session);
    final appearance = AppearanceCubit(MemoryPreferences());
    await appearance.change(language: AppLanguage.english);
    final router = AppRouter.create(
      initialLocation: '/error=access_denied&error_code=otp_expired&type=recovery',
      session: session,
    );
    addTearDown(auth.close);
    addTearDown(router.dispose);
    addTearDown(appearance.close);
    await tester.pumpWidget(
      DentaFlowApp(appearance: appearance, router: router, auth: auth),
    );
    await tester.pumpAndSettle();
    expect(find.text('Page unavailable'), findsNothing);
  });
}


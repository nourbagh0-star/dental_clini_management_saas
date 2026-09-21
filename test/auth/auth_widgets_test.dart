import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:dental_clini_management_saas/app/localization/generated/app_localizations.dart';
import 'package:dental_clini_management_saas/app/theme/app_theme.dart';
import 'package:dental_clini_management_saas/app/theme/appearance_cubit.dart';
import 'package:dental_clini_management_saas/core/auth/session_coordinator.dart';
import 'package:dental_clini_management_saas/features/auth/domain/auth_models.dart';
import 'package:dental_clini_management_saas/features/auth/domain/auth_validation.dart';
import 'package:dental_clini_management_saas/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:dental_clini_management_saas/features/auth/presentation/pages/auth_page.dart';
import '../support/fakes.dart';
import 'auth_fakes.dart';

Widget _page(AuthPageKind kind) {
  final repository = TestAuthRepository();
  final session = SessionCoordinator(
    repository,
    repository,
    TestPrivacySignal(),
    enableTimer: false,
  );
  return MultiBlocProvider(
    providers: [
      BlocProvider.value(value: AuthBloc(session)),
      BlocProvider.value(value: AppearanceCubit(MemoryPreferences())),
    ],
    child: MaterialApp(
      theme: AppTheme.light,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      locale: const Locale('ru'),
      home: AuthPage(kind),
    ),
  );
}

Widget _pageWithSession(AuthPageKind kind, SessionCoordinator session) {
  return MultiBlocProvider(
    providers: [
      BlocProvider.value(value: AuthBloc(session)),
      BlocProvider.value(value: AppearanceCubit(MemoryPreferences())),
    ],
    child: MaterialApp(
      theme: AppTheme.light,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      locale: const Locale('en'),
      home: AuthPage(kind),
    ),
  );
}

void main() {
  testWidgets('recovery waits for an email link without code entry', (
    tester,
  ) async {
    await tester.pumpWidget(_page(AuthPageKind.reset));
    await tester.pump();
    expect(find.byKey(const ValueKey('auth-code')), findsNothing);
    expect(find.byKey(const ValueKey('auth-password')), findsNothing);
    expect(find.text('Отправить ссылку повторно'), findsOneWidget);
  });
  testWidgets(
    'verification screen offers a link resend and sign-in without code entry',
    (tester) async {
      await tester.pumpWidget(_page(AuthPageKind.verify));
      await tester.pump();
      expect(find.byKey(const ValueKey('auth-code')), findsNothing);
      expect(find.byKey(const ValueKey('auth-password')), findsNothing);
      expect(find.text('Отправить ссылку повторно'), findsOneWidget);
    },
  );
  test(
    'passwords preserve spaces and code validation rejects malformed input',
    () {
      expect(AuthValidation.password('a long passphrase with spaces'), isTrue);
      expect(AuthValidation.password('short'), isFalse);
      expect(AuthValidation.code('123456'), isTrue);
      expect(AuthValidation.code('12345 '), isFalse);
      expect(AuthValidation.email('user@example.test'), isTrue);
      expect(AuthValidation.email('user@@example.test'), isFalse);
    },
  );

  for (final width in [320.0, 800.0, 1440.0]) {
    testWidgets('authentication forms fit Russian large text at $width', (
      tester,
    ) async {
      tester.view.physicalSize = Size(width, 1000);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      for (final kind in [
        AuthPageKind.login,
        AuthPageKind.register,
        AuthPageKind.verify,
        AuthPageKind.forgot,
        AuthPageKind.reset,
        AuthPageKind.initialPassword,
        AuthPageKind.locked,
        AuthPageKind.account,
      ]) {
        await tester.pumpWidget(
          MediaQuery(
            data: const MediaQueryData(textScaler: TextScaler.linear(1.6)),
            child: _page(kind),
          ),
        );
        await tester.pump();
        expect(tester.takeException(), isNull);
      }
    });
  }

  testWidgets('password entry retains spaces and invalid email blocks submit', (
    tester,
  ) async {
    await tester.pumpWidget(_page(AuthPageKind.login));
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey('auth-submit')));
    await tester.pump();
    expect(find.text('Введите корректный адрес почты.'), findsOneWidget);
    await tester.enterText(
      find.byKey(const ValueKey('auth-email')),
      'demo@example.test',
    );
    await tester.enterText(
      find.byKey(const ValueKey('auth-password')),
      'passphrase with spaces',
    );
    expect(find.text('passphrase with spaces'), findsOneWidget);
  });

  testWidgets('registration failure is announced where the user can see it', (
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
    repository.failure = AuthIssue.network;
    await tester.pumpWidget(_pageWithSession(AuthPageKind.register, session));
    await tester.pump();
    await tester.enterText(
      find.byKey(const ValueKey('auth-email')),
      'owner@example.test',
    );
    await tester.enterText(
      find.byKey(const ValueKey('auth-password')),
      'a valid demo password',
    );
    await tester.enterText(
      find.byKey(const ValueKey('auth-confirm')),
      'a valid demo password',
    );
    await tester.ensureVisible(find.byKey(const ValueKey('auth-submit')));
    await tester.tap(find.byKey(const ValueKey('auth-submit')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.byType(SnackBar), findsOneWidget);
    expect(
      find.text('Connection unavailable. Please try again.'),
      findsWidgets,
    );
  });
}

import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:dental_clini_management_saas/core/auth/server_session.dart';
import 'package:dental_clini_management_saas/core/auth/session_coordinator.dart';
import 'package:dental_clini_management_saas/features/auth/domain/auth_models.dart';
import 'package:dental_clini_management_saas/features/auth/presentation/bloc/auth_bloc.dart';
import 'auth_fakes.dart';

void main() {
  late TestAuthRepository repository;
  late TestPrivacySignal signals;
  late TestServerSession serverSession;
  late SessionCoordinator session;
  late DateTime now;
  setUp(() {
    repository = TestAuthRepository();
    signals = TestPrivacySignal();
    serverSession = TestServerSession();
    now = DateTime.utc(2026);
    session = SessionCoordinator(
      repository,
      repository,
      signals,
      serverSession: serverSession,
      now: () => now,
    );
  });
  tearDown(() => session.dispose());
  test(
    'temporary-password sign-in gates clinic access and requires a fresh login',
    () async {
      await session.run(AuthAction.restore, AuthInput());
      serverSession.unlockFailure = ServerSessionIssue.passwordChangeRequired;
      await session.run(
        AuthAction.login,
        AuthInput(email: 'staff@example.test', secret: 'temporary password'),
      );
      expect(session.state.stage, AuthStage.passwordChangeRequired);
      expect(session.accessToken, isNull);
      expect(repository.logouts, 0);
      await session.run(
        AuthAction.changeInitialPassword,
        AuthInput(secret: 'new staff passphrase'),
      );
      expect(serverSession.passwordCompletions, 1);
      expect(repository.logouts, 1);
      expect(session.state.stage, AuthStage.signedOut);
      expect(session.accessToken, isNull);
    },
  );
  test('failed password update preserves the access gate', () async {
    await session.run(AuthAction.restore, AuthInput());
    serverSession.unlockFailure = ServerSessionIssue.passwordChangeRequired;
    await session.run(
      AuthAction.login,
      AuthInput(email: 'staff@example.test', secret: 'temporary password'),
    );
    repository.failure = AuthIssue.network;
    await session.run(
      AuthAction.changeInitialPassword,
      AuthInput(secret: 'new staff passphrase'),
    );
    expect(session.state.stage, AuthStage.passwordChangeRequired);
    expect(session.accessToken, isNull);
    expect(serverSession.passwordCompletions, 0);
  });
  test('recovery link allows password reset without clinic access', () async {
    await session.run(AuthAction.recoveryLink, AuthInput(secret: 'callback'));
    expect(session.state.stage, AuthStage.recoveryAuthorized);
    expect(session.accessToken, isNull);
    expect(serverSession.unlocks, 0);
    expect(serverSession.restores, 0);
    await session.run(
      AuthAction.resetPassword,
      AuthInput(secret: 'new passphrase'),
    );
    expect(session.state.stage, AuthStage.signedOut);
    expect(session.state.issue, AuthIssue.passwordChanged);
  });
  test('invalid recovery link remains signed out', () async {
    repository.failure = AuthIssue.invalidConfirmationLink;
    await session.run(AuthAction.recoveryLink, AuthInput(secret: 'expired'));
    expect(session.state.stage, AuthStage.signedOut);
    expect(session.accessToken, isNull);
  });
  test(
    'email link confirms without restoring or opening a clinic session',
    () async {
      repository.restored = TestAuthRepository.user;
      await session.run(
        AuthAction.confirmEmailLink,
        AuthInput(secret: 'callback'),
      );
      expect(session.state.stage, AuthStage.signedOut);
      expect(session.state.issue, AuthIssue.emailConfirmed);
      expect(session.accessToken, isNull);
      expect(repository.clears, 1);
      expect(serverSession.unlocks, 0);
      expect(serverSession.restores, 0);
    },
  );
  test(
    'expired email link returns to sign-in without an authenticated session',
    () async {
      repository.failure = AuthIssue.invalidConfirmationLink;
      await session.run(
        AuthAction.confirmEmailLink,
        AuthInput(secret: 'expired'),
      );
      expect(session.state.stage, AuthStage.signedOut);
      expect(session.state.issue, AuthIssue.invalidConfirmationLink);
      expect(session.accessToken, isNull);
    },
  );
  Future<void> login() async {
    await session.run(AuthAction.restore, AuthInput());
    await session.run(
      AuthAction.login,
      AuthInput(email: 'demo@example.test', secret: 'test passphrase'),
    );
  }

  test(
    'restored credentials require unlock and expose no application token',
    () async {
      repository.restored = TestAuthRepository.user;
      await session.run(AuthAction.restore, AuthInput());
      expect(session.state.stage, AuthStage.locked);
      expect(session.accessToken, isNull);
      expect(signals.sent, contains('lock'));
      await session.run(AuthAction.unlock, AuthInput(secret: 'password'));
      expect(session.accessToken, isNotNull);
    },
  );
  test(
    'three-day deadline is evaluated before a late input can reset it',
    () async {
      await login();
      now = now.add(const Duration(days: 3));
      session.activity();
      expect(session.state.stage, AuthStage.locked);
      expect(session.accessToken, isNull);
      expect(repository.logouts, 0);
    },
  );
  test('human activity extends deadline, refresh does not', () async {
    await login();
    now = now.add(const Duration(days: 2));
    session.activity();
    now = now.add(const Duration(days: 2));
    await session.refreshAccessToken();
    expect(session.state.stage, AuthStage.signedIn);
    now = now.add(const Duration(days: 1));
    session.checkInactivity();
    expect(session.state.stage, AuthStage.locked);
  });
  test('72 hours minus one second remains signed in', () async {
    await login();
    now = now.add(const Duration(days: 3) - Duration(seconds: 1));
    session.checkInactivity();
    expect(session.state.stage, AuthStage.signedIn);
    now = now.add(const Duration(seconds: 1));
    session.checkInactivity();
    expect(session.state.stage, AuthStage.locked);
  });
  test('background masks data and resume rechecks elapsed time', () async {
    await login();
    session.background();
    expect(session.state.hidden, isTrue);
    expect(session.state.stage, AuthStage.signedIn);
    expect(session.accessToken, isNull);
    now = now.add(const Duration(days: 3, seconds: 1));
    await session.resume();
    expect(session.state.hidden, isFalse);
    expect(session.state.stage, AuthStage.locked);
  });
  test('resume asserts the server lease before revealing data', () async {
    await login();
    session.background();
    final pending = session.resume();
    expect(session.state.hidden, isTrue);
    await pending;
    expect(serverSession.restores, 1);
    expect(session.state.hidden, isFalse);
    expect(session.state.stage, AuthStage.signedIn);
  });
  test('resume failure stays locked and reveals no token', () async {
    await login();
    session.background();
    serverSession.restoreFailure = ServerSessionIssue.unavailable;
    await session.resume();
    expect(session.state.stage, AuthStage.locked);
    expect(session.state.hidden, isFalse);
    expect(session.accessToken, isNull);
  });
  test('web policy restores a valid server lease without a password', () async {
    await session.dispose();
    repository.restored = TestAuthRepository.user;
    signals = TestPrivacySignal();
    serverSession = TestServerSession();
    session = SessionCoordinator(
      repository,
      repository,
      signals,
      serverSession: serverSession,
      now: () => now,
      restoreServerSession: true,
    );
    await session.run(AuthAction.restore, AuthInput());
    expect(serverSession.restores, 1);
    expect(serverSession.unlocks, 0);
    expect(session.state.stage, AuthStage.signedIn);
    expect(session.accessToken, isNotNull);
  });
  test(
    'web restoration fails closed when the server lease is unavailable',
    () async {
      await session.dispose();
      repository.restored = TestAuthRepository.user;
      signals = TestPrivacySignal();
      serverSession = TestServerSession()
        ..restoreFailure = ServerSessionIssue.locked;
      session = SessionCoordinator(
        repository,
        repository,
        signals,
        serverSession: serverSession,
        now: () => now,
        restoreServerSession: true,
      );
      await session.run(AuthAction.restore, AuthInput());
      expect(session.state.stage, AuthStage.locked);
      expect(session.accessToken, isNull);
    },
  );
  test(
    'logout racing an in-flight login never restores authenticated UI',
    () async {
      await session.run(AuthAction.restore, AuthInput());
      repository.gate = Completer<void>();
      final pending = session.run(
        AuthAction.login,
        AuthInput(secret: 'secret'),
      );
      await Future<void>.delayed(Duration.zero);
      final out = session.logout();
      expect(session.accessToken, isNull);
      repository.gate!.complete();
      await pending;
      await out;
      expect(session.state.stage, AuthStage.signedOut);
      expect(repository.token, isNull);
      expect(repository.logouts, 1);
    },
  );
  test(
    'simultaneous refresh shares work; a lock blocks the eventual result',
    () async {
      await login();
      repository.refreshGate = Completer<void>();
      final a = session.refreshAccessToken();
      final b = session.refreshAccessToken();
      await Future<void>.delayed(Duration.zero);
      session.lock();
      repository.refreshGate!.complete();
      expect(await a, isNull);
      expect(await b, isNull);
      expect(repository.refreshes, 1);
    },
  );
  test(
    'restore outage preserves blocked retry; invalid credentials clear storage',
    () async {
      repository.failure = AuthIssue.network;
      await session.run(AuthAction.restore, AuthInput());
      expect(session.state.stage, AuthStage.restorationFailed);
      expect(repository.clears, 0);
      repository.failure = AuthIssue.credentials;
      await session.run(AuthAction.restore, AuthInput());
      expect(session.state.stage, AuthStage.signedOut);
      expect(repository.clears, 1);
    },
  );
  test(
    'recovery cannot open account or reset before code verification',
    () async {
      await session.run(AuthAction.restore, AuthInput());
      await session.run(
        AuthAction.resetPassword,
        AuthInput(secret: 'new password'),
      );
      expect(session.state.stage, AuthStage.signedOut);
      await session.run(
        AuthAction.recover,
        AuthInput(email: 'demo@example.test'),
      );
      await session.run(AuthAction.verifyRecovery, AuthInput(secret: '123456'));
      expect(session.state.stage, AuthStage.recoveryAuthorized);
      expect(session.accessToken, isNull);
      await session.run(
        AuthAction.resetPassword,
        AuthInput(secret: 'new password'),
      );
      expect(session.state.stage, AuthStage.signedOut);
      expect(session.state.issue, AuthIssue.passwordChanged);
    },
  );
  test(
    'password changed with failed revocation is an explicit partial outcome',
    () async {
      await session.run(AuthAction.restore, AuthInput());
      await session.run(
        AuthAction.recover,
        AuthInput(email: 'demo@example.test'),
      );
      await session.run(AuthAction.verifyRecovery, AuthInput(secret: '123456'));
      repository.failure = AuthIssue.passwordChangedRevocationUnconfirmed;
      await session.run(
        AuthAction.resetPassword,
        AuthInput(secret: 'replacement'),
      );
      expect(session.state.stage, AuthStage.signedOut);
      expect(
        session.state.issue,
        AuthIssue.passwordChangedRevocationUnconfirmed,
      );
    },
  );
  test(
    'cross-tab lock/logout does not rebroadcast or reveal credentials',
    () async {
      await login();
      signals.controller.add('lock');
      expect(session.state.stage, AuthStage.locked);
      expect(signals.sent, isEmpty);
      signals.controller.add('logout');
      await Future<void>.delayed(Duration.zero);
      expect(session.state.stage, AuthStage.signedOut);
      expect(signals.sent, isEmpty);
    },
  );
  test(
    'logout clears client access even when remote revocation fails',
    () async {
      await login();
      repository.failure = AuthIssue.network;
      await session.logout();
      expect(session.state.stage, AuthStage.signedOut);
      expect(session.accessToken, isNull);
      expect(session.state.issue, isNotNull);
    },
  );
  test('Bloc command inputs are redacted and consumed', () async {
    await session.run(AuthAction.restore, AuthInput());
    final bloc = AuthBloc(session);
    addTearDown(bloc.close);
    final input = AuthInput(
      email: 'private@example.test',
      secret: 'private password',
    );
    final event = AuthRequested(AuthAction.login, input);
    expect(event.toString(), isNot(contains('private')));
    expect(input.toString(), isNot(contains('private')));
    final done = bloc.stream.firstWhere((s) => s.stage == AuthStage.signedIn);
    bloc.add(event);
    await done;
    expect(input.takeSecret(), isEmpty);
  });
}

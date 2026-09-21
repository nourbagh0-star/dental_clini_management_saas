import 'dart:async';
import 'package:dental_clini_management_saas/core/auth/privacy_signal.dart';
import 'package:dental_clini_management_saas/core/auth/server_session.dart';
import 'package:dental_clini_management_saas/core/network/session_token_provider.dart';
import 'package:dental_clini_management_saas/features/auth/domain/auth_models.dart';
import 'package:dental_clini_management_saas/features/auth/domain/auth_repository.dart';

class TestPrivacySignal implements PrivacySignal {
  final controller = StreamController<String>.broadcast(sync: true);
  final sent = <String>[];
  @override
  Stream<String> get messages => controller.stream;
  @override
  void send(String message) => sent.add(message);
  @override
  Future<void> dispose() => controller.close();
}

class TestServerSession implements ServerSession {
  ServerSessionIssue? unlockFailure;
  int passwordCompletions = 0;
  @override
  Future<void> completePasswordSetup() async => passwordCompletions++;
  ServerSessionIssue? restoreFailure;
  int restores = 0;
  int unlocks = 0;
  int renewals = 0;
  int locks = 0;
  int clears = 0;

  @override
  Future<void> restore() async {
    restores++;
    final failure = restoreFailure;
    if (failure != null) throw ServerSessionException(failure);
  }

  @override
  Future<void> unlock(String password) async {
    unlocks++;
    if (unlockFailure != null) throw ServerSessionException(unlockFailure!);
  }

  @override
  Future<void> renew() async => renewals++;

  @override
  Future<void> lock() async => locks++;

  @override
  void clear() => clears++;
}

class TestAuthRepository implements AuthRepository, SessionTokenProvider {
  static const user = AuthIdentity(id: 'demo-user', email: 'demo@example.test');
  AuthIdentity? restored;
  AuthIssue? failure;
  Completer<void>? gate;
  Completer<void>? refreshGate;
  int logouts = 0;
  int logins = 0;
  int refreshes = 0;
  int clears = 0;
  String? token;
  Future<void> _check() async {
    if (failure != null) throw AuthOperationException(failure!);
  }

  @override
  Future<AuthIdentity?> restore() async {
    await _check();
    token = restored == null ? null : 'test-token';
    return restored;
  }

  @override
  Future<AuthIdentity> login(String email, String password) async {
    logins++;
    await gate?.future;
    await _check();
    token = 'test-token';
    return user;
  }

  @override
  Future<void> register(String email, String password) => _check();
  @override
  Future<void> confirmEmailLink(String tokenHash) => _check();
  @override
  Future<void> authorizeRecoveryLink(String fragment) => _check();
  @override
  Future<AuthIdentity> verifyEmail(String email, String code) =>
      login(email, code);
  @override
  Future<void> resend(String email) => _check();
  @override
  Future<void> requestRecovery(String email) => _check();
  @override
  Future<void> verifyRecovery(String email, String code) => _check();
  @override
  Future<void> resetPassword(String password) => _check();
  @override
  Future<void> changeInitialPassword(String password) => _check();
  @override
  Future<AuthIdentity> unlock(AuthIdentity identity, String password) =>
      login(identity.email, password);
  @override
  Future<void> logout({bool global = false}) async {
    logouts++;
    token = null;
    await _check();
  }

  @override
  Future<void> clearLocal() async {
    clears++;
    token = null;
  }

  @override
  String? get accessToken => token;
  @override
  Future<String?> refreshAccessToken() async {
    refreshes++;
    await refreshGate?.future;
    await _check();
    return token;
  }
}

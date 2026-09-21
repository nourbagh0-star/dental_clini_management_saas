import 'dart:async';
import '../../features/auth/domain/auth_models.dart';
import '../../features/auth/domain/auth_repository.dart';
import '../network/session_token_provider.dart';
import 'privacy_signal.dart';
import 'server_session.dart';

/// Serializes provider mutations; route/token access is revoked synchronously.
class SessionCoordinator implements SessionTokenProvider, SessionLockHandler {
  SessionCoordinator(
    this._repository,
    this._tokens,
    this._signals, {
    ServerSession? serverSession,
    DateTime Function()? now,
    bool enableTimer = true,
    this.restoreServerSession = false,
  }) : _serverSession = serverSession ?? _NoopServerSession(),
       _now = now ?? DateTime.now {
    _subscription = _signals.messages.listen((message) {
      if (message == 'logout') {
        unawaited(logout(broadcast: false));
      } else {
        lock(broadcast: false);
      }
    });
    if (enableTimer) {
      _timer = Timer.periodic(
        const Duration(seconds: 1),
        (_) => checkInactivity(),
      );
    }
  }
  final AuthRepository _repository;
  final SessionTokenProvider _tokens;
  final PrivacySignal _signals;
  final ServerSession _serverSession;
  final DateTime Function() _now;
  final bool restoreServerSession;
  final _changes = StreamController<AuthViewState>.broadcast(sync: true);
  late final StreamSubscription<String> _subscription;
  Timer? _timer;
  AuthViewState _state = const AuthViewState();
  AuthViewState get state => _state;
  Stream<AuthViewState> get changes => _changes.stream;
  Future<void> _tail = Future.value();
  Future<String?>? _refresh;
  DateTime? _lastActivity;
  DateTime? _lastLeaseRenewal;
  int _generation = 0;
  bool _disposed = false;

  void _set(AuthViewState value) {
    if (_disposed) return;
    _state = value;
    _changes.add(value);
  }

  Future<T> _serial<T>(Future<T> Function() task) {
    final result = _tail.then((_) => task());
    _tail = result.then<void>((_) {}, onError: (Object _, StackTrace _) {});
    return result;
  }

  bool _allowed(AuthAction action) => switch (action) {
    AuthAction.recoveryLink =>
      state.stage == AuthStage.restoring ||
          state.stage == AuthStage.signedOut ||
          state.stage == AuthStage.recoveryPending,
    AuthAction.confirmEmailLink =>
      state.stage == AuthStage.restoring ||
          state.stage == AuthStage.signedOut ||
          state.stage == AuthStage.awaitingVerification,
    AuthAction.restore =>
      state.stage == AuthStage.restoring ||
          state.stage == AuthStage.restorationFailed,
    AuthAction.unlock => state.stage == AuthStage.locked,
    AuthAction.resetPassword => state.stage == AuthStage.recoveryAuthorized,
    AuthAction.changeInitialPassword =>
      state.stage == AuthStage.passwordChangeRequired,
    AuthAction.verifyRecovery => state.stage == AuthStage.recoveryPending,
    AuthAction.verifyEmail ||
    AuthAction.resend => state.stage == AuthStage.awaitingVerification,
    _ =>
      state.stage == AuthStage.signedOut ||
          state.stage == AuthStage.awaitingVerification ||
          state.stage == AuthStage.recoveryPending,
  };

  Future<void> run(AuthAction action, AuthInput input) async {
    if (state.busy || !_allowed(action)) {
      input.clear();
      return;
    }
    final generation = _generation;
    final before = state;
    _set(state.copyWith(busy: true, issue: null));
    await _serial(() async {
      if (generation != _generation) {
        input.clear();
        return;
      }
      var secret = input.takeSecret();
      final email = input.email.trim();
      AuthIdentity? restoredIdentity;
      try {
        AuthViewState next;
        switch (action) {
          case AuthAction.changeInitialPassword:
            await _repository.changeInitialPassword(secret);
            await _serverSession.completePasswordSetup();
            try {
              await _repository.logout(global: true);
            } on Object {
              throw const AuthOperationException(
                AuthIssue.passwordChangedRevocationUnconfirmed,
              );
            }
            _signals.send('logout');
            next = const AuthViewState(
              stage: AuthStage.signedOut,
              issue: AuthIssue.passwordChanged,
            );
          case AuthAction.recoveryLink:
            await _repository.clearLocal();
            await _repository.authorizeRecoveryLink(secret);
            next = const AuthViewState(stage: AuthStage.recoveryAuthorized);
          case AuthAction.confirmEmailLink:
            await _repository.clearLocal();
            await _repository.confirmEmailLink(secret);
            next = const AuthViewState(
              stage: AuthStage.signedOut,
              issue: AuthIssue.emailConfirmed,
            );
          case AuthAction.restore:
            restoredIdentity = await _repository.restore();
            if (restoredIdentity == null) {
              next = const AuthViewState(stage: AuthStage.signedOut);
            } else if (restoreServerSession) {
              await _serverSession.restore();
              next = AuthViewState(
                stage: AuthStage.signedIn,
                identity: restoredIdentity,
              );
            } else {
              next = AuthViewState(
                stage: AuthStage.locked,
                identity: restoredIdentity,
              );
              _signals.send('lock');
            }
          case AuthAction.login:
            final identity = await _repository.login(email, secret);
            await _serverSession.unlock(secret);
            next = AuthViewState(stage: AuthStage.signedIn, identity: identity);
          case AuthAction.register:
            await _repository.register(email, secret);
            next = AuthViewState(
              stage: AuthStage.awaitingVerification,
              email: email,
            );
          case AuthAction.verifyEmail:
            final identity = await _repository.verifyEmail(
              before.email,
              secret,
            );
            next = AuthViewState(stage: AuthStage.locked, identity: identity);
          case AuthAction.resend:
            await _repository.resend(before.email);
            next = before.copyWith(issue: AuthIssue.confirmationLinkSent);
          case AuthAction.recover:
            await _repository.requestRecovery(email);
            next = AuthViewState(
              stage: AuthStage.recoveryPending,
              email: email,
              issue: AuthIssue.recoverySent,
            );
          case AuthAction.verifyRecovery:
            await _repository.verifyRecovery(before.email, secret);
            next = AuthViewState(
              stage: AuthStage.recoveryAuthorized,
              email: before.email,
            );
          case AuthAction.resetPassword:
            await _repository.resetPassword(secret);
            _signals.send('logout');
            next = const AuthViewState(
              stage: AuthStage.signedOut,
              issue: AuthIssue.passwordChanged,
            );
          case AuthAction.unlock:
            final identity = await _repository.unlock(before.identity!, secret);
            await _serverSession.unlock(secret);
            next = AuthViewState(stage: AuthStage.signedIn, identity: identity);
        }
        if (generation == _generation) {
          if (next.stage == AuthStage.signedIn) {
            _lastActivity = _now();
            _lastLeaseRenewal = _lastActivity;
          }
          _set(next.copyWith(busy: false, hidden: state.hidden));
        }
      } on Object catch (error) {
        if (error is ServerSessionException &&
            error.kind == ServerSessionIssue.passwordChangeRequired) {
          if (generation == _generation) {
            _serverSession.clear();
            _set(
              const AuthViewState(
                stage: AuthStage.passwordChangeRequired,
                issue: AuthIssue.passwordChangeRequired,
              ),
            );
          }
          return;
        }
        if (action == AuthAction.login && error is ServerSessionException) {
          try {
            await _repository.logout();
          } on Object {
            // The signed-out UI remains authoritative after partial login.
          }
        }
        final issue = switch (error) {
          AuthOperationException() => error.issue,
          ServerSessionException(kind: ServerSessionIssue.credentials) =>
            AuthIssue.credentials,
          ServerSessionException(kind: ServerSessionIssue.authentication) =>
            AuthIssue.credentials,
          ServerSessionException(kind: ServerSessionIssue.locked) =>
            AuthIssue.unavailable,
          ServerSessionException() => AuthIssue.network,
          _ => AuthIssue.unknown,
        };
        if (generation != _generation) return;
        if (action == AuthAction.confirmEmailLink ||
            action == AuthAction.recoveryLink) {
          _set(AuthViewState(stage: AuthStage.signedOut, issue: issue));
        } else if (issue == AuthIssue.passwordChangedRevocationUnconfirmed) {
          _signals.send('logout');
          _set(AuthViewState(stage: AuthStage.signedOut, issue: issue));
        } else if (action == AuthAction.restore && restoredIdentity != null) {
          _serverSession.clear();
          _set(
            AuthViewState(
              stage: AuthStage.locked,
              identity: restoredIdentity,
              issue: issue,
            ),
          );
        } else if (action == AuthAction.restore) {
          if (issue == AuthIssue.credentials ||
              issue == AuthIssue.unconfirmed) {
            try {
              await _repository.clearLocal();
            } on Object {
              _set(
                const AuthViewState(
                  stage: AuthStage.restorationFailed,
                  issue: AuthIssue.storage,
                ),
              );
              return;
            }
            _set(AuthViewState(stage: AuthStage.signedOut, issue: issue));
          } else {
            _set(
              AuthViewState(stage: AuthStage.restorationFailed, issue: issue),
            );
          }
        } else if (action == AuthAction.login &&
            issue == AuthIssue.unconfirmed) {
          _set(
            AuthViewState(
              stage: AuthStage.awaitingVerification,
              email: email,
              issue: issue,
            ),
          );
        } else {
          _set(
            before.copyWith(busy: false, issue: issue, hidden: state.hidden),
          );
        }
      } finally {
        secret = '';
        input.clear();
      }
    });
  }

  void activity() {
    checkInactivity();
    if (state.stage == AuthStage.signedIn && !state.hidden) {
      _lastActivity = _now();
      final lastRenewal = _lastLeaseRenewal;
      if (lastRenewal == null ||
          _now().difference(lastRenewal) >= const Duration(minutes: 1)) {
        _lastLeaseRenewal = _now();
        unawaited(
          _serverSession.renew().catchError((Object error) {
            if (error is ServerSessionException &&
                (error.kind == ServerSessionIssue.locked ||
                    error.kind == ServerSessionIssue.authentication)) {
              lock();
            }
          }),
        );
      }
    }
  }

  void checkInactivity() {
    if (state.stage == AuthStage.signedIn &&
        _lastActivity != null &&
        _now().difference(_lastActivity!) >= const Duration(days: 3)) {
      lock();
    }
  }

  void background() {
    _set(state.copyWith(hidden: true));
  }

  Future<void> resume() async {
    checkInactivity();
    if (state.stage != AuthStage.signedIn) {
      _set(state.copyWith(hidden: false));
      return;
    }
    final generation = _generation;
    try {
      await _serial(_serverSession.restore);
      if (generation == _generation && state.stage == AuthStage.signedIn) {
        _set(state.copyWith(hidden: false));
      }
    } on Object {
      if (generation == _generation) {
        lock();
        _set(state.copyWith(hidden: false));
      }
    }
  }

  void lock({bool broadcast = true}) {
    if (state.stage != AuthStage.signedIn && state.stage != AuthStage.locked) {
      return;
    }
    _generation++;
    _lastLeaseRenewal = null;
    unawaited(_serverSession.lock().catchError((Object _) {}));
    _set(state.copyWith(stage: AuthStage.locked, busy: false, issue: null));
    if (broadcast) _signals.send('lock');
  }

  @override
  void handleSessionLocked() => lock();

  Future<void> logout({bool broadcast = true}) async {
    _generation++;
    final generation = _generation;
    _lastActivity = null;
    _lastLeaseRenewal = null;
    _serverSession.clear();
    _set(const AuthViewState(stage: AuthStage.signedOut, busy: true));
    if (broadcast) _signals.send('logout');
    await _serial(() async {
      AuthIssue? issue;
      try {
        await _repository.logout();
      } on AuthOperationException catch (e) {
        issue = e.issue;
      } on Object {
        issue = AuthIssue.revocationUnconfirmed;
      }
      if (generation == _generation) {
        _set(AuthViewState(stage: AuthStage.signedOut, issue: issue));
      }
    });
  }

  @override
  String? get accessToken {
    checkInactivity();
    return state.stage == AuthStage.signedIn && !state.hidden
        ? _tokens.accessToken
        : null;
  }

  @override
  Future<String?> refreshAccessToken() {
    if (accessToken == null) return Future.value();
    return _refresh ??= _refreshOnce().whenComplete(() => _refresh = null);
  }

  Future<String?> _refreshOnce() => _serial(() async {
    if (accessToken == null) return null;
    try {
      await _tokens.refreshAccessToken();
      return accessToken;
    } on Object {
      lock();
      rethrow;
    }
  });
  Future<void> dispose() async {
    _disposed = true;
    _generation++;
    _timer?.cancel();
    await _subscription.cancel();
    await _tail;
    await _signals.dispose();
    await _changes.close();
  }
}

class _NoopServerSession implements ServerSession {
  @override
  Future<void> completePasswordSetup() async {}
  @override
  void clear() {}
  @override
  Future<void> lock() async {}
  @override
  Future<void> renew() async {}
  @override
  Future<void> restore() async {}
  @override
  Future<void> unlock(String password) async {}
}

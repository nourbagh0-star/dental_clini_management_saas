import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:injectable/injectable.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/network/session_token_provider.dart';
import '../../../core/storage/auth_session_store.dart';
import '../domain/auth_models.dart';
import '../domain/auth_repository.dart';
import 'supabase_auth_data_source.dart';

@lazySingleton
class SupabaseAuthRepository implements AuthRepository, SessionTokenProvider {
  SupabaseAuthRepository(this._source, this._store);
  final SupabaseAuthDataSource _source;
  final AuthSessionStore _store;
  bool _recovery = false;

  Future<T> _guard<T>(Future<T> Function() action) async {
    if (!_source.config.backendConfigured) {
      throw const AuthOperationException(AuthIssue.unavailable);
    }
    try {
      return await action();
    } on AuthOperationException {
      rethrow;
    } on AuthRetryableFetchException {
      throw const AuthOperationException(AuthIssue.network);
    } on TimeoutException {
      throw const AuthOperationException(AuthIssue.network);
    } on AuthException catch (e) {
      final issue = switch (e.code) {
        'email_not_confirmed' => AuthIssue.unconfirmed,
        'weak_password' || 'same_password' => AuthIssue.weakPassword,
        'otp_expired' || 'otp_disabled' => AuthIssue.invalidCode,
        'over_request_rate_limit' ||
        'over_email_send_rate_limit' => AuthIssue.rateLimited,
        _ =>
          e.statusCode == '429' ? AuthIssue.rateLimited : AuthIssue.credentials,
      };
      throw AuthOperationException(issue);
    } on Object catch (_, stack) {
      Error.throwWithStackTrace(
        const AuthOperationException(AuthIssue.unknown),
        stack,
      );
    }
  }

  AuthIdentity _identity(User? user) {
    if (user == null || user.emailConfirmedAt == null || user.email == null) {
      throw const AuthOperationException(AuthIssue.unconfirmed);
    }
    return AuthIdentity(id: user.id, email: user.email!);
  }

  Future<void> _save() async {
    final token = _source.auth.currentSession?.refreshToken;
    if (token == null) {
      throw const AuthOperationException(AuthIssue.credentials);
    }
    try {
      await _store.write(token);
    } on Object {
      // A failed write must not leave a logged-in identity behind.
      try {
        await _source.auth.signOut();
      } on Object {
        /* reported as storage failure below */
      }
      await _source.connection.dispose();
      throw const AuthOperationException(AuthIssue.storage);
    }
  }

  @override
  Future<AuthIdentity?> restore() => !_source.config.backendConfigured
      ? Future.value()
      : _guard(() async {
          final String? token;
          try {
            token = await _store.read();
          } on Object {
            throw const AuthOperationException(AuthIssue.storage);
          }
          if (token == null) return null;
          // setSession refreshes on the server even if a saved access token was valid.
          final response = await _source.auth.setSession(token);
          final identity = _identity(response.user);
          await _save();
          return identity;
        });

  @override
  Future<AuthIdentity> login(String email, String password) => _guard(() async {
    final response = await _source.auth.signInWithPassword(
      email: email,
      password: password,
    );
    final identity = _identity(response.user);
    _recovery = false;
    await _save();
    return identity;
  });

  @override
  Future<void> register(String email, String password) => _guard(() async {
    final result = await _source.auth.signUp(email: email, password: password);
    if (result.session != null) {
      await _source.auth.signOut();
      throw const AuthOperationException(AuthIssue.unavailable);
    }
  });

  @override
  Future<void> authorizeRecoveryLink(String fragment) => _guard(() async {
    final parameters = Uri.splitQueryString(fragment);
    if (parameters['type'] != 'recovery' ||
        parameters.containsKey('error') ||
        parameters.containsKey('error_code')) {
      throw const AuthOperationException(AuthIssue.invalidConfirmationLink);
    }
    final response = await _source.auth.getSessionFromUrl(
      Uri.parse('https://confirmation.invalid/#$fragment'),
    );
    _identity(response.session.user);
    _recovery = true;
    // Memory only: the coordinator permits password reset, never clinic access.
  });

  @override
  Future<void> confirmEmailLink(String fragment) => _guard(() async {
    final parameters = Uri.splitQueryString(fragment);
    if (parameters.containsKey('error') ||
        parameters.containsKey('error_code') ||
        parameters['type'] != 'signup' ||
        !parameters.containsKey('access_token')) {
      throw const AuthOperationException(AuthIssue.invalidConfirmationLink);
    }
    final candidate = _source.isolatedClient();
    try {
      final result = await candidate.auth.getSessionFromUrl(
        Uri.parse('https://confirmation.invalid/#$fragment'),
      );
      _identity(result.session.user);
      // Verification must not grant the app a remembered login or server lease.
      await candidate.auth.signOut(scope: SignOutScope.local);
    } on AuthException catch (error) {
      if (error.code == 'otp_expired' || error.statusCode == '403') {
        throw const AuthOperationException(AuthIssue.invalidConfirmationLink);
      }
      rethrow;
    } finally {
      await candidate.dispose();
    }
  });

  @override
  Future<AuthIdentity> verifyEmail(String email, String code) =>
      _guard(() async {
        final result = await _source.auth.verifyOTP(
          email: code.length == 6 ? email : null,
          token: code.length == 6 ? code : null,
          tokenHash: code.length == 6 ? null : code,
          type: OtpType.signup,
        );
        final identity = _identity(result.user);
        _recovery = false;
        await _save();
        return identity;
      });
  @override
  Future<void> resend(String email) => _guard(() async {
    await _source.auth.resend(type: OtpType.signup, email: email);
  });
  @override
  Future<void> requestRecovery(String email) => _guard(() {
    String? redirectTo;
    if (kIsWeb) {
      final origin = Uri.base.origin;
      if (origin.isNotEmpty && origin != 'null') {
        redirectTo = '$origin/#/reset-password';
      }
    }
    return _source.auth.resetPasswordForEmail(
      email,
      redirectTo: redirectTo,
    );
  });
  @override
  Future<void> verifyRecovery(String email, String code) => _guard(() async {
    if (_source.auth.currentSession != null) {
      throw const AuthOperationException(AuthIssue.credentials);
    }
    final response = await _source.auth.verifyOTP(
      email: email,
      token: code,
      type: OtpType.recovery,
    );
    _identity(response.user);
    if (response.session == null) {
      throw const AuthOperationException(AuthIssue.invalidCode);
    }
    _recovery = true;
    // Recovery sessions are never persisted or made available to protected APIs.
  });
  @override
  Future<void> resetPassword(String password) => _guard(() async {
    if (!_recovery) throw const AuthOperationException(AuthIssue.credentials);
    await _source.auth.updateUser(UserAttributes(password: password));
    _recovery = false;
    try {
      await logout(global: true);
    } on Object {
      throw const AuthOperationException(
        AuthIssue.passwordChangedRevocationUnconfirmed,
      );
    }
  });

  @override
  Future<void> changeInitialPassword(String password) => _guard(() async {
    try {
      await _source.auth.updateUser(UserAttributes(password: password));
    } on AuthException catch (error) {
      // A retry after the password update succeeded must still complete setup.
      // The server compares the current hash against the original temporary one.
      if (error.code != 'same_password') rethrow;
    }
  });

  @override
  Future<AuthIdentity> unlock(AuthIdentity identity, String password) =>
      _guard(() async {
        final candidate = _source.isolatedClient();
        try {
          final result = await candidate.auth.signInWithPassword(
            email: identity.email,
            password: password,
          );
          final verified = _identity(result.user);
          if (verified.id != identity.id) {
            await candidate.auth.signOut();
            throw const AuthOperationException(AuthIssue.credentials);
          }
          return verified;
        } on Object {
          try {
            await candidate.auth.signOut();
          } on Object {
            /* original safe failure is propagated */
          }
          rethrow;
        } finally {
          await candidate.dispose();
        }
      });

  @override
  Future<void> logout({bool global = false}) async {
    AuthIssue? failure;
    try {
      await _store.clear();
    } on Object {
      failure = AuthIssue.storage;
    }
    try {
      if (_source.config.backendConfigured) {
        await _source.auth.signOut(
          scope: global ? SignOutScope.global : SignOutScope.local,
        );
      }
    } on Object {
      failure = AuthIssue.revocationUnconfirmed;
    } finally {
      _recovery = false;
      await _source.connection.dispose();
    }
    if (failure != null) throw AuthOperationException(failure);
  }

  @override
  Future<void> clearLocal() async {
    _recovery = false;
    await _source.connection.dispose();
    try {
      await _store.clear();
    } on Object {
      throw const AuthOperationException(AuthIssue.storage);
    }
  }

  @override
  String? get accessToken => _recovery ? null : _source.connection.accessToken;
  @override
  Future<String?> refreshAccessToken() => _guard(() async {
    if (_recovery || _source.auth.currentSession == null) return null;
    final result = await _source.auth.refreshSession();
    _identity(result.user);
    await _save();
    return result.session?.accessToken;
  });
}

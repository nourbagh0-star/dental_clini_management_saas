import 'package:injectable/injectable.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../config/app_config.dart';
import '../error/app_failure.dart';
import 'session_token_provider.dart';

/// Only data sources may use the SDK client. Phase 0 has no persisted login.
@lazySingleton
class SupabaseConnection implements SessionTokenProvider {
  SupabaseConnection(this._config);

  final AppConfig _config;
  SupabaseClient? _client;

  SupabaseClient get client {
    if (!_config.backendConfigured) throw const ValidationFailure();
    return _client ??= SupabaseClient(
      _config.supabaseUrl.toString(),
      _config.publishableKey!,
      // Signup links are handled by an isolated client at bootstrap, then
      // revoked. The main client never automatically adopts callback tokens.
      authOptions: const AuthClientOptions(
        autoRefreshToken: false,
        authFlowType: AuthFlowType.implicit,
      ),
    );
  }

  @override
  String? get accessToken => _client?.auth.currentSession?.accessToken;

  @override
  Future<String?> refreshAccessToken() async {
    final activeClient = _client;
    if (activeClient?.auth.currentSession == null) return null;
    try {
      return (await activeClient!.auth.refreshSession()).session?.accessToken;
    } on AuthException {
      throw const AuthenticationFailure();
    }
  }

  @disposeMethod
  Future<void> dispose() async {
    final old = _client;
    _client = null;
    await old?.dispose();
  }
}

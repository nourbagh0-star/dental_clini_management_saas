import 'package:injectable/injectable.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/config/app_config.dart';
import '../../../core/network/supabase_connection.dart';

@lazySingleton
class SupabaseAuthDataSource {
  SupabaseAuthDataSource(this.connection, this.config);
  final SupabaseConnection connection;
  final AppConfig config;
  GoTrueClient get auth => connection.client.auth;

  /// Password checks must not replace the active identity before verification.
  SupabaseClient isolatedClient() => SupabaseClient(
    config.supabaseUrl.toString(),
    config.publishableKey!,
    authOptions: const AuthClientOptions(
      autoRefreshToken: false,
      authFlowType: AuthFlowType.implicit,
    ),
  );
}

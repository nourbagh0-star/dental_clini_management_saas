import 'package:injectable/injectable.dart';

import '../../core/network/session_token_provider.dart';
import '../../core/config/app_config.dart';
import '../../core/auth/session_coordinator.dart';
import '../../core/auth/privacy_signal_factory.dart';
import '../../core/auth/server_session.dart';
import '../../core/storage/auth_session_store.dart';
import '../../core/storage/auth_session_store_factory.dart';
import '../../features/auth/data/supabase_auth_repository.dart';
import '../../features/auth/domain/auth_repository.dart';

Future<void> disposeCoordinator(SessionCoordinator value) => value.dispose();

@module
abstract class BackendModule {
  @lazySingleton
  AuthSessionStore sessionStore(AppConfig config) =>
      createAuthSessionStore(config.supabaseUrl?.toString() ?? 'disconnected');

  @lazySingleton
  AuthRepository authRepository(SupabaseAuthRepository repository) =>
      repository;

  @LazySingleton(dispose: disposeCoordinator)
  SessionCoordinator coordinator(
    SupabaseAuthRepository repository,
    SupabaseServerSession serverSession,
    AppConfig config,
  ) => SessionCoordinator(
    repository,
    repository,
    createPrivacySignal(config.supabaseUrl?.toString() ?? 'disconnected'),
    serverSession: serverSession,
    // A verified refresh token is stored in the platform secure storage, so a
    // returning user can continue on this device without entering credentials
    // again. SessionCoordinator still validates the server lease and locks
    // after three days without activity.
    restoreServerSession: true,
  );

  @lazySingleton
  SessionTokenProvider sessionTokens(SessionCoordinator coordinator) =>
      coordinator;
}

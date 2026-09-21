import 'auth_models.dart';

/// Identity workflows only. SDK models and credential persistence stay in data.
abstract interface class AuthRepository {
  Future<AuthIdentity?> restore();
  Future<AuthIdentity> login(String email, String password);
  Future<void> register(String email, String password);
  Future<void> confirmEmailLink(String tokenHash);
  Future<void> authorizeRecoveryLink(String fragment);
  Future<AuthIdentity> verifyEmail(String email, String code);
  Future<void> resend(String email);
  Future<void> requestRecovery(String email);
  Future<void> verifyRecovery(String email, String code);
  Future<void> resetPassword(String password);
  Future<void> changeInitialPassword(String password);
  Future<AuthIdentity> unlock(AuthIdentity identity, String password);
  Future<void> logout({bool global = false});
  Future<void> clearLocal();
}

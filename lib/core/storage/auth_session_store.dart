abstract interface class AuthSessionStore {
  Future<String?> read();
  Future<void> write(String value);
  Future<void> clear();
}

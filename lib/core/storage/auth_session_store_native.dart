import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'auth_session_store.dart';

AuthSessionStore createAuthSessionStore(String namespace) =>
    _NativeStore(namespace);

class _NativeStore implements AuthSessionStore {
  _NativeStore(String namespace) : _key = 'dentaflow.auth.$namespace';
  final String _key;
  final _storage = const FlutterSecureStorage();
  @override
  Future<String?> read() => _storage.read(key: _key);
  @override
  Future<void> write(String value) => _storage.write(key: _key, value: value);
  @override
  Future<void> clear() => _storage.delete(key: _key);
}

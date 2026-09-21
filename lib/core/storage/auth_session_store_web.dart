import 'package:web/web.dart' as web;
import 'auth_session_store.dart';

AuthSessionStore createAuthSessionStore(String namespace) =>
    _WebStore(namespace);

class _WebStore implements AuthSessionStore {
  _WebStore(String namespace) : _key = 'dentaflow.auth.$namespace';
  final String _key;
  @override
  Future<String?> read() async => web.window.sessionStorage.getItem(_key);
  @override
  Future<void> write(String value) async =>
      web.window.sessionStorage.setItem(_key, value);
  @override
  Future<void> clear() async => web.window.sessionStorage.removeItem(_key);
}

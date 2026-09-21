import 'privacy_signal.dart';

PrivacySignal createPrivacySignal(String namespace) => _NativeSignal();

class _NativeSignal implements PrivacySignal {
  @override
  Stream<String> get messages => const Stream.empty();
  @override
  void send(String message) {}
  @override
  Future<void> dispose() async {}
}

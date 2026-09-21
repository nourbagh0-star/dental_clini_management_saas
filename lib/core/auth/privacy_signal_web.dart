import 'dart:async';
import 'dart:js_interop';
import 'package:web/web.dart' as web;
import 'privacy_signal.dart';

PrivacySignal createPrivacySignal(String namespace) => _WebSignal(namespace);

class _WebSignal implements PrivacySignal {
  _WebSignal(String namespace)
    : _channel = web.BroadcastChannel('dentaflow.privacy.$namespace') {
    _listener = ((web.MessageEvent event) {
      final message = event.data.dartify();
      if (message == 'lock' || message == 'logout') {
        _messages.add(message! as String);
      }
    }).toJS;
    _channel.addEventListener('message', _listener);
  }
  final web.BroadcastChannel _channel;
  final _messages = StreamController<String>.broadcast();
  late final JSFunction _listener;
  @override
  Stream<String> get messages => _messages.stream;
  @override
  void send(String message) => _channel.postMessage(message.toJS);
  @override
  Future<void> dispose() async {
    _channel.removeEventListener('message', _listener);
    _channel.close();
    await _messages.close();
  }
}

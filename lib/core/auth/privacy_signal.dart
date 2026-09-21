abstract interface class PrivacySignal {
  Stream<String> get messages;
  void send(String message);
  Future<void> dispose();
}

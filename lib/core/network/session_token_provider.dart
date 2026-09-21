/// Provider-neutral credential boundary; authentication UI belongs to Phase 1.
abstract interface class SessionTokenProvider {
  String? get accessToken;
  Future<String?> refreshAccessToken();
}

/// Optional provider-neutral callback for a server-enforced privacy lock.
abstract interface class SessionLockHandler {
  void handleSessionLocked();
}

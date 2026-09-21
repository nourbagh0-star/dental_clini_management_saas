/// Safe, typed failures. Provider messages and response bodies stay out of UI.
sealed class AppFailure implements Exception {
  const AppFailure();
}

final class NetworkFailure extends AppFailure {
  const NetworkFailure();
}

final class AuthenticationFailure extends AppFailure {
  const AuthenticationFailure();
}

final class AuthorizationFailure extends AppFailure {
  const AuthorizationFailure();
}

final class ValidationFailure extends AppFailure {
  const ValidationFailure();
}

final class ServerFailure extends AppFailure {
  const ServerFailure();
}

final class NotFoundFailure extends AppFailure {
  const NotFoundFailure();
}

final class UnknownFailure extends AppFailure {
  const UnknownFailure();
}

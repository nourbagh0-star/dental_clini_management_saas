import 'package:dio/dio.dart';

import '../../error/app_failure.dart';

class ErrorInterceptor extends Interceptor {
  ErrorInterceptor({this.onSessionLocked});

  final void Function()? onSessionLocked;

  static AppFailure failureFor(DioException error) {
    if (error.error case final AppFailure failure) return failure;
    if ({
      DioExceptionType.connectionTimeout,
      DioExceptionType.sendTimeout,
      DioExceptionType.receiveTimeout,
      DioExceptionType.connectionError,
    }.contains(error.type)) {
      return const NetworkFailure();
    }
    return switch (error.response?.statusCode) {
      401 || 423 => const AuthenticationFailure(),
      403 => const AuthorizationFailure(),
      404 => const NotFoundFailure(),
      400 || 409 || 422 => const ValidationFailure(),
      final int code when code >= 500 => const ServerFailure(),
      _ => const UnknownFailure(),
    };
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    if (err.response?.statusCode == 423) onSessionLocked?.call();
    handler.next(err.copyWith(error: failureFor(err)));
  }
}

import 'package:dio/dio.dart';

/// Intentionally excludes URLs, headers, bodies, exception text and identifiers.
class SafeLoggingInterceptor extends Interceptor {
  SafeLoggingInterceptor(this._write);
  final void Function(String) _write;

  @override
  void onResponse(
    Response<dynamic> response,
    ResponseInterceptorHandler handler,
  ) {
    _write('HTTP response status=${response.statusCode}');
    handler.next(response);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    _write('HTTP failure status=${err.response?.statusCode ?? 0}');
    handler.next(err);
  }
}

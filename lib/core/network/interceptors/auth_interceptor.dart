import 'package:dio/dio.dart';

import '../../config/app_config.dart';
import '../../error/app_failure.dart';
import '../session_token_provider.dart';

/// Attaches credentials only to this project's Edge Functions origin/path.
/// A 401 may replay GET/HEAD/OPTIONS once. Mutations never auto-replay.
class AuthInterceptor extends Interceptor {
  AuthInterceptor(this._dio, this._config, this._tokens);

  static const requiresAuth = 'requiresAuth';
  static const _retried = 'authRetried';
  final Dio _dio;
  final AppConfig _config;
  final SessionTokenProvider _tokens;
  Future<String?>? _refresh;

  bool _trusted(Uri uri) {
    final base = _config.supabaseUrl;
    return base != null &&
        uri.origin == base.origin &&
        uri.userInfo.isEmpty &&
        uri.path.startsWith('/functions/v1/');
  }

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    if (!_trusted(options.uri)) {
      handler.reject(
        DioException(
          requestOptions: options,
          error: const AuthorizationFailure(),
        ),
      );
      return;
    }
    options.headers.removeWhere(
      (key, _) =>
          key.toLowerCase() == 'authorization' || key.toLowerCase() == 'apikey',
    );
    options.headers['apikey'] = _config.publishableKey;
    if (options.extra[requiresAuth] == true) {
      final token = _tokens.accessToken;
      if (token == null) {
        handler.reject(
          DioException(
            requestOptions: options,
            error: const AuthenticationFailure(),
          ),
        );
        return;
      }
      options.headers['Authorization'] = 'Bearer $token';
    }
    handler.next(options);
  }

  Future<String?> _refreshOnce() async {
    if (_refresh != null) return _refresh;
    final pending = _tokens.refreshAccessToken();
    _refresh = pending;
    try {
      return await pending;
    } finally {
      if (identical(_refresh, pending)) _refresh = null;
    }
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) async {
    final error = err;
    final request = error.requestOptions;
    if (error.response?.statusCode != 401 ||
        request.extra[requiresAuth] != true ||
        request.extra[_retried] == true ||
        !_trusted(request.uri) ||
        !{'GET', 'HEAD', 'OPTIONS'}.contains(request.method.toUpperCase())) {
      handler.next(error);
      return;
    }
    try {
      final current = _tokens.accessToken;
      final token =
          current != null &&
              request.headers['Authorization'] != 'Bearer $current'
          ? current
          : await _refreshOnce();
      if (token == null) {
        handler.next(error);
        return;
      }
      final retry = request.copyWith(extra: {...request.extra, _retried: true});
      final response = await _dio.fetch<dynamic>(retry);
      handler.resolve(response);
    } on DioException catch (retryError) {
      handler.next(retryError);
    } on Object {
      // The request is failed explicitly; provider details are never exposed.
      handler.next(error.copyWith(error: const AuthenticationFailure()));
    }
  }
}

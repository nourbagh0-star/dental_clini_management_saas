import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:injectable/injectable.dart';

import '../config/app_config.dart';
import 'interceptors/auth_interceptor.dart';
import 'interceptors/error_interceptor.dart';
import 'interceptors/safe_logging_interceptor.dart';
import 'session_token_provider.dart';

@lazySingleton
class DioClient {
  DioClient(AppConfig config, SessionTokenProvider tokens)
    : client = Dio(
        BaseOptions(
          baseUrl:
              '${config.supabaseUrl ?? Uri.parse('https://backend.invalid')}/functions/v1/',
          connectTimeout: const Duration(seconds: 15),
          sendTimeout: kIsWeb ? null : const Duration(seconds: 15),
          receiveTimeout: const Duration(seconds: 20),
          followRedirects: false,
        ),
      ) {
    final lockHandler = switch (tokens) {
      final SessionLockHandler handler => handler,
      _ => null,
    };
    client.interceptors.addAll([
      if (kIsWeb)
        InterceptorsWrapper(
          onRequest: (options, handler) {
            if (options.data == null) {
              options.sendTimeout = null;
            }
            handler.next(options);
          },
        ),
      AuthInterceptor(client, config, tokens),
      ErrorInterceptor(onSessionLocked: lockHandler?.handleSessionLocked),
      if (kDebugMode) SafeLoggingInterceptor((message) => debugPrint(message)),
    ]);
  }

  /// For data sources only. This transport is scoped to Edge Functions.
  final Dio client;

  @disposeMethod
  void dispose() => client.close(force: true);
}

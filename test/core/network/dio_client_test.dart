import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:dental_clini_management_saas/core/config/app_config.dart';
import 'package:dental_clini_management_saas/core/error/app_failure.dart';
import 'package:dental_clini_management_saas/core/network/dio_client.dart';
import 'package:dental_clini_management_saas/core/network/interceptors/auth_interceptor.dart';
import 'package:dental_clini_management_saas/core/network/interceptors/safe_logging_interceptor.dart';
import 'package:dental_clini_management_saas/core/network/session_token_provider.dart';

import '../../support/fakes.dart';

void main() {
  late FakeTokens tokens;
  late DioClient transport;
  late FakeHttpAdapter adapter;

  setUp(() {
    tokens = FakeTokens();
    transport = DioClient(
      AppConfig.parse(
        supabaseUrl: 'https://demo.supabase.co',
        publishableKey: 'sb_publishable_demo',
      ),
      tokens,
    );
    adapter = FakeHttpAdapter((_) => jsonResponse(200));
    transport.client.httpClientAdapter = adapter;
  });
  tearDown(() => transport.dispose());

  Options authenticated() =>
      Options(extra: {AuthInterceptor.requiresAuth: true});

  test(
    'unauthenticated endpoint gets public key but no supplied bearer',
    () async {
      await transport.client.get<dynamic>(
        'health',
        options: Options(headers: {'authorization': 'Bearer unexpected'}),
      );
      expect(adapter.requests.single.headers['apikey'], 'sb_publishable_demo');
      expect(
        adapter.requests.single.headers.keys.any(
          (key) => key.toLowerCase() == 'authorization',
        ),
        isFalse,
      );
      expect(transport.client.options.followRedirects, isFalse);
    },
  );

  test(
    'foreign origins and non-function paths never receive credentials',
    () async {
      for (final url in [
        'https://outside.example/functions/v1/read',
        'https://demo.supabase.co.evil.example/functions/v1/read',
        'https://demo.supabase.co/rest/v1/patients',
        '../rest',
      ]) {
        await expectLater(
          transport.client.get<dynamic>(url, options: authenticated()),
          throwsA(
            isA<DioException>().having(
              (e) => e.error,
              'failure',
              isA<AuthorizationFailure>(),
            ),
          ),
        );
      }
      expect(adapter.requests, isEmpty);
    },
  );

  test('missing session rejects protected request before sending', () async {
    tokens.accessToken = null;
    await expectLater(
      transport.client.get<dynamic>('read', options: authenticated()),
      throwsA(
        isA<DioException>().having(
          (e) => e.error,
          'failure',
          isA<AuthenticationFailure>(),
        ),
      ),
    );
    expect(adapter.requests, isEmpty);
  });

  test('safe request refreshes and replays exactly once', () async {
    adapter = FakeHttpAdapter(
      (request) => jsonResponse(
        request.headers['Authorization'] == 'Bearer renewed' ? 200 : 401,
      ),
    );
    transport.client.httpClientAdapter = adapter;
    await transport.client.get<dynamic>('read', options: authenticated());
    expect(tokens.refreshCount, 1);
    expect(adapter.requests, hasLength(2));
    expect(adapter.requests.last.headers['Authorization'], 'Bearer renewed');
  });

  test(
    'second 401 stops; mutation 401 is never automatically replayed',
    () async {
      adapter = FakeHttpAdapter(
        (_) => jsonResponse(401, '{"message":"private details"}'),
      );
      transport.client.httpClientAdapter = adapter;
      await expectLater(
        transport.client.get<dynamic>('read', options: authenticated()),
        throwsA(isA<DioException>()),
      );
      expect(adapter.requests, hasLength(2));
      expect(tokens.refreshCount, 1);
      await expectLater(
        transport.client.post<dynamic>(
          'payment',
          data: {'amount': '20.00'},
          options: authenticated(),
        ),
        throwsA(isA<DioException>()),
      );
      expect(adapter.requests, hasLength(3));
      expect(tokens.refreshCount, 1);
    },
  );

  test('simultaneous 401 requests share a refresh', () async {
    final refreshGate = Completer<String?>();
    final bothSent = Completer<void>();
    tokens.refresh = () => refreshGate.future;
    var expiredRequests = 0;
    adapter = FakeHttpAdapter((request) {
      if (request.headers['Authorization'] == 'Bearer renewed') {
        return jsonResponse(200);
      }
      expiredRequests++;
      if (expiredRequests == 2) bothSent.complete();
      return jsonResponse(401);
    });
    transport.client.httpClientAdapter = adapter;
    final first = transport.client.get<dynamic>(
      'first',
      options: authenticated(),
    );
    final second = transport.client.get<dynamic>(
      'second',
      options: authenticated(),
    );
    await bothSent.future;
    await Future<void>.delayed(Duration.zero);
    refreshGate.complete('renewed');
    await Future.wait([first, second]);
    expect(tokens.refreshCount, 1);
    expect(adapter.requests, hasLength(4));
  });

  test(
    'refresh failure surfaces authentication failure without another request',
    () async {
      tokens.refresh = () async => throw StateError('private-provider-message');
      adapter = FakeHttpAdapter((_) => jsonResponse(401));
      transport.client.httpClientAdapter = adapter;
      await expectLater(
        transport.client.get<dynamic>('read', options: authenticated()),
        throwsA(
          isA<DioException>().having(
            (e) => e.error,
            'failure',
            isA<AuthenticationFailure>(),
          ),
        ),
      );
      expect(adapter.requests, hasLength(1));
    },
  );

  test(
    'maps permission failures and logs no request or response content',
    () async {
      final logs = <String>[];
      transport.client.interceptors.add(SafeLoggingInterceptor(logs.add));
      adapter = FakeHttpAdapter(
        (_) => jsonResponse(403, '{"diagnosis":"private-medical-content"}'),
      );
      transport.client.httpClientAdapter = adapter;
      await expectLater(
        transport.client.get<dynamic>(
          'patient-secret?name=private-name',
          options: authenticated(),
        ),
        throwsA(
          isA<DioException>().having(
            (e) => e.error,
            'failure',
            isA<AuthorizationFailure>(),
          ),
        ),
      );
      expect(logs, ['HTTP failure status=403']);
    },
  );

  test('server lock response locks the application without replay', () async {
    final lockAwareTokens = _LockAwareTokens();
    final lockedTransport = DioClient(
      AppConfig.parse(
        supabaseUrl: 'https://demo.supabase.co',
        publishableKey: 'sb_publishable_demo',
      ),
      lockAwareTokens,
    );
    addTearDown(lockedTransport.dispose);
    final lockedAdapter = FakeHttpAdapter((_) => jsonResponse(423));
    lockedTransport.client.httpClientAdapter = lockedAdapter;

    await expectLater(
      lockedTransport.client.post<dynamic>(
        'patients',
        options: Options(extra: {AuthInterceptor.requiresAuth: true}),
      ),
      throwsA(
        isA<DioException>().having(
          (error) => error.error,
          'failure',
          isA<AuthenticationFailure>(),
        ),
      ),
    );

    expect(lockAwareTokens.lockCount, 1);
    expect(lockedAdapter.requests, hasLength(1));
    expect(lockAwareTokens.refreshCount, 0);
  });

  test('unconfigured transport fails locally', () async {
    final disconnected = DioClient(AppConfig.parse(), tokens);
    addTearDown(disconnected.dispose);
    disconnected.client.httpClientAdapter = adapter;
    await expectLater(
      disconnected.client.get<dynamic>('health'),
      throwsA(isA<DioException>()),
    );
    expect(adapter.requests, isEmpty);
  });
}

class _LockAwareTokens extends FakeTokens implements SessionLockHandler {
  int lockCount = 0;

  @override
  void handleSessionLocked() => lockCount++;
}

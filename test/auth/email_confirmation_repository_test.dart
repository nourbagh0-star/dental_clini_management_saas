import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:dental_clini_management_saas/core/config/app_config.dart';
import 'package:dental_clini_management_saas/core/network/supabase_connection.dart';
import 'package:dental_clini_management_saas/core/storage/auth_session_store.dart';
import 'package:dental_clini_management_saas/features/auth/data/supabase_auth_data_source.dart';
import 'package:dental_clini_management_saas/features/auth/data/supabase_auth_repository.dart';
import 'package:dental_clini_management_saas/features/auth/domain/auth_models.dart';

class _Store implements AuthSessionStore {
  String? value;
  int writes = 0;
  @override
  Future<String?> read() async => value;
  @override
  Future<void> clear() async => value = null;
  @override
  Future<void> write(String token) async {
    writes++;
    value = token;
  }
}

void main() {
  test(
    'confirmation validates the user and revokes only the temporary session',
    () async {
      final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
      addTearDown(() => server.close(force: true));
      final requests = <String>[];
      server.listen((request) async {
        requests.add(
          '${request.method} ${request.uri.path}${request.uri.query.isEmpty ? '' : '?${request.uri.query}'}',
        );
        request.response.headers.contentType = ContentType.json;
        if (request.uri.path == '/auth/v1/user') {
          request.response.write(
            jsonEncode({
              'id': 'fictional-user',
              'email': 'owner@example.test',
              'email_confirmed_at': '2026-09-17T12:00:00Z',
              'app_metadata': <String, dynamic>{},
              'user_metadata': <String, dynamic>{},
              'aud': 'authenticated',
              'created_at': '2026-09-17T12:00:00Z',
            }),
          );
        } else if (request.uri.path == '/auth/v1/logout') {
          request.response.statusCode = 204;
        } else {
          request.response.statusCode = 404;
        }
        await request.response.close();
      });
      final config = AppConfig.parse(
        supabaseUrl: 'http://127.0.0.1:${server.port}',
        publishableKey: 'sb_publishable_test',
      );
      final connection = SupabaseConnection(config);
      addTearDown(connection.dispose);
      final store = _Store();
      final repository = SupabaseAuthRepository(
        SupabaseAuthDataSource(connection, config),
        store,
      );
      String encode(Object value) =>
          base64Url.encode(utf8.encode(jsonEncode(value))).replaceAll('=', '');
      final token =
          '${encode({'alg': 'HS256'})}.${encode({'sub': 'fictional-user', 'exp': DateTime.now().add(const Duration(hours: 1)).millisecondsSinceEpoch ~/ 1000})}.test';
      final fragment = Uri(
        queryParameters: {
          'access_token': token,
          'refresh_token': 'fictional-refresh',
          'expires_in': '3600',
          'token_type': 'bearer',
          'type': 'signup',
        },
      ).query;
      await repository.confirmEmailLink(fragment);
      expect(requests, [
        'GET /auth/v1/user',
        'POST /auth/v1/logout?scope=local',
      ]);
      expect(store.writes, 0);
      expect(store.value, isNull);
      expect(connection.accessToken, isNull);
      for (final invalid in [
        'error=access_denied&error_code=otp_expired',
        'access_token=test&type=recovery',
        '',
      ]) {
        await expectLater(
          repository.confirmEmailLink(invalid),
          throwsA(
            isA<AuthOperationException>().having(
              (e) => e.issue,
              'issue',
              AuthIssue.invalidConfirmationLink,
            ),
          ),
        );
      }
      expect(requests.length, 2);
      await repository.authorizeRecoveryLink(
        fragment.replaceFirst('type=signup', 'type=recovery'),
      );
      expect(store.writes, 0);
      expect(repository.accessToken, isNull);
      expect(connection.accessToken, isNotNull);
      await repository.logout();
      expect(connection.accessToken, isNull);
    },
  );
}

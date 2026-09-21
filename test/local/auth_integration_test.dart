import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:dental_clini_management_saas/core/auth/server_session.dart';
import 'package:dental_clini_management_saas/core/config/app_config.dart';
import 'package:dental_clini_management_saas/core/network/supabase_connection.dart';
import 'package:dental_clini_management_saas/core/storage/auth_session_store.dart';
import 'package:dental_clini_management_saas/features/auth/data/supabase_auth_data_source.dart';
import 'package:dental_clini_management_saas/features/auth/data/supabase_auth_repository.dart';
import 'package:dental_clini_management_saas/features/auth/domain/auth_models.dart';

class _MemorySession implements AuthSessionStore {
  String? value;
  @override
  Future<String?> read() async => value;
  @override
  Future<void> write(String value) async {
    this.value = value;
  }

  @override
  Future<void> clear() async {
    value = null;
  }
}

void main() {
  test(
    'real local Auth: verification, restore, unlock, recovery and revocation',
    () async {
      final config = AppConfig.fromEnvironment();
      expect(config.supabaseUrl?.host, anyOf('127.0.0.1', 'localhost'));
      final connection = SupabaseConnection(config);
      final store = _MemorySession();
      final source = SupabaseAuthDataSource(connection, config);
      final repository = SupabaseAuthRepository(source, store);
      final secondConnection = SupabaseConnection(config);
      final second = SupabaseAuthRepository(
        SupabaseAuthDataSource(secondConnection, config),
        _MemorySession(),
      );
      addTearDown(connection.dispose);
      addTearDown(secondConnection.dispose);
      final mail = Dio(
        BaseOptions(
          baseUrl: 'http://127.0.0.1:54324/api/v1',
          connectTimeout: const Duration(seconds: 5),
        ),
      );
      addTearDown(() => mail.close(force: true));
      final email =
          'demo-${DateTime.now().microsecondsSinceEpoch}@example.test';
      const password = 'fictional long test passphrase 42';
      const replacement = 'different fictional test phrase 84';
      final usedMessages = <String>{};
      Future<String> readCode() async {
        for (var attempt = 0; attempt < 30; attempt++) {
          final response = await mail.get<Map<String, dynamic>>('/messages');
          final messages = response.data!['messages'] as List<dynamic>;
          for (final raw in messages) {
            final message = raw as Map<String, dynamic>;
            final recipients = message['To'] as List<dynamic>;
            if (!recipients.any(
              (r) => (r as Map<String, dynamic>)['Address'] == email,
            )) {
              continue;
            }
            final id = message['ID'] as String;
            if (usedMessages.contains(id)) continue;
            final full = await mail.get<Map<String, dynamic>>('/message/$id');
            final body = '${full.data!['Text']} ${full.data!['HTML']}';
            final code =
                RegExp(r'token=([A-Za-z0-9_-]+)').firstMatch(body)?.group(1) ??
                RegExp(r'\b\d{6}\b').firstMatch(body)?.group(0);
            if (code != null) {
              expect(body, contains('ساعة واحدة'));
              usedMessages.add(id);
              return code;
            }
          }
          await Future<void>.delayed(const Duration(milliseconds: 200));
        }
        fail('Local inbox did not receive the expected email code.');
      }

      await repository.register(email, password);
      expect(connection.accessToken, isNull);
      await expectLater(
        repository.login(email, password),
        throwsA(
          isA<AuthOperationException>().having(
            (e) => e.issue,
            'issue',
            AuthIssue.unconfirmed,
          ),
        ),
      );
      final confirmation = await readCode();
      final verifier = Dio();
      addTearDown(() => verifier.close(force: true));
      final verified = await verifier.get<void>(
        '${config.supabaseUrl}/auth/v1/verify',
        queryParameters: {'token': confirmation, 'type': 'signup'},
        options: Options(
          followRedirects: false,
          validateStatus: (status) => status == 303 || status == 302,
        ),
      );
      final callback = Uri.parse(verified.headers.value('location')!);
      expect(callback.fragment, contains('type=signup'));
      await repository.confirmEmailLink(callback.fragment);
      expect(store.value, isNull);
      expect(repository.accessToken, isNull);
      final identity = await repository.login(email, password);
      expect(identity.email, email);
      expect(store.value, isNotNull);
      expect(repository.accessToken, isNotNull);
      final initialServerSession = SupabaseServerSession(config, connection);
      addTearDown(initialServerSession.dispose);
      await initialServerSession.unlock(password);
      await connection.dispose();
      final restoredConnection = SupabaseConnection(config);
      final restoredRepository = SupabaseAuthRepository(
        SupabaseAuthDataSource(restoredConnection, config),
        store,
      );
      final restoredServerSession = SupabaseServerSession(
        config,
        restoredConnection,
      );
      addTearDown(restoredConnection.dispose);
      addTearDown(restoredServerSession.dispose);
      expect((await restoredRepository.restore())?.id, identity.id);
      await restoredServerSession.restore();
      await restoredServerSession.renew();
      await restoredServerSession.lock();
      await expectLater(
        restoredServerSession.restore(),
        throwsA(
          isA<ServerSessionException>().having(
            (error) => error.kind,
            'kind',
            ServerSessionIssue.locked,
          ),
        ),
      );
      await expectLater(
        restoredRepository.unlock(identity, 'incorrect password'),
        throwsA(isA<AuthOperationException>()),
      );
      expect(
        (await restoredRepository.unlock(identity, password)).id,
        identity.id,
      );
      await restoredServerSession.unlock(password);
      expect(await restoredRepository.refreshAccessToken(), isNotNull);
      await restoredRepository.logout();
      expect(store.value, isNull);
      await expectLater(
        restoredRepository.verifyEmail(email, confirmation),
        throwsA(isA<AuthOperationException>()),
      );
      await second.login(email, password);
      await restoredRepository.requestRecovery(email);
      final recovery = await readCode();
      await restoredRepository.verifyRecovery(email, recovery);
      expect(restoredRepository.accessToken, isNull);
      expect(store.value, isNull);
      await restoredRepository.resetPassword(replacement);
      expect(restoredRepository.accessToken, isNull);
      await expectLater(
        second.refreshAccessToken(),
        throwsA(isA<AuthOperationException>()),
      );
      await expectLater(
        restoredRepository.login(email, password),
        throwsA(isA<AuthOperationException>()),
      );
      expect(
        (await restoredRepository.login(email, replacement)).id,
        identity.id,
      );
      await restoredRepository.logout();
    },
    skip: !const bool.fromEnvironment('RUN_LOCAL_AUTH'),
    timeout: const Timeout(Duration(minutes: 2)),
  );
}

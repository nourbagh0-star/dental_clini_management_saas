import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:dental_clini_management_saas/core/config/app_config.dart';
import 'package:dental_clini_management_saas/core/auth/server_session.dart';
import 'package:dental_clini_management_saas/core/network/dio_client.dart';
import 'package:dental_clini_management_saas/core/network/supabase_connection.dart';
import 'package:dental_clini_management_saas/core/storage/auth_session_store.dart';
import 'package:dental_clini_management_saas/features/auth/data/supabase_auth_data_source.dart';
import 'package:dental_clini_management_saas/features/auth/data/supabase_auth_repository.dart';
import 'package:dental_clini_management_saas/features/clinic/data/supabase_clinic_data_source.dart';
import 'package:dental_clini_management_saas/features/clinic/data/supabase_clinic_repository.dart';

class _MemorySession implements AuthSessionStore {
  String? value;
  @override
  Future<void> clear() async => value = null;
  @override
  Future<String?> read() async => value;
  @override
  Future<void> write(String next) async => value = next;
}

void main() {
  test(
    'real local database: clinic creation creates isolated owner membership',
    () async {
      final config = AppConfig.fromEnvironment();
      expect(config.supabaseUrl?.host, anyOf('127.0.0.1', 'localhost'));
      final firstConnection = SupabaseConnection(config);
      final secondConnection = SupabaseConnection(config);
      addTearDown(firstConnection.dispose);
      addTearDown(secondConnection.dispose);
      final firstAuth = SupabaseAuthRepository(
        SupabaseAuthDataSource(firstConnection, config),
        _MemorySession(),
      );
      final secondAuth = SupabaseAuthRepository(
        SupabaseAuthDataSource(secondConnection, config),
        _MemorySession(),
      );
      final firstFunctions = DioClient(config, firstAuth);
      final secondFunctions = DioClient(config, secondAuth);
      addTearDown(firstFunctions.dispose);
      addTearDown(secondFunctions.dispose);
      final firstClinics = SupabaseClinicRepository(
        SupabaseClinicDataSource(firstFunctions),
      );
      final secondClinics = SupabaseClinicRepository(
        SupabaseClinicDataSource(secondFunctions),
      );
      final inbox = Dio(
        BaseOptions(
          baseUrl: 'http://127.0.0.1:54324/api/v1',
          connectTimeout: const Duration(seconds: 5),
        ),
      );
      addTearDown(() => inbox.close(force: true));
      final stamp = DateTime.now().microsecondsSinceEpoch;
      const password = 'fictional long test passphrase 42';

      await _registerAndVerify(
        repository: firstAuth,
        inbox: inbox,
        email: 'clinic-owner-$stamp@example.test',
        password: password,
      );
      final firstServerSession = SupabaseServerSession(config, firstConnection);
      addTearDown(firstServerSession.dispose);
      await expectLater(
        firstServerSession.unlock('wrong fictional password'),
        throwsA(
          isA<ServerSessionException>().having(
            (error) => error.kind,
            'kind',
            ServerSessionIssue.credentials,
          ),
        ),
      );
      await firstServerSession.unlock(password);
      await firstServerSession.renew();
      await _registerAndVerify(
        repository: secondAuth,
        inbox: inbox,
        email: 'clinic-other-$stamp@example.test',
        password: password,
      );
      final secondServerSession = SupabaseServerSession(
        config,
        secondConnection,
      );
      addTearDown(secondServerSession.dispose);
      await secondServerSession.unlock(password);

      final first = await firstClinics.createClinic(
        name: 'North Demo $stamp',
        ownerDisplayName: 'North Owner',
        currencyCode: 'RUB',
        timeZone: 'Europe/Moscow',
      );
      expect(
        (await firstClinics.getMyActiveMemberships()).map((m) => m.clinic.id),
        contains(first.id),
      );
      await firstServerSession.lock();
      await expectLater(
        firstClinics.getMyActiveMemberships(),
        throwsA(anything),
      );
      await firstServerSession.unlock(password);
      expect(
        (await firstClinics.getMyActiveMemberships()).map((m) => m.clinic.id),
        contains(first.id),
      );
      expect(
        (await secondClinics.getMyActiveMemberships()).map((m) => m.clinic.id),
        isNot(contains(first.id)),
      );

      final second = await secondClinics.createClinic(
        name: 'South Demo $stamp',
        ownerDisplayName: 'South Owner',
        currencyCode: 'USD',
        timeZone: 'America/New_York',
      );
      expect(
        (await secondClinics.getMyActiveMemberships()).map((m) => m.clinic.id),
        contains(second.id),
      );
    },
    skip: !const bool.fromEnvironment('RUN_LOCAL_CLINIC'),
    timeout: const Timeout(Duration(minutes: 2)),
  );
}

Future<void> _registerAndVerify({
  required SupabaseAuthRepository repository,
  required Dio inbox,
  required String email,
  required String password,
}) async {
  await repository.register(email, password);
  final code = await _readConfirmationCode(inbox, email);
  await repository.verifyEmail(email, code);
}

Future<String> _readConfirmationCode(Dio inbox, String email) async {
  for (var attempt = 0; attempt < 30; attempt++) {
    final response = await inbox.get<Map<String, dynamic>>('/messages');
    final messages = response.data!['messages'] as List<dynamic>;
    for (final raw in messages) {
      final message = raw as Map<String, dynamic>;
      final recipients = message['To'] as List<dynamic>;
      if (!recipients.any(
        (recipient) => (recipient as Map<String, dynamic>)['Address'] == email,
      )) {
        continue;
      }
      final id = message['ID'] as String;
      final full = await inbox.get<Map<String, dynamic>>('/message/$id');
      final body = '${full.data!['Text']} ${full.data!['HTML']}';
      final code =
          RegExp(r'token=([A-Za-z0-9_-]+)').firstMatch(body)?.group(1) ??
          RegExp(r'\b\d{6}\b').firstMatch(body)?.group(0);
      if (code != null) return code;
    }
    await Future<void>.delayed(const Duration(milliseconds: 200));
  }
  fail('Local inbox did not receive the expected confirmation code.');
}

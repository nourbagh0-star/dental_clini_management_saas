import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import 'package:dental_clini_management_saas/core/config/app_config.dart';
import 'package:dental_clini_management_saas/core/auth/server_session.dart';
import 'package:dental_clini_management_saas/core/network/dio_client.dart';
import 'package:dental_clini_management_saas/core/network/supabase_connection.dart';
import 'package:dental_clini_management_saas/core/storage/auth_session_store.dart';
import 'package:dental_clini_management_saas/features/auth/data/supabase_auth_data_source.dart';
import 'package:dental_clini_management_saas/features/auth/data/supabase_auth_repository.dart';
import 'package:dental_clini_management_saas/features/clinic/data/supabase_clinic_data_source.dart';
import 'package:dental_clini_management_saas/features/clinic/data/supabase_clinic_repository.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

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
    'real local audit records access and returns an owner-only page',
    () async {
      final config = AppConfig.fromEnvironment();
      expect(config.supabaseUrl?.host, anyOf('127.0.0.1', 'localhost'));
      final connection = SupabaseConnection(config);
      final auth = SupabaseAuthRepository(
        SupabaseAuthDataSource(connection, config),
        _MemorySession(),
      );
      final clinicFunctions = DioClient(config, auth);
      final clinics = SupabaseClinicRepository(
        SupabaseClinicDataSource(clinicFunctions),
      );
      final http = Dio(
        BaseOptions(
          baseUrl: config.supabaseUrl.toString(),
          validateStatus: (status) => status != null && status < 600,
        ),
      );
      addTearDown(connection.dispose);
      addTearDown(clinicFunctions.dispose);
      addTearDown(() => http.close(force: true));

      final stamp = DateTime.now().microsecondsSinceEpoch;
      const password = 'fictional audit passphrase 42';
      final email = 'audit-owner-$stamp@example.test';
      await auth.register(email, password);
      await auth.verifyEmail(email, await _confirmationCode(email));
      final serverSession = SupabaseServerSession(config, connection);
      addTearDown(serverSession.dispose);
      await serverSession.unlock(password);
      final clinic = await clinics.createClinic(
        name: 'Audit Demo $stamp',
        ownerDisplayName: 'Audit Owner',
        currencyCode: 'RUB',
        timeZone: 'Europe/Moscow',
      );
      final token = auth.accessToken!;
      final headers = {
        'apikey': config.publishableKey,
        'authorization': 'Bearer $token',
      };
      final requestId = _uuid();
      final recorded = await http.post<dynamic>(
        '/functions/v1/audit-events',
        data: {
          'clinicId': clinic.id,
          'intent': 'audit_log',
          'subjectId': clinic.id,
          'requestId': requestId,
        },
        options: Options(headers: headers),
      );
      expect(recorded.statusCode, 201, reason: '${recorded.data}');

      final today = DateTime.now().toUtc();
      final pageResponse = await http.get<dynamic>(
        '/functions/v1/audit-events',
        queryParameters: {
          'clinicId': clinic.id,
          'from': _date(today.subtract(const Duration(days: 2))),
          'to': _date(today.add(const Duration(days: 2))),
          'limit': 50,
        },
        options: Options(headers: headers),
      );
      expect(pageResponse.statusCode, 200, reason: '${pageResponse.data}');
      final decoded = pageResponse.data is String
          ? jsonDecode(pageResponse.data as String)
          : pageResponse.data;
      final page = decoded as Map<String, dynamic>;
      expect(page['clinicId'], clinic.id);
      expect(page['clinicTimeZone'], 'Europe/Moscow');
      final items = page['items'] as List<dynamic>;
      expect(items, isNotEmpty);
      expect(
        (items.first as Map<String, dynamic>)['eventType'],
        'audit_log_opened',
      );
      expect((items.first as Map<String, dynamic>)['actorEmail'], email);

      await expectLater(
        connection.client
            .from('audit_events')
            .update({'reason': 'must fail'})
            .eq('id', (items.first as Map<String, dynamic>)['id'] as String),
        throwsA(anything),
      );
    },
    skip: !const bool.fromEnvironment('RUN_LOCAL_AUDIT'),
    timeout: const Timeout(Duration(minutes: 2)),
  );
}

Future<String> _confirmationCode(String email) async {
  final inbox = Dio(BaseOptions(baseUrl: 'http://127.0.0.1:54324/api/v1'));
  try {
    for (var attempt = 0; attempt < 30; attempt++) {
      final messages =
          (await inbox.get<Map<String, dynamic>>('/messages')).data!['messages']
              as List<dynamic>;
      for (final raw in messages.reversed) {
        final message = raw as Map<String, dynamic>;
        final recipients = message['To'] as List<dynamic>;
        if (!recipients.any(
          (recipient) =>
              (recipient as Map<String, dynamic>)['Address'] == email,
        )) {
          continue;
        }
        final full = await inbox.get<Map<String, dynamic>>(
          '/message/${message['ID']}',
        );
        final body = '${full.data!['Text']} ${full.data!['HTML']}';
        final code =
            RegExp(r'token=([A-Za-z0-9_-]+)').firstMatch(body)?.group(1) ??
            RegExp(r'\b\d{6}\b').firstMatch(body)?.group(0);
        if (code != null) return code;
      }
      await Future<void>.delayed(const Duration(milliseconds: 200));
    }
    fail('Local inbox did not receive the audit test email code.');
  } finally {
    inbox.close(force: true);
  }
}

String _date(DateTime value) =>
    '${value.year.toString().padLeft(4, '0')}-'
    '${value.month.toString().padLeft(2, '0')}-'
    '${value.day.toString().padLeft(2, '0')}';

String _uuid() {
  final random = Random.secure();
  final bytes = Uint8List.fromList(
    List<int>.generate(16, (_) => random.nextInt(256)),
  );
  bytes[6] = (bytes[6] & 0x0f) | 0x40;
  bytes[8] = (bytes[8] & 0x3f) | 0x80;
  final value = bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
  return '${value.substring(0, 8)}-${value.substring(8, 12)}-'
      '${value.substring(12, 16)}-${value.substring(16, 20)}-'
      '${value.substring(20)}';
}

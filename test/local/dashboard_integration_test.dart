import 'dart:convert';

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
    'real local dashboard returns an authenticated active-clinic snapshot',
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
          connectTimeout: const Duration(seconds: 20),
          receiveTimeout: const Duration(seconds: 30),
          validateStatus: (status) => status != null && status < 600,
        ),
      );
      addTearDown(connection.dispose);
      addTearDown(clinicFunctions.dispose);
      addTearDown(() => http.close(force: true));

      final stamp = DateTime.now().microsecondsSinceEpoch;
      const password = 'fictional dashboard passphrase 42';
      final email = 'dashboard-owner-$stamp@example.test';
      await auth.register(email, password);
      await auth.verifyEmail(email, await _confirmationCode(email));
      final serverSession = SupabaseServerSession(config, connection);
      addTearDown(serverSession.dispose);
      await serverSession.unlock(password);
      final clinic = await clinics.createClinic(
        name: 'Dashboard Demo $stamp',
        ownerDisplayName: 'Dashboard Owner',
        currencyCode: 'RUB',
        timeZone: 'Europe/Moscow',
      );

      final response = await http.get<dynamic>(
        '/functions/v1/dashboard',
        queryParameters: {'clinicId': clinic.id},
        options: Options(
          headers: {
            'apikey': config.publishableKey,
            'authorization': 'Bearer ${auth.accessToken}',
          },
        ),
      );

      expect(response.statusCode, 200, reason: '${response.data}');
      final decoded = response.data is String
          ? jsonDecode(response.data as String)
          : response.data;
      expect(decoded, isA<Map<String, dynamic>>());
      final snapshot = decoded as Map<String, dynamic>;
      expect(snapshot['clinicId'], clinic.id);
      expect(snapshot['clinicTimeZone'], 'Europe/Moscow');
      expect(snapshot['generatedAt'], isA<String>());
      expect(snapshot['periods'], isA<Map<String, dynamic>>());
      expect(snapshot['capabilities'], {
        'canViewCompletedTreatments': true,
        'canViewFinancialSummary': true,
      });
      expect(snapshot['metrics'], {
        'totalPatients': 0,
        'appointmentsThisWeek': 0,
        'completedTreatmentsThisMonth': 0,
        'financial': {
          'outstandingInvoiceCount': 0,
          'outstandingAmount': '0.00',
          'currencyCode': 'RUB',
        },
      });
      expect(
        (snapshot['todayAppointments'] as Map<String, dynamic>)['items'],
        isEmpty,
      );
      expect(
        (snapshot['upcomingAppointments'] as Map<String, dynamic>)['items'],
        isEmpty,
      );
    },
    skip: !const bool.fromEnvironment('RUN_LOCAL_DASHBOARD'),
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
        final matches = recipients.any(
          (recipient) =>
              (recipient as Map<String, dynamic>)['Address'] == email,
        );
        if (!matches) continue;
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
    fail('Local inbox did not receive the dashboard test email code.');
  } finally {
    inbox.close(force: true);
  }
}

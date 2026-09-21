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
import 'package:dental_clini_management_saas/features/staff/data/supabase_staff_data_source.dart';
import 'package:dental_clini_management_saas/features/staff/data/supabase_staff_repository.dart';
import 'package:dental_clini_management_saas/features/staff/domain/staff_models.dart';
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
    'real local billing: exact totals, invoice number, overpayment credit, and Arabic PDF',
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
      final staff = SupabaseStaffRepository(
        SupabaseStaffDataSource(clinicFunctions),
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
      const password = 'fictional long billing passphrase 42';
      final email = 'billing-owner-$stamp@example.test';
      await auth.register(email, password);
      await auth.verifyEmail(email, await _confirmationCode(email));
      final serverSession = SupabaseServerSession(config, connection);
      addTearDown(serverSession.dispose);
      await serverSession.unlock(password);
      final clinic = await clinics.createClinic(
        name: 'Billing Demo $stamp',
        ownerDisplayName: 'Billing Owner',
        currencyCode: 'RUB',
        timeZone: 'Europe/Moscow',
      );
      final token = auth.accessToken!;
      final memberId = (await staff.getStaffMembers(clinic.id)).single.id;
      await staff.replaceMemberRoles(
        clinicId: clinic.id,
        memberId: memberId,
        roles: {StaffRole.owner, StaffRole.dentist},
        ownerPassword: password,
      );

      final patientResponse = await _call(http, config, token, 'patients', {
        'action': 'create',
        'clinicId': clinic.id,
        'demographic': {
          'firstName': 'Amal',
          'lastName': 'Demo',
          'middleName': null,
          'phone': '+79990000000',
          'email': null,
          'birthDate': null,
          'birthDatePrecision': 'unknown',
          'approximateAgeYears': null,
          'ageAssessedAt': null,
          'isMinorDeclared': false,
          'guardianName': null,
          'guardianPhone': null,
          'guardianEmail': null,
          'administrativeNotes': null,
        },
      });
      expect(
        patientResponse.statusCode,
        201,
        reason: '${patientResponse.data}',
      );
      final patientId = patientResponse.data!['patientId'] as String;

      final procedureResponse = await _call(
        http,
        config,
        token,
        'treatment-plans',
        {
          'action': 'create_procedure',
          'clinicId': clinic.id,
          'procedure': {
            'name': 'Demo crown',
            'category': 'Restoration',
            'defaultPrice': '1250.25',
            'durationMinutes': 60,
          },
        },
      );
      expect(procedureResponse.statusCode, 201);
      final procedureId = procedureResponse.data!['procedureId'] as String;

      final created = await _call(http, config, token, 'billing', {
        'action': 'create_invoice_draft',
        'patientId': patientId,
        'locale': 'ar',
        'commandId': _uuid(),
      });
      expect(created.statusCode, 201);
      final invoiceId = created.data!['invoiceId'] as String;

      final added = await _call(http, config, token, 'billing', {
        'action': 'add_invoice_item',
        'invoiceId': invoiceId,
        'procedureId': procedureId,
        'quantity': '1.00',
        'revision': 1,
      });
      expect(added.statusCode, 201);
      final itemId = added.data!['itemId'] as String;
      expect(
        (await _call(http, config, token, 'billing', {
          'action': 'approve_invoice_content',
          'invoiceId': invoiceId,
          'revision': 2,
          'approved': true,
        })).statusCode,
        200,
      );
      expect(
        (await _call(http, config, token, 'billing', {
          'action': 'set_invoice_financials',
          'invoiceId': invoiceId,
          'revision': 3,
          'itemPrices': [
            {'itemId': itemId, 'unitPrice': '1250.25'},
          ],
          'discountType': 'fixed',
          'discountValue': '50.25',
          'taxRate': '10.00',
          'locale': 'ar',
        })).statusCode,
        200,
      );
      final finalized = await _call(http, config, token, 'billing', {
        'action': 'finalize_invoice',
        'invoiceId': invoiceId,
        'revision': 4,
        'commandId': _uuid(),
      });
      expect(finalized.statusCode, 200);
      expect(finalized.data!['invoiceNumber'], 'INV-00001');
      final paymentCommandId = _uuid();
      final paymentReceivedAt = DateTime.now().toUtc().toIso8601String();
      final paymentCommand = {
        'action': 'record_payment',
        'invoiceId': invoiceId,
        'amount': '1330.00',
        'method': 'card',
        'reference': 'DEMO',
        'receivedAt': paymentReceivedAt,
        'commandId': paymentCommandId,
      };
      final paymentResponses = await Future.wait([
        _call(http, config, token, 'billing', paymentCommand),
        _call(http, config, token, 'billing', paymentCommand),
      ]);
      expect(
        paymentResponses.map((response) => response.statusCode),
        everyElement(201),
      );
      expect(
        paymentResponses[0].data!['paymentId'],
        paymentResponses[1].data!['paymentId'],
      );

      final invoicesResponse = await _call(http, config, token, 'billing', {
        'action': 'read_invoices',
        'clinicId': clinic.id,
        'patientId': patientId,
      });
      expect(invoicesResponse.statusCode, 200);
      final invoice = (invoicesResponse.data!['rows'] as List<dynamic>)
          .cast<Map<String, dynamic>>()
          .singleWhere((row) => row['id'] == invoiceId);
      expect(invoice['total'], '1320.00');
      expect(invoice['paid_amount'], '1320.00');
      expect(invoice['outstanding_balance'], '0.00');
      final creditResponse = await _call(http, config, token, 'billing', {
        'action': 'read_credit',
        'patientId': patientId,
        'currencyCode': 'RUB',
      });
      expect(creditResponse.statusCode, 200);
      final credit = creditResponse.data!['row'] as Map<String, dynamic>;
      expect(credit['balance'], '10.00');

      final paymentsResponse = await _call(http, config, token, 'billing', {
        'action': 'read_payments',
        'invoiceId': invoiceId,
      });
      expect(paymentsResponse.statusCode, 200);
      expect(paymentsResponse.data!['rows'] as List<dynamic>, hasLength(1));

      final pdfResponse = await _call(http, config, token, 'invoice-pdf', {
        'invoiceId': invoiceId,
        'locale': 'ar',
      });
      expect(pdfResponse.statusCode, 200, reason: '${pdfResponse.data}');
      final rawPdfUrl = Uri.parse(pdfResponse.data!['url'] as String);
      final pdfUrl = rawPdfUrl.hasScheme
          ? rawPdfUrl
          : config.supabaseUrl!.resolveUri(rawPdfUrl);
      final bytes = await http.get<List<int>>(
        pdfUrl.toString(),
        options: Options(responseType: ResponseType.bytes),
      );
      expect(bytes.statusCode, 200);
      expect(String.fromCharCodes(bytes.data!.take(4)), '%PDF');
    },
    skip: !const bool.fromEnvironment('RUN_LOCAL_BILLING'),
    timeout: const Timeout(Duration(minutes: 3)),
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
    fail('Local inbox did not receive the billing test email code.');
  } finally {
    inbox.close(force: true);
  }
}

Future<Response<Map<String, dynamic>>> _call(
  Dio http,
  AppConfig config,
  String token,
  String function,
  Map<String, dynamic> body,
) => http.post<Map<String, dynamic>>(
  '/functions/v1/$function',
  data: body,
  options: Options(
    headers: {
      'apikey': config.publishableKey,
      'authorization': 'Bearer $token',
    },
  ),
);

String _uuid() {
  final random = Random.secure();
  final bytes = Uint8List.fromList(
    List<int>.generate(16, (_) => random.nextInt(256)),
  );
  bytes[6] = (bytes[6] & 0x0f) | 0x40;
  bytes[8] = (bytes[8] & 0x3f) | 0x80;
  final value = bytes
      .map((byte) => byte.toRadixString(16).padLeft(2, '0'))
      .join();
  return '${value.substring(0, 8)}-${value.substring(8, 12)}-'
      '${value.substring(12, 16)}-${value.substring(16, 20)}-'
      '${value.substring(20)}';
}

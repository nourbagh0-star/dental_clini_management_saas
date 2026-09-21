import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import 'package:dental_clini_management_saas/core/auth/server_session.dart';
import 'package:dental_clini_management_saas/core/config/app_config.dart';
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
    'real local MVP: owner, dentist, receptionist, patient, care, billing, and audit',
    () async {
      final config = AppConfig.fromEnvironment();
      expect(config.supabaseUrl?.host, anyOf('127.0.0.1', 'localhost'));

      final ownerConnection = SupabaseConnection(config);
      final receptionistConnection = SupabaseConnection(config);
      final ownerAuth = _auth(ownerConnection, config);
      final receptionistAuth = _auth(receptionistConnection, config);
      final ownerClient = DioClient(config, ownerAuth);
      final ownerClinics = SupabaseClinicRepository(
        SupabaseClinicDataSource(ownerClient),
      );
      final ownerStaff = SupabaseStaffRepository(
        SupabaseStaffDataSource(ownerClient),
      );
      final http = Dio(
        BaseOptions(
          baseUrl: config.supabaseUrl.toString(),
          connectTimeout: const Duration(seconds: 20),
          receiveTimeout: const Duration(seconds: 30),
          validateStatus: (status) => status != null && status < 600,
        ),
      );
      final inbox = Dio(
        BaseOptions(
          baseUrl: 'http://127.0.0.1:54324/api/v1',
          connectTimeout: const Duration(seconds: 5),
        ),
      );
      addTearDown(ownerConnection.dispose);
      addTearDown(receptionistConnection.dispose);
      addTearDown(ownerClient.dispose);
      addTearDown(() => http.close(force: true));
      addTearDown(() => inbox.close(force: true));

      final stamp = DateTime.now().microsecondsSinceEpoch;
      const password = 'fictional MVP test passphrase 42';
      final ownerEmail = 'mvp-owner-$stamp@example.test';
      final receptionistEmail = 'mvp-reception-$stamp@example.test';

      await _registerAndVerify(ownerAuth, inbox, ownerEmail, password);
      await _registerAndVerify(
        receptionistAuth,
        inbox,
        receptionistEmail,
        password,
      );
      final ownerSession = SupabaseServerSession(config, ownerConnection);
      final receptionistSession = SupabaseServerSession(
        config,
        receptionistConnection,
      );
      addTearDown(ownerSession.dispose);
      addTearDown(receptionistSession.dispose);
      await ownerSession.unlock(password);
      await receptionistSession.unlock(password);

      final clinic = await ownerClinics.createClinic(
        name: 'DentaFlow Fictional Clinic $stamp',
        ownerDisplayName: 'Workflow Owner',
        currencyCode: 'RUB',
        timeZone: 'Europe/Moscow',
      );
      final ownerMember = (await ownerStaff.getStaffMembers(clinic.id)).single;
      await ownerStaff.replaceMemberRoles(
        clinicId: clinic.id,
        memberId: ownerMember.id,
        roles: {StaffRole.owner, StaffRole.dentist},
        ownerPassword: password,
      );

      final invitation = await _call(
        http,
        config,
        ownerAuth.accessToken!,
        'staff-invitations',
        {
          'action': 'create',
          'clinicId': clinic.id,
          'email': receptionistEmail,
          'roles': ['receptionist'],
          'appOrigin': 'http://localhost:3000',
        },
      );
      expect(invitation.statusCode, 201, reason: '${invitation.data}');
      final invitationToken = await _readInvitationToken(
        inbox,
        receptionistEmail,
      );
      final accepted = await _call(
        http,
        config,
        receptionistAuth.accessToken!,
        'staff-invitations',
        {'action': 'accept', 'token': invitationToken},
      );
      expect(accepted.statusCode, 200, reason: '${accepted.data}');
      final reused = await _call(
        http,
        config,
        receptionistAuth.accessToken!,
        'staff-invitations',
        {'action': 'accept', 'token': invitationToken},
      );
      expect(reused.statusCode, 403, reason: '${reused.data}');

      final effectiveFrom = _date(
        DateTime.now().toUtc().add(const Duration(days: 2)),
      );
      final schedule = await _call(
        http,
        config,
        ownerAuth.accessToken!,
        'doctor-schedules',
        {
          'action': 'replace_weekly',
          'dentistMemberId': ownerMember.id,
          'effectiveFrom': effectiveFrom,
          'periods': [
            for (var weekday = 1; weekday <= 7; weekday++)
              {
                'weekday': weekday,
                'startsAt': '08:00',
                'endsAt': '20:00',
                'breaks': <Map<String, String>>[],
              },
          ],
          'confirmAffectedAppointments': false,
          'appointmentImpactReason': null,
        },
      );
      expect(schedule.statusCode, 200, reason: '${schedule.data}');

      final patient = await _call(
        http,
        config,
        receptionistAuth.accessToken!,
        'patients',
        {
          'action': 'create',
          'clinicId': clinic.id,
          'demographic': {
            'firstName': 'Layla',
            'lastName': 'Fictional',
            'middleName': null,
            'phone': '+79990000001',
            'email': 'layla.fictional-$stamp@example.test',
            'birthDate': '1992-04-15',
            'birthDatePrecision': 'exact',
            'approximateAgeYears': null,
            'ageAssessedAt': null,
            'isMinorDeclared': false,
            'guardianName': null,
            'guardianPhone': null,
            'guardianEmail': null,
            'address': 'Fictional address',
            'gender': null,
            'emergencyContact': null,
            'administrativeNotes': 'Demo record only',
          },
        },
      );
      expect(patient.statusCode, 201, reason: '${patient.data}');
      final patientId = patient.data!['patientId'] as String;

      final appointmentStart = DateTime.now()
          .toUtc()
          .add(const Duration(days: 3))
          .copyWith(
            hour: 10,
            minute: 0,
            second: 0,
            millisecond: 0,
            microsecond: 0,
          );
      final appointment = await _call(
        http,
        config,
        receptionistAuth.accessToken!,
        'appointments',
        {
          'action': 'create',
          'clinicId': clinic.id,
          'patientId': patientId,
          'dentistMemberId': ownerMember.id,
          'startsAt': appointmentStart.toIso8601String(),
          'endsAt': appointmentStart
              .add(const Duration(minutes: 45))
              .toIso8601String(),
          'purpose': 'Fictional routine examination',
          'overrideReason': null,
        },
      );
      expect(appointment.statusCode, 201, reason: '${appointment.data}');
      final appointmentId = appointment.data!['appointmentId'] as String;
      final confirmed = await _call(
        http,
        config,
        receptionistAuth.accessToken!,
        'appointments',
        {'action': 'confirm', 'appointmentId': appointmentId},
      );
      expect(confirmed.statusCode, 200, reason: '${confirmed.data}');

      final forbiddenMedical =
          await _call(http, config, receptionistAuth.accessToken!, 'patients', {
            'action': 'upsert_medical',
            'patientId': patientId,
            'medical': _fictionalMedical,
          });
      expect(
        forbiddenMedical.statusCode,
        403,
        reason: '${forbiddenMedical.data}',
      );

      final medical =
          await _call(http, config, ownerAuth.accessToken!, 'patients', {
            'action': 'upsert_medical',
            'patientId': patientId,
            'medical': _fictionalMedical,
          });
      expect(medical.statusCode, 200, reason: '${medical.data}');
      final condition = await _call(
        http,
        config,
        ownerAuth.accessToken!,
        'odontogram',
        {
          'action': 'create_condition',
          'patientId': patientId,
          'condition': {
            'toothNumber': 16,
            'surface': 'occlusal',
            'conditionType': 'caries',
            'notes': 'Fictional chart finding',
          },
        },
      );
      expect(condition.statusCode, 201, reason: '${condition.data}');

      final procedure = await _call(
        http,
        config,
        ownerAuth.accessToken!,
        'treatment-plans',
        {
          'action': 'create_procedure',
          'clinicId': clinic.id,
          'procedure': {
            'name': 'Fictional composite restoration',
            'category': 'Restorative',
            'defaultPrice': '750.00',
            'durationMinutes': 45,
          },
        },
      );
      expect(procedure.statusCode, 201, reason: '${procedure.data}');
      final procedureId = procedure.data!['procedureId'] as String;
      final plan =
          await _call(http, config, ownerAuth.accessToken!, 'treatment-plans', {
            'action': 'create_plan',
            'patientId': patientId,
            'dentistMemberId': ownerMember.id,
            'notes': 'Fictional treatment plan',
          });
      expect(plan.statusCode, 201, reason: '${plan.data}');
      final planId = plan.data!['planId'] as String;
      final planItem = await _call(
        http,
        config,
        ownerAuth.accessToken!,
        'treatment-plans',
        {
          'action': 'add_plan_item',
          'planId': planId,
          'item': {
            'procedureId': procedureId,
            'toothNumber': 16,
            'description': 'Fictional restoration item',
            'estimatedPrice': '750.00',
            'assignedDentistId': ownerMember.id,
          },
        },
      );
      expect(planItem.statusCode, 201, reason: '${planItem.data}');
      final planItemId = planItem.data!['itemId'] as String;
      await _expectAction(
        http,
        config,
        ownerAuth.accessToken!,
        'treatment-plans',
        {'action': 'transition_plan', 'planId': planId, 'status': 'active'},
      );
      await _expectAction(
        http,
        config,
        ownerAuth.accessToken!,
        'treatment-plans',
        {
          'action': 'transition_plan_item',
          'itemId': planItemId,
          'status': 'in_progress',
        },
      );
      await _expectAction(
        http,
        config,
        ownerAuth.accessToken!,
        'treatment-plans',
        {
          'action': 'transition_plan_item',
          'itemId': planItemId,
          'status': 'completed',
        },
      );
      await _expectAction(
        http,
        config,
        ownerAuth.accessToken!,
        'treatment-plans',
        {'action': 'transition_plan', 'planId': planId, 'status': 'completed'},
      );

      final clinical = await _call(
        http,
        config,
        ownerAuth.accessToken!,
        'clinical-sessions',
        {
          'action': 'create_session',
          'patientId': patientId,
          'appointmentId': null,
          'dentistMemberId': ownerMember.id,
          'sessionDate': DateTime.now()
              .toUtc()
              .subtract(const Duration(minutes: 1))
              .toIso8601String(),
        },
      );
      expect(clinical.statusCode, 201, reason: '${clinical.data}');
      final sessionId = clinical.data!['sessionId'] as String;
      await _expectAction(
        http,
        config,
        ownerAuth.accessToken!,
        'clinical-sessions',
        {
          'action': 'update_draft_session',
          'sessionId': sessionId,
          'clinicalNotes': 'Fictional examination and treatment notes',
          'recommendations': 'Fictional follow-up recommendation',
          'expectedRevision': 1,
        },
      );
      await _expectAction(
        http,
        config,
        ownerAuth.accessToken!,
        'clinical-sessions',
        {
          'action': 'finalize_session',
          'sessionId': sessionId,
          'expectedRevision': 2,
        },
      );

      final invoice =
          await _call(http, config, ownerAuth.accessToken!, 'billing', {
            'action': 'create_invoice_draft',
            'patientId': patientId,
            'locale': 'en',
            'commandId': _uuid(),
          });
      expect(invoice.statusCode, 201, reason: '${invoice.data}');
      final invoiceId = invoice.data!['invoiceId'] as String;
      final invoiceItem =
          await _call(http, config, ownerAuth.accessToken!, 'billing', {
            'action': 'add_invoice_item',
            'invoiceId': invoiceId,
            'procedureId': procedureId,
            'treatmentPlanItemId': planItemId,
            'quantity': '1.00',
            'revision': 1,
          });
      expect(invoiceItem.statusCode, 201, reason: '${invoiceItem.data}');
      final invoiceItemId = invoiceItem.data!['itemId'] as String;
      await _expectAction(http, config, ownerAuth.accessToken!, 'billing', {
        'action': 'approve_invoice_content',
        'invoiceId': invoiceId,
        'revision': 2,
        'approved': true,
      });
      await _expectAction(http, config, ownerAuth.accessToken!, 'billing', {
        'action': 'set_invoice_financials',
        'invoiceId': invoiceId,
        'revision': 3,
        'itemPrices': [
          {'itemId': invoiceItemId, 'unitPrice': '750.00'},
        ],
        'discountType': 'none',
        'discountValue': '0.00',
        'taxRate': '0.00',
        'locale': 'en',
      });
      final finalizedInvoice =
          await _call(http, config, ownerAuth.accessToken!, 'billing', {
            'action': 'finalize_invoice',
            'invoiceId': invoiceId,
            'revision': 4,
            'commandId': _uuid(),
          });
      expect(
        finalizedInvoice.statusCode,
        200,
        reason: '${finalizedInvoice.data}',
      );
      expect(finalizedInvoice.data!['invoiceNumber'], 'INV-00001');
      final payment =
          await _call(http, config, receptionistAuth.accessToken!, 'billing', {
            'action': 'record_payment',
            'invoiceId': invoiceId,
            'amount': '750.00',
            'method': 'card',
            'reference': 'FICTIONAL-MVP',
            'receivedAt': DateTime.now().toUtc().toIso8601String(),
            'commandId': _uuid(),
          });
      expect(payment.statusCode, 201, reason: '${payment.data}');

      final dashboard = await http.get<dynamic>(
        '/functions/v1/dashboard',
        queryParameters: {'clinicId': clinic.id},
        options: _options(config, ownerAuth.accessToken!),
      );
      expect(dashboard.statusCode, 200, reason: '${dashboard.data}');
      final dashboardBody = _jsonMap(dashboard.data);
      final metrics = dashboardBody['metrics'] as Map<String, dynamic>;
      expect(metrics['totalPatients'], 1);
      expect(dashboardBody['capabilities'], {
        'canViewCompletedTreatments': true,
        'canViewFinancialSummary': true,
      });

      final auditRequestId = _uuid();
      final auditRecorded = await http.post<dynamic>(
        '/functions/v1/audit-events',
        data: {
          'clinicId': clinic.id,
          'intent': 'audit_log',
          'subjectId': clinic.id,
          'requestId': auditRequestId,
        },
        options: _options(config, ownerAuth.accessToken!),
      );
      expect(auditRecorded.statusCode, 201, reason: '${auditRecorded.data}');
      final from = _date(
        DateTime.now().toUtc().subtract(const Duration(days: 2)),
      );
      final to = _date(DateTime.now().toUtc().add(const Duration(days: 2)));
      final ownerAudit = await http.get<dynamic>(
        '/functions/v1/audit-events',
        queryParameters: {
          'clinicId': clinic.id,
          'from': from,
          'to': to,
          'limit': 50,
        },
        options: _options(config, ownerAuth.accessToken!),
      );
      expect(ownerAudit.statusCode, 200, reason: '${ownerAudit.data}');
      expect(_jsonMap(ownerAudit.data)['items'] as List<dynamic>, isNotEmpty);
      final receptionistAudit = await http.get<dynamic>(
        '/functions/v1/audit-events',
        queryParameters: {
          'clinicId': clinic.id,
          'from': from,
          'to': to,
          'limit': 50,
        },
        options: _options(config, receptionistAuth.accessToken!),
      );
      expect(
        receptionistAudit.statusCode,
        403,
        reason: '${receptionistAudit.data}',
      );
    },
    skip: !const bool.fromEnvironment('RUN_LOCAL_MVP'),
    timeout: const Timeout(Duration(minutes: 5)),
  );
}

const _fictionalMedical = <String, dynamic>{
  'allergies': 'Fictional: none reported',
  'currentMedications': 'Fictional: none',
  'chronicConditions': 'Fictional: none',
  'importantMedicalNotes': 'Demo data only',
};

SupabaseAuthRepository _auth(SupabaseConnection connection, AppConfig config) =>
    SupabaseAuthRepository(
      SupabaseAuthDataSource(connection, config),
      _MemorySession(),
    );

Future<void> _registerAndVerify(
  SupabaseAuthRepository repository,
  Dio inbox,
  String email,
  String password,
) async {
  await repository.register(email, password);
  await repository.verifyEmail(
    email,
    await _readConfirmationCode(inbox, email),
  );
}

Future<String> _readConfirmationCode(Dio inbox, String email) async {
  for (var attempt = 0; attempt < 30; attempt++) {
    final response = await inbox.get<Map<String, dynamic>>('/messages');
    final messages = response.data!['messages'] as List<dynamic>;
    for (final raw in messages.reversed) {
      final message = raw as Map<String, dynamic>;
      final recipients = message['To'] as List<dynamic>;
      final matches = recipients.any(
        (recipient) => (recipient as Map<String, dynamic>)['Address'] == email,
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
  fail('Local inbox did not receive the expected confirmation code.');
}

Future<String> _readInvitationToken(Dio inbox, String email) async {
  for (var attempt = 0; attempt < 30; attempt++) {
    final response = await inbox.get<Map<String, dynamic>>('/messages');
    final messages = response.data!['messages'] as List<dynamic>;
    for (final raw in messages.reversed) {
      final message = raw as Map<String, dynamic>;
      final recipients = message['To'] as List<dynamic>;
      final matches = recipients.any(
        (recipient) => (recipient as Map<String, dynamic>)['Address'] == email,
      );
      if (!matches) continue;
      final full = await inbox.get<Map<String, dynamic>>(
        '/message/${message['ID']}',
      );
      final body = '${full.data!['Text']} ${full.data!['HTML']}';
      final token = RegExp(
        r'#token=([A-Za-z0-9_-]{43})',
      ).firstMatch(body)?.group(1);
      if (token != null) return token;
    }
    await Future<void>.delayed(const Duration(milliseconds: 200));
  }
  fail('Local inbox did not receive the expected invitation link.');
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
  options: _options(config, token),
);

Future<void> _expectAction(
  Dio http,
  AppConfig config,
  String token,
  String function,
  Map<String, dynamic> body,
) async {
  final response = await _call(http, config, token, function, body);
  expect(response.statusCode, 200, reason: '${response.data}');
}

Options _options(AppConfig config, String token) => Options(
  headers: {'apikey': config.publishableKey, 'authorization': 'Bearer $token'},
);

Map<String, dynamic> _jsonMap(dynamic value) => value is String
    ? jsonDecode(value) as Map<String, dynamic>
    : value as Map<String, dynamic>;

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
  final value = bytes
      .map((byte) => byte.toRadixString(16).padLeft(2, '0'))
      .join();
  return '${value.substring(0, 8)}-${value.substring(8, 12)}-'
      '${value.substring(12, 16)}-${value.substring(16, 20)}-'
      '${value.substring(20)}';
}

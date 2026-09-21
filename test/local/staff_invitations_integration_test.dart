import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:dental_clini_management_saas/core/auth/server_session.dart';
import 'package:dental_clini_management_saas/core/config/app_config.dart';
import 'package:dental_clini_management_saas/core/network/dio_client.dart';
import 'package:dental_clini_management_saas/core/network/supabase_connection.dart';
import 'package:dental_clini_management_saas/core/storage/auth_session_store.dart';
import 'package:dental_clini_management_saas/features/auth/data/supabase_auth_data_source.dart';
import 'package:dental_clini_management_saas/features/auth/data/supabase_auth_repository.dart';
import 'package:dental_clini_management_saas/features/auth/domain/auth_models.dart';
import 'package:dental_clini_management_saas/features/clinic/data/supabase_clinic_data_source.dart';
import 'package:dental_clini_management_saas/features/clinic/data/supabase_clinic_repository.dart';
import 'package:dental_clini_management_saas/features/staff/data/supabase_staff_data_source.dart';
import 'package:dental_clini_management_saas/features/staff/data/supabase_staff_repository.dart';
import 'package:dental_clini_management_saas/features/staff/domain/staff_models.dart';

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
    'owner-created staff: forced password change and protected API access',
    () async {
      final config = AppConfig.fromEnvironment();
      expect(config.supabaseUrl?.host, anyOf('127.0.0.1', 'localhost'));
      final ownerConnection = SupabaseConnection(config);
      final staffConnection = SupabaseConnection(config);
      final owner = _repository(ownerConnection, config);
      final employee = _repository(staffConnection, config);
      final ownerLease = SupabaseServerSession(config, ownerConnection);
      final employeeLease = SupabaseServerSession(config, staffConnection);
      final api = DioClient(config, owner);
      final staff = SupabaseStaffRepository(SupabaseStaffDataSource(api));
      final clinics = SupabaseClinicRepository(SupabaseClinicDataSource(api));
      final inbox = Dio(BaseOptions(baseUrl: 'http://127.0.0.1:54324/api/v1'));
      final raw = Dio(
        BaseOptions(
          baseUrl: config.supabaseUrl.toString(),
          validateStatus: (status) => status != null && status < 600,
        ),
      );
      addTearDown(ownerConnection.dispose);
      addTearDown(staffConnection.dispose);
      addTearDown(ownerLease.dispose);
      addTearDown(employeeLease.dispose);
      addTearDown(api.dispose);
      addTearDown(() => inbox.close(force: true));
      addTearDown(() => raw.close(force: true));
      final stamp = DateTime.now().microsecondsSinceEpoch;
      final ownerEmail = 'provision-owner-$stamp@example.test';
      final staffEmail = 'provision-staff-$stamp@example.test';
      const ownerPassword = 'fictional owner passphrase 42';
      const temporary = 'fictional temporary passphrase 43';
      const replacement = 'fictional replacement passphrase 44';
      await _registerAndVerify(owner, inbox, ownerEmail, ownerPassword);
      await ownerLease.unlock(ownerPassword);
      final clinic = await clinics.createClinic(
        name: 'Fictional provision test $stamp',
        ownerDisplayName: 'Provision Owner',
        currencyCode: 'USD',
        timeZone: 'Asia/Damascus',
      );
      final input = <String, dynamic>{
        'action': 'create_account',
        'clinicId': clinic.id,
        'displayName': 'Provision Dentist',
        'email': staffEmail,
        'roles': ['dentist'],
        'temporaryPassword': temporary,
        'ownerPassword': 'wrong password',
      };
      expect(
        (await _call(raw, config, owner.accessToken!, input)).statusCode,
        403,
      );
      await staff.createAccount(
        clinicId: clinic.id,
        displayName: 'Provision Dentist',
        email: staffEmail,
        roles: {StaffRole.dentist},
        temporaryPassword: temporary,
        ownerPassword: ownerPassword,
      );
      expect(
        (await staff.getStaffMembers(clinic.id)).any(
          (m) => m.email == staffEmail && m.roles.contains(StaffRole.dentist),
        ),
        isTrue,
      );
      input['ownerPassword'] = ownerPassword;
      expect(
        (await _call(raw, config, owner.accessToken!, input)).statusCode,
        409,
      );
      await employee.login(staffEmail, temporary);
      final oldToken = employee.accessToken!;
      await expectLater(
        employeeLease.unlock(temporary),
        throwsA(
          isA<ServerSessionException>().having(
            (e) => e.kind,
            'kind',
            ServerSessionIssue.passwordChangeRequired,
          ),
        ),
      );
      expect(
        (await _call(raw, config, oldToken, {
          'action': 'list_members',
          'clinicId': clinic.id,
        })).statusCode,
        401,
      );
      await expectLater(
        employeeLease.completePasswordSetup(),
        throwsA(isA<ServerSessionException>()),
      );
      await employee.changeInitialPassword(replacement);
      await employeeLease.completePasswordSetup();
      expect(
        (await _call(raw, config, oldToken, {
          'action': 'list_members',
          'clinicId': clinic.id,
        })).statusCode,
        401,
      );
      await employee.logout(global: true);
      await expectLater(
        employee.login(staffEmail, temporary),
        throwsA(isA<AuthOperationException>()),
      );
      await employee.login(staffEmail, replacement);
      await employeeLease.unlock(replacement);
      input['email'] = 'cannot-create-$stamp@example.test';
      input['ownerPassword'] = replacement;
      expect(
        (await _call(raw, config, employee.accessToken!, input)).statusCode,
        403,
      );
    },
    skip: !const bool.fromEnvironment('RUN_LOCAL_STAFF'),
    timeout: const Timeout(Duration(minutes: 3)),
  );
  test(
    'real local staff invitations: delivery, one-time acceptance, roles, and activation',
    () async {
      final config = AppConfig.fromEnvironment();
      expect(config.supabaseUrl?.host, anyOf('127.0.0.1', 'localhost'));

      final ownerConnection = SupabaseConnection(config);
      final inviteeConnection = SupabaseConnection(config);
      final mismatchConnection = SupabaseConnection(config);
      final owner = _repository(ownerConnection, config);
      final invitee = _repository(inviteeConnection, config);
      final mismatch = _repository(mismatchConnection, config);
      final clinicFunctions = DioClient(config, owner);
      final clinics = SupabaseClinicRepository(
        SupabaseClinicDataSource(clinicFunctions),
      );
      final staffFunctions = DioClient(config, owner);
      final staff = SupabaseStaffRepository(
        SupabaseStaffDataSource(staffFunctions),
      );
      final inbox = Dio(
        BaseOptions(
          baseUrl: 'http://127.0.0.1:54324/api/v1',
          connectTimeout: const Duration(seconds: 5),
        ),
      );
      final functions = Dio(
        BaseOptions(
          baseUrl: config.supabaseUrl.toString(),
          connectTimeout: const Duration(seconds: 10),
          receiveTimeout: const Duration(seconds: 10),
          validateStatus: (status) => status != null && status < 600,
        ),
      );
      addTearDown(ownerConnection.dispose);
      addTearDown(inviteeConnection.dispose);
      addTearDown(mismatchConnection.dispose);
      addTearDown(staffFunctions.dispose);
      addTearDown(clinicFunctions.dispose);
      addTearDown(() => inbox.close(force: true));
      addTearDown(() => functions.close(force: true));

      final stamp = DateTime.now().microsecondsSinceEpoch;
      const password = 'fictional long test passphrase 42';
      final ownerEmail = 'staff-owner-$stamp@example.test';
      final inviteeEmail = 'staff-invitee-$stamp@example.test';
      final mismatchEmail = 'staff-mismatch-$stamp@example.test';
      final usedInvitationMessages = <String>{};
      await _registerAndVerify(owner, inbox, ownerEmail, password);
      await _registerAndVerify(invitee, inbox, inviteeEmail, password);
      await _registerAndVerify(mismatch, inbox, mismatchEmail, password);
      final ownerServerSession = SupabaseServerSession(config, ownerConnection);
      final inviteeServerSession = SupabaseServerSession(
        config,
        inviteeConnection,
      );
      final mismatchServerSession = SupabaseServerSession(
        config,
        mismatchConnection,
      );
      addTearDown(ownerServerSession.dispose);
      addTearDown(inviteeServerSession.dispose);
      addTearDown(mismatchServerSession.dispose);
      await ownerServerSession.unlock(password);
      await inviteeServerSession.unlock(password);
      await mismatchServerSession.unlock(password);
      final clinic = await clinics.createClinic(
        name: 'Staff Demo $stamp',
        ownerDisplayName: 'Staff Owner',
        currencyCode: 'RUB',
        timeZone: 'Europe/Moscow',
      );
      final ownerToken = owner.accessToken!;
      final inviteeToken = invitee.accessToken!;
      final mismatchToken = mismatch.accessToken!;

      final ownerWithoutPassword = await _call(functions, config, ownerToken, {
        'action': 'create',
        'clinicId': clinic.id,
        'email': 'future-owner-$stamp@example.test',
        'roles': ['owner'],
        'appOrigin': 'http://localhost:3000',
      });
      expect(ownerWithoutPassword.statusCode, 403);
      expect(
        ownerWithoutPassword.data?['error'],
        'owner_reauthentication_required',
      );

      final created = await _call(functions, config, ownerToken, {
        'action': 'create',
        'clinicId': clinic.id,
        'email': inviteeEmail,
        'roles': ['assistant'],
        'appOrigin': 'http://localhost:3000',
      });
      expect(created.statusCode, 201);
      final invitationId = created.data!['invitationId'] as String;
      final firstToken = await _readInvitationToken(
        inbox,
        inviteeEmail,
        usedInvitationMessages,
      );

      final resent = await _call(functions, config, ownerToken, {
        'action': 'resend',
        'invitationId': invitationId,
        'appOrigin': 'http://localhost:3000',
      });
      expect(resent.statusCode, 200);
      final secondToken = await _readInvitationToken(
        inbox,
        inviteeEmail,
        usedInvitationMessages,
      );
      expect(secondToken, isNot(firstToken));

      final staleAcceptance = await _call(functions, config, inviteeToken, {
        'action': 'accept',
        'token': firstToken,
      });
      expect(staleAcceptance.statusCode, 403);

      final revoked = await _call(functions, config, ownerToken, {
        'action': 'revoke',
        'invitationId': invitationId,
      });
      expect(revoked.statusCode, 200);
      final revokedAcceptance = await _call(functions, config, inviteeToken, {
        'action': 'accept',
        'token': secondToken,
      });
      expect(revokedAcceptance.statusCode, 403);

      final replacement = await _call(functions, config, ownerToken, {
        'action': 'create',
        'clinicId': clinic.id,
        'email': inviteeEmail,
        'roles': ['assistant'],
        'appOrigin': 'http://localhost:3000',
      });
      expect(replacement.statusCode, 201);
      final acceptedToken = await _readInvitationToken(
        inbox,
        inviteeEmail,
        usedInvitationMessages,
      );

      final mismatchedAcceptance = await _call(
        functions,
        config,
        mismatchToken,
        {'action': 'accept', 'token': acceptedToken},
      );
      expect(mismatchedAcceptance.statusCode, 403);

      final accepted = await _call(functions, config, inviteeToken, {
        'action': 'accept',
        'token': acceptedToken,
      });
      expect(accepted.statusCode, 200);
      expect(accepted.data?['clinicId'], clinic.id);
      final reusedAcceptance = await _call(functions, config, inviteeToken, {
        'action': 'accept',
        'token': acceptedToken,
      });
      expect(reusedAcceptance.statusCode, 403);

      final acceptedDirectory = await staff.getStaffMembers(clinic.id);
      final staffMemberId = acceptedDirectory
          .singleWhere((member) => member.email == inviteeEmail)
          .id;
      final promotionWithoutPassword = await _call(
        functions,
        config,
        ownerToken,
        {
          'action': 'replace_roles',
          'memberId': staffMemberId,
          'roles': ['assistant', 'owner'],
        },
      );
      expect(promotionWithoutPassword.statusCode, 403);
      expect(
        promotionWithoutPassword.data?['error'],
        'owner_reauthentication_required',
      );

      final roleChange = await _call(functions, config, ownerToken, {
        'action': 'replace_roles',
        'memberId': staffMemberId,
        'roles': ['dentist'],
      });
      expect(roleChange.statusCode, 200);
      final changedMember = (await staff.getStaffMembers(
        clinic.id,
      )).singleWhere((member) => member.id == staffMemberId);
      expect(changedMember.roles, {StaffRole.dentist});

      await staff.setMemberActive(
        clinicId: clinic.id,
        memberId: staffMemberId,
        isActive: false,
        ownerPassword: password,
      );
      await staff.setMemberActive(
        clinicId: clinic.id,
        memberId: staffMemberId,
        isActive: true,
      );
      final directory = await staff.getStaffMembers(clinic.id);
      final directoryMember = directory.singleWhere(
        (member) => member.email == inviteeEmail,
      );
      expect(directoryMember.isActive, isTrue);
      expect(directoryMember.roles, {StaffRole.dentist});
      final listedInvitations = await staff.getInvitations(clinic.id);
      expect(
        listedInvitations.map((invitation) => invitation.status),
        containsAll([
          StaffInvitationStatus.accepted,
          StaffInvitationStatus.revoked,
        ]),
      );

      final ownerInvitation = await staff.createInvitation(
        clinicId: clinic.id,
        email: 'approved-owner-$stamp@example.test',
        roles: {StaffRole.owner},
        appOrigin: Uri.parse('http://localhost:3000'),
        ownerPassword: password,
      );
      final ownerInvitationId = ownerInvitation.invitationId;
      final revokeOwnerWithoutPassword = await _call(
        functions,
        config,
        ownerToken,
        {'action': 'revoke', 'invitationId': ownerInvitationId},
      );
      expect(revokeOwnerWithoutPassword.statusCode, 403);
      expect(
        revokeOwnerWithoutPassword.data?['error'],
        'owner_reauthentication_required',
      );
      await staff.revokeInvitation(
        clinicId: clinic.id,
        invitationId: ownerInvitationId,
        ownerPassword: password,
      );
    },
    skip: !const bool.fromEnvironment('RUN_LOCAL_STAFF'),
    timeout: const Timeout(Duration(minutes: 3)),
  );
}

SupabaseAuthRepository _repository(
  SupabaseConnection connection,
  AppConfig config,
) {
  return SupabaseAuthRepository(
    SupabaseAuthDataSource(connection, config),
    _MemorySession(),
  );
}

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
  fail('Local inbox did not receive the expected email code.');
}

Future<String> _readInvitationToken(
  Dio inbox,
  String email,
  Set<String> usedMessageIds,
) async {
  for (var attempt = 0; attempt < 30; attempt++) {
    final response = await inbox.get<Map<String, dynamic>>('/messages');
    final messages = response.data!['messages'] as List<dynamic>;
    for (final raw in messages.reversed) {
      final message = raw as Map<String, dynamic>;
      final recipients = message['To'] as List<dynamic>;
      if (!recipients.any(
        (recipient) => (recipient as Map<String, dynamic>)['Address'] == email,
      )) {
        continue;
      }
      final id = message['ID'] as String;
      if (usedMessageIds.contains(id)) continue;
      final full = await inbox.get<Map<String, dynamic>>('/message/$id');
      final body = '${full.data!['Text']} ${full.data!['HTML']}';
      final token = RegExp(
        r'#token=([A-Za-z0-9_-]{43})',
      ).firstMatch(body)?.group(1);
      if (token != null) {
        expect(body, contains('تمت دعوتك إلى عيادة'));
        expect(body, contains('Вас пригласили в клинику'));
        usedMessageIds.add(id);
        return token;
      }
    }
    await Future<void>.delayed(const Duration(milliseconds: 200));
  }
  fail('Local inbox did not receive the expected invitation link.');
}

Future<Response<Map<String, dynamic>>> _call(
  Dio functions,
  AppConfig config,
  String accessToken,
  Map<String, dynamic> body,
) {
  return functions.post<Map<String, dynamic>>(
    '/functions/v1/staff-invitations',
    data: body,
    options: Options(
      headers: {
        'apikey': config.publishableKey,
        'authorization': 'Bearer $accessToken',
      },
    ),
  );
}

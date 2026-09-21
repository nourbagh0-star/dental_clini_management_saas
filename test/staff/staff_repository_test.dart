import 'package:dental_clini_management_saas/features/staff/data/staff_data_source.dart';
import 'package:dental_clini_management_saas/features/staff/data/supabase_staff_repository.dart';
import 'package:dental_clini_management_saas/features/staff/domain/staff_models.dart';
import 'package:dental_clini_management_saas/features/staff/domain/staff_validation.dart';
import 'package:flutter_test/flutter_test.dart';

const _clinicId = '11111111-1111-4111-8111-111111111111';
const _memberId = '22222222-2222-4222-8222-222222222222';
const _invitationId = '33333333-3333-4333-8333-333333333333';

void main() {
  group('SupabaseStaffRepository', () {
    test(
      'creates a normalized staff account and validates credentials before sending',
      () async {
        final source = _FakeStaffDataSource();
        final repository = SupabaseStaffRepository(source);
        await expectLater(
          repository.createAccount(
            clinicId: _clinicId,
            displayName: 'Morgan Reed',
            email: 'staff@example.test',
            roles: {StaffRole.dentist},
            temporaryPassword: 'short',
            ownerPassword: 'owner',
          ),
          throwsA(isA<StaffOperationException>()),
        );
        expect(source.requests, isEmpty);
        await repository.createAccount(
          clinicId: _clinicId,
          displayName: 'Morgan Reed',
          email: ' Staff@Example.Test ',
          roles: {StaffRole.dentist},
          temporaryPassword: 'fictional temporary password',
          ownerPassword: 'fictional owner password',
        );
        expect(source.requests.single['action'], 'create_account');
        expect(source.requests.single['email'], 'staff@example.test');
        expect(source.requests.single['roles'], ['dentist']);
      },
    );
    test('maps staff rows and their multiple roles', () async {
      final source = _FakeStaffDataSource()
        ..staffRows = [
          {
            'id': _memberId,
            'user_id': '44444444-4444-4444-8444-444444444444',
            'display_name': 'Doctor Morgan',
            'email': ' Doctor@Example.Test ',
            'is_active': true,
            'deactivated_at': null,
            'clinic_member_roles': [
              {'role': 'owner'},
              {'role': 'dentist'},
            ],
          },
        ];
      final repository = SupabaseStaffRepository(source);

      final members = await repository.getStaffMembers(_clinicId);

      expect(source.lastClinicId, _clinicId);
      expect(members, hasLength(1));
      expect(members.single.email, 'doctor@example.test');
      expect(members.single.roles, {StaffRole.owner, StaffRole.dentist});
      expect(members.single.isActive, isTrue);
    });

    test(
      'maps invitations and sends normalized create input to the function',
      () async {
        final source = _FakeStaffDataSource()
          ..response = {
            'invitationId': _invitationId,
            'expiresAt': '2026-09-15T10:00:00Z',
          }
          ..invitationRows = [
            {
              'id': _invitationId,
              'clinic_id': _clinicId,
              'email': 'assistant@example.test',
              'status': 'pending',
              'created_at': '2026-09-08T10:00:00Z',
              'expires_at': '2026-09-15T10:00:00Z',
              'last_sent_at': '2026-09-08T10:00:00Z',
              'resend_count': 0,
              'accepted_at': null,
              'revoked_at': null,
              'clinic_invitation_roles': [
                {'role': 'assistant'},
              ],
            },
          ];
        final repository = SupabaseStaffRepository(source);

        final delivery = await repository.createInvitation(
          clinicId: _clinicId,
          email: ' Assistant@Example.Test ',
          roles: {StaffRole.assistant},
          appOrigin: Uri.parse('https://demo.example.test'),
        );
        final invitations = await repository.getInvitations(_clinicId);

        expect(delivery.invitationId, _invitationId);
        expect(delivery.expiresAt, DateTime.utc(2026, 9, 15, 10));
        expect(source.requests.single, {
          'action': 'create',
          'clinicId': _clinicId,
          'email': 'assistant@example.test',
          'roles': ['assistant'],
          'appOrigin': 'https://demo.example.test',
        });
        expect(invitations.single.status, StaffInvitationStatus.pending);
        expect(invitations.single.roles, {StaffRole.assistant});
      },
    );

    test('rejects malformed input before making a remote request', () async {
      final source = _FakeStaffDataSource();
      final repository = SupabaseStaffRepository(source);

      await expectLater(
        repository.createInvitation(
          clinicId: 'not-a-uuid',
          email: 'assistant@example.test',
          roles: {StaffRole.assistant},
          appOrigin: Uri.parse('https://demo.example.test'),
        ),
        throwsA(
          isA<StaffOperationException>().having(
            (error) => error.issue,
            'issue',
            StaffOperationIssue.invalidInput,
          ),
        ),
      );
      await expectLater(
        repository.acceptInvitation('not-a-token'),
        throwsA(isA<StaffOperationException>()),
      );
      expect(source.requests, isEmpty);
    });

    test(
      'preserves typed server outcomes for the presentation workflow',
      () async {
        final source = _FakeStaffDataSource()
          ..failure = const StaffOperationException(
            StaffOperationIssue.ownerReauthenticationRequired,
          );
        final repository = SupabaseStaffRepository(source);

        await expectLater(
          repository.setMemberActive(
            clinicId: _clinicId,
            memberId: _memberId,
            isActive: false,
          ),
          throwsA(
            isA<StaffOperationException>().having(
              (error) => error.issue,
              'issue',
              StaffOperationIssue.ownerReauthenticationRequired,
            ),
          ),
        );
      },
    );

    test(
      'rejects malformed server records without exposing their contents',
      () async {
        final source = _FakeStaffDataSource()
          ..staffRows = [
            {
              'id': _memberId,
              'user_id': '44444444-4444-4444-8444-444444444444',
              'display_name': 'Assistant Morgan',
              'email': 'assistant@example.test',
              'is_active': true,
              'deactivated_at': null,
              'clinic_member_roles': <Map<String, dynamic>>[],
            },
          ];
        final repository = SupabaseStaffRepository(source);

        await expectLater(
          repository.getStaffMembers(_clinicId),
          throwsA(isA<StaffOperationException>()),
        );
      },
    );
  });

  group('StaffValidation', () {
    test('accepts an origin only without a path, query, or fragment', () {
      expect(
        StaffValidation.appOrigin(Uri.parse('https://demo.example.test/')),
        Uri.parse('https://demo.example.test'),
      );
      expect(
        () => StaffValidation.appOrigin(
          Uri.parse('https://demo.example.test/invitations/accept'),
        ),
        throwsA(isA<StaffOperationException>()),
      );
    });
  });
}

class _FakeStaffDataSource implements StaffDataSource {
  List<Map<String, dynamic>> staffRows = const [];
  List<Map<String, dynamic>> invitationRows = const [];
  Map<String, dynamic> response = const {'ok': true};
  Object? failure;
  String? lastClinicId;
  final requests = <Map<String, dynamic>>[];

  @override
  Future<List<Map<String, dynamic>>> getInvitationRows(String clinicId) async {
    lastClinicId = clinicId;
    return invitationRows;
  }

  @override
  Future<List<Map<String, dynamic>>> getStaffMemberRows(String clinicId) async {
    lastClinicId = clinicId;
    return staffRows;
  }

  @override
  Future<Map<String, dynamic>> invokeStaffAction(
    Map<String, dynamic> request,
  ) async {
    requests.add(request);
    if (failure != null) throw failure!;
    return response;
  }
}

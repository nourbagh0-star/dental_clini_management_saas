import 'package:dental_clini_management_saas/core/auth/session_coordinator.dart';
import 'package:dental_clini_management_saas/core/error/app_failure.dart';
import 'package:dental_clini_management_saas/core/storage/active_clinic_store.dart';
import 'package:dental_clini_management_saas/features/auth/domain/auth_models.dart';
import 'package:dental_clini_management_saas/features/clinic/domain/clinic_models.dart';
import 'package:dental_clini_management_saas/features/clinic/domain/clinic_repository.dart';
import 'package:dental_clini_management_saas/features/clinic/presentation/clinic_cubit.dart';
import 'package:flutter_test/flutter_test.dart';

import '../auth/auth_fakes.dart';

void main() {
  group('ClinicCubit', () {
    test(
      'auto-selects one clinic and remembers it only for that account',
      () async {
        final store = MemoryActiveClinicStore();
        final fixture = _Fixture(
          store: store,
          memberships: [_membership('clinic-1', 'North Dental')],
        );
        addTearDown(fixture.dispose);

        await fixture.signIn();

        expect(fixture.cubit.state.status, ClinicStatus.ready);
        expect(fixture.cubit.state.activeClinic?.name, 'North Dental');
        expect(store.values['demo-user'], 'clinic-1');
      },
    );

    test(
      'requires a choice when the account belongs to multiple clinics',
      () async {
        final fixture = _Fixture(
          memberships: [
            _membership('clinic-1', 'North Dental'),
            _membership('clinic-2', 'South Dental'),
          ],
        );
        addTearDown(fixture.dispose);

        await fixture.signIn();
        expect(fixture.cubit.state.activeClinic, isNull);

        await fixture.cubit.selectClinic('clinic-2');
        expect(fixture.cubit.state.activeClinic?.id, 'clinic-2');
      },
    );

    test('creates a clinic then selects it', () async {
      final fixture = _Fixture(memberships: []);
      addTearDown(fixture.dispose);
      await fixture.signIn();

      await fixture.cubit.createClinic(
        name: 'River Dental',
        ownerDisplayName: 'Morgan Reed',
        currencyCode: 'RUB',
        timeZone: 'Europe/Moscow',
      );

      expect(fixture.cubit.state.activeClinic?.name, 'River Dental');
      expect(fixture.repository.created, hasLength(1));
      expect(
        fixture.store.values['demo-user'],
        fixture.cubit.state.activeClinic?.id,
      );
    });

    test('clears the active selection after logout', () async {
      final fixture = _Fixture(memberships: [_membership('clinic-1', 'North')]);
      addTearDown(fixture.dispose);
      await fixture.signIn();

      await fixture.session.logout();
      await _settle();

      expect(fixture.cubit.state.status, ClinicStatus.initial);
      expect(fixture.store.values, isEmpty);
    });

    test('shows a safe failure when the membership request fails', () async {
      final fixture = _Fixture(memberships: [])
        ..repository.failure = const NetworkFailure();
      addTearDown(fixture.dispose);

      await fixture.signIn();

      expect(fixture.cubit.state.status, ClinicStatus.failure);
      expect(fixture.cubit.state.failure, isA<NetworkFailure>());
    });
  });
}

ClinicMembership _membership(String id, String name) => ClinicMembership(
  clinic: Clinic(
    id: id,
    name: name,
    currencyCode: 'RUB',
    timeZone: 'Europe/Moscow',
  ),
  roles: const {'owner'},
);

Future<void> _settle() async {
  await Future<void>.delayed(Duration.zero);
  await Future<void>.delayed(Duration.zero);
}

class _Fixture {
  _Fixture({
    List<ClinicMembership>? memberships,
    MemoryActiveClinicStore? store,
  }) : store = store ?? MemoryActiveClinicStore(),
       repository = MemoryClinicRepository(memberships ?? []),
       auth = TestAuthRepository(),
       signal = TestPrivacySignal() {
    session = SessionCoordinator(auth, auth, signal, enableTimer: false);
    cubit = ClinicCubit(repository, this.store, session);
  }

  final MemoryActiveClinicStore store;
  final MemoryClinicRepository repository;
  final TestAuthRepository auth;
  final TestPrivacySignal signal;
  late final SessionCoordinator session;
  late final ClinicCubit cubit;

  Future<void> signIn() async {
    await session.run(AuthAction.restore, AuthInput());
    await session.run(
      AuthAction.login,
      AuthInput(email: 'demo@example.test', secret: 'a long password'),
    );
    await _settle();
  }

  Future<void> dispose() async {
    await cubit.close();
    await session.dispose();
  }
}

class MemoryActiveClinicStore implements ActiveClinicStore {
  final values = <String, String>{};
  @override
  Future<void> clearForUser(String userId) async => values.remove(userId);
  @override
  Future<String?> readForUser(String userId) async => values[userId];
  @override
  Future<void> writeForUser(String userId, String clinicId) async {
    values[userId] = clinicId;
  }
}

class MemoryClinicRepository implements ClinicRepository {
  MemoryClinicRepository(this.memberships);
  final List<ClinicMembership> memberships;
  final created = <Clinic>[];
  AppFailure? failure;

  @override
  Future<Clinic> createClinic({
    required String name,
    required String ownerDisplayName,
    required String currencyCode,
    required String timeZone,
  }) async {
    if (failure != null) throw failure!;
    final clinic = Clinic(
      id: 'clinic-${created.length + 1}',
      name: name,
      currencyCode: currencyCode,
      timeZone: timeZone,
    );
    created.add(clinic);
    memberships.add(ClinicMembership(clinic: clinic, roles: const {'owner'}));
    return clinic;
  }

  @override
  Future<List<ClinicMembership>> getMyActiveMemberships() async {
    if (failure != null) throw failure!;
    return List.of(memberships);
  }
}

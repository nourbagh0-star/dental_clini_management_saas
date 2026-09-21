import 'dart:async';

import 'package:dental_clini_management_saas/app/localization/generated/app_localizations.dart';
import 'package:dental_clini_management_saas/features/clinic/domain/clinic_models.dart';
import 'package:dental_clini_management_saas/features/clinic/presentation/clinic_cubit.dart';
import 'package:dental_clini_management_saas/features/staff/domain/staff_models.dart';
import 'package:dental_clini_management_saas/features/staff/presentation/pages/staff_pages.dart';
import 'package:dental_clini_management_saas/features/staff/presentation/staff_cubit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockClinicCubit extends Mock implements ClinicCubit {}

class _MockStaffCubit extends Mock implements StaffCubit {}

void main() {
  testWidgets('desktop staff columns stay mounted while staff reloads', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1200, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final clinicCubit = _MockClinicCubit();
    final staffCubit = _MockStaffCubit();
    final staffStates = StreamController<StaffState>.broadcast();
    addTearDown(staffStates.close);

    const clinic = Clinic(
      id: 'clinic-1',
      name: 'Test Clinic',
      currencyCode: 'USD',
      timeZone: 'UTC',
    );
    const clinicState = ClinicState(
      status: ClinicStatus.ready,
      memberships: [
        ClinicMembership(clinic: clinic, memberId: 'owner-1', roles: {'owner'}),
      ],
      activeClinicId: 'clinic-1',
    );
    const member = StaffMember(
      id: 'member-1',
      userId: 'user-1',
      displayName: 'Morgan Reed',
      email: 'staff@example.test',
      isActive: true,
      roles: {StaffRole.assistant},
    );
    const ready = StaffState(
      status: StaffStatus.ready,
      clinicId: 'clinic-1',
      members: [member],
    );

    when(() => clinicCubit.state).thenReturn(clinicState);
    when(() => clinicCubit.stream).thenAnswer((_) => const Stream.empty());
    when(() => staffCubit.state).thenReturn(ready);
    when(() => staffCubit.stream).thenAnswer((_) => staffStates.stream);
    when(() => staffCubit.load(any())).thenAnswer((_) async {});

    await tester.pumpWidget(
      MultiBlocProvider(
        providers: [
          BlocProvider<ClinicCubit>.value(value: clinicCubit),
          BlocProvider<StaffCubit>.value(value: staffCubit),
        ],
        child: const MaterialApp(
          locale: Locale('en'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: StaffPage(),
        ),
      ),
    );
    await tester.pump();

    expect(find.byKey(const ValueKey('staff-desktop-columns')), findsOneWidget);

    staffStates.add(
      const StaffState(
        status: StaffStatus.loading,
        clinicId: 'clinic-1',
        members: [member],
      ),
    );
    await tester.pump();
    expect(find.byKey(const ValueKey('staff-desktop-columns')), findsOneWidget);

    staffStates.add(ready);
    await tester.pump();
    expect(find.byKey(const ValueKey('staff-desktop-columns')), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('staff creation waits for each dialog overlay to close', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1200, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final clinicCubit = _MockClinicCubit();
    final staffCubit = _MockStaffCubit();
    const clinic = Clinic(
      id: 'clinic-1',
      name: 'Test Clinic',
      currencyCode: 'USD',
      timeZone: 'UTC',
    );
    when(() => clinicCubit.state).thenReturn(
      const ClinicState(
        status: ClinicStatus.ready,
        memberships: [
          ClinicMembership(
            clinic: clinic,
            memberId: 'owner-1',
            roles: {'owner'},
          ),
        ],
        activeClinicId: 'clinic-1',
      ),
    );
    when(() => clinicCubit.stream).thenAnswer((_) => const Stream.empty());
    when(() => staffCubit.state).thenReturn(
      const StaffState(status: StaffStatus.ready, clinicId: 'clinic-1'),
    );
    when(() => staffCubit.stream).thenAnswer((_) => const Stream.empty());
    when(() => staffCubit.load(any())).thenAnswer((_) async {});
    when(
      () => staffCubit.createAccount(
        clinicId: any(named: 'clinicId'),
        displayName: any(named: 'displayName'),
        email: any(named: 'email'),
        roles: any(named: 'roles'),
        temporaryPassword: any(named: 'temporaryPassword'),
        ownerPassword: any(named: 'ownerPassword'),
      ),
    ).thenAnswer((_) async => true);

    await tester.pumpWidget(
      MultiBlocProvider(
        providers: [
          BlocProvider<ClinicCubit>.value(value: clinicCubit),
          BlocProvider<StaffCubit>.value(value: staffCubit),
        ],
        child: const MaterialApp(
          locale: Locale('en'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: StaffPage(),
        ),
      ),
    );
    await tester.pump();

    await tester.tap(find.byKey(const ValueKey('staff-invite')));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const ValueKey('staff-display-name')),
      'Morgan Reed',
    );
    await tester.enterText(
      find.byKey(const ValueKey('staff-invite-email')),
      'employee@example.test',
    );
    await tester.enterText(
      find.byKey(const ValueKey('staff-temporary-password')),
      'temporary password 123',
    );
    await tester.tap(find.widgetWithText(FilledButton, 'Create staff account'));
    await tester.pump(const Duration(seconds: 1));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(find.byType(AlertDialog), findsOneWidget);
    await tester.enterText(find.byType(TextField), 'owner password 123');
    await tester.tap(find.widgetWithText(FilledButton, 'Confirm'));
    await tester.pump(const Duration(seconds: 1));
    await tester.pumpAndSettle();

    final call = verify(
      () => staffCubit.createAccount(
        clinicId: captureAny(named: 'clinicId'),
        displayName: captureAny(named: 'displayName'),
        email: captureAny(named: 'email'),
        roles: captureAny(named: 'roles'),
        temporaryPassword: captureAny(named: 'temporaryPassword'),
        ownerPassword: captureAny(named: 'ownerPassword'),
      ),
    )..called(1);
    expect(call.captured[0], 'clinic-1');
    expect(call.captured[1], 'Morgan Reed');
    expect(call.captured[2], 'employee@example.test');
    expect(call.captured[3], contains(StaffRole.assistant));
    expect(call.captured[4], 'temporary password 123');
    expect(call.captured[5], 'owner password 123');
    expect(tester.takeException(), isNull);
  });
}

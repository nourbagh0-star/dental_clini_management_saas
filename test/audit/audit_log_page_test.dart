import 'package:dental_clini_management_saas/app/localization/generated/app_localizations.dart';
import 'package:dental_clini_management_saas/features/audit/domain/audit_models.dart';
import 'package:dental_clini_management_saas/features/audit/presentation/audit_cubit.dart';
import 'package:dental_clini_management_saas/features/audit/presentation/pages/audit_log_page.dart';
import 'package:dental_clini_management_saas/features/clinic/domain/clinic_models.dart';
import 'package:dental_clini_management_saas/features/clinic/presentation/clinic_cubit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockClinicCubit extends Mock implements ClinicCubit {}

class _MockAuditCubit extends Mock implements AuditCubit {}

void main() {
  setUpAll(() {
    registerFallbackValue(
      AuditFilter(
        fromDate: DateTime(2026, 9, 1),
        toDateExclusive: DateTime(2026, 10, 1),
      ),
    );
  });

  testWidgets('a non-owner receives the neutral owner-only screen', (
    tester,
  ) async {
    await tester.pumpWidget(_app(const Locale('en'), owner: false));
    await tester.pump();

    expect(
      find.text('Only an active clinic owner can view the audit log.'),
      findsOneWidget,
    );
    expect(find.text('Filters'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Arabic owner audit cards fit a narrow large-text screen', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 1100);
    tester.view.devicePixelRatio = 1;
    tester.platformDispatcher.textScaleFactorTestValue = 1.6;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);

    await tester.pumpWidget(_app(const Locale('ar'), owner: true));
    await tester.pump();

    expect(find.text('سجل التدقيق'), findsOneWidget);
    expect(find.text('عوامل التصفية'), findsOneWidget);
    expect(find.text('audit-owner@example.test'), findsOneWidget);
    expect(
      Directionality.of(tester.element(find.byType(Scaffold).first)),
      TextDirection.rtl,
    );
    expect(tester.takeException(), isNull);
  });
}

Widget _app(Locale locale, {required bool owner}) {
  final clinic = _MockClinicCubit();
  final audit = _MockAuditCubit();
  when(() => clinic.stream).thenAnswer((_) => const Stream.empty());
  when(() => clinic.state).thenReturn(
    ClinicState(
      status: ClinicStatus.ready,
      activeClinicId: '13000000-0000-4000-8000-000000000010',
      memberships: [
        ClinicMembership(
          clinic: const Clinic(
            id: '13000000-0000-4000-8000-000000000010',
            name: 'Audit Clinic',
            currencyCode: 'RUB',
            timeZone: 'Europe/Moscow',
          ),
          roles: {if (owner) 'owner' else 'dentist'},
        ),
      ],
    ),
  );
  when(() => audit.stream).thenAnswer((_) => const Stream.empty());
  when(() => audit.state).thenReturn(
    owner
        ? AuditState(
            status: AuditLoadStatus.ready,
            clinicId: '13000000-0000-4000-8000-000000000010',
            filter: AuditFilter(
              fromDate: DateTime(2026, 9, 1),
              toDateExclusive: DateTime(2026, 10, 1),
            ),
            page: _page(),
          )
        : const AuditState(),
  );
  when(() => audit.load(any(), any())).thenAnswer((_) async {});
  when(() => audit.refresh()).thenAnswer((_) async {});
  when(() => audit.clear()).thenReturn(null);
  return MultiBlocProvider(
    providers: [
      BlocProvider<ClinicCubit>.value(value: clinic),
      BlocProvider<AuditCubit>.value(value: audit),
    ],
    child: MaterialApp(
      locale: locale,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: const AuditLogPage(),
    ),
  );
}

AuditPage _page() => AuditPage(
  clinicId: '13000000-0000-4000-8000-000000000010',
  clinicTimeZone: 'Europe/Moscow',
  fromDate: DateTime(2026, 9, 1),
  toDateExclusive: DateTime(2026, 10, 1),
  actors: const [],
  hasMore: false,
  items: [
    AuditEvent(
      id: '13000000-0000-4000-8000-000000000050',
      actorUserId: '13000000-0000-4000-8000-000000000001',
      actorEmail: 'audit-owner@example.test',
      actorRoles: const {'owner'},
      category: AuditCategory.access,
      eventType: 'audit_log_opened',
      subjectType: 'clinic',
      subjectId: '13000000-0000-4000-8000-000000000010',
      context: const AuditContext(),
      occurredAt: DateTime.utc(2026, 9, 13, 9),
    ),
  ],
);

import 'package:dental_clini_management_saas/app/localization/generated/app_localizations.dart';
import 'package:dental_clini_management_saas/app/theme/app_theme.dart';
import 'package:dental_clini_management_saas/app/theme/appearance.dart';
import 'package:dental_clini_management_saas/app/theme/appearance_cubit.dart';
import 'package:dental_clini_management_saas/features/auth/domain/auth_models.dart';
import 'package:dental_clini_management_saas/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:dental_clini_management_saas/features/clinic/domain/clinic_models.dart';
import 'package:dental_clini_management_saas/features/clinic/presentation/clinic_cubit.dart';
import 'package:dental_clini_management_saas/features/settings/presentation/pages/settings_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../support/fakes.dart';

class _MockClinicCubit extends Mock implements ClinicCubit {}

class _MockAuthBloc extends Mock implements AuthBloc {}

void main() {
  setUpAll(() => registerFallbackValue(AuthLockRequested()));

  testWidgets('Arabic settings persist appearance and expose privacy actions', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 1000);
    tester.view.devicePixelRatio = 1;
    tester.platformDispatcher.textScaleFactorTestValue = 2;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);

    final store = MemoryPreferences();
    final appearance = AppearanceCubit(store);
    final clinic = _MockClinicCubit();
    final auth = _MockAuthBloc();
    addTearDown(appearance.close);
    when(() => clinic.stream).thenAnswer((_) => const Stream.empty());
    when(() => clinic.state).thenReturn(
      const ClinicState(
        status: ClinicStatus.ready,
        activeClinicId: 'clinic-1',
        memberships: [
          ClinicMembership(
            clinic: Clinic(
              id: 'clinic-1',
              name: 'Demo Clinic',
              currencyCode: 'USD',
              timeZone: 'Etc/UTC',
            ),
            roles: {'owner'},
          ),
        ],
      ),
    );
    when(() => auth.stream).thenAnswer((_) => const Stream.empty());
    when(() => auth.state).thenReturn(
      const AuthViewState(
        stage: AuthStage.signedIn,
        identity: AuthIdentity(id: 'user-demo', email: 'owner@example.test'),
      ),
    );

    await tester.pumpWidget(
      MultiBlocProvider(
        providers: [
          BlocProvider<AppearanceCubit>.value(value: appearance),
          BlocProvider<ClinicCubit>.value(value: clinic),
          BlocProvider<AuthBloc>.value(value: auth),
        ],
        child: MaterialApp(
          theme: AppTheme.light,
          locale: const Locale('ar'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: const SettingsPage(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('settings-theme')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('داكن').last);
    await tester.pumpAndSettle();
    expect(appearance.state.preferences.theme, AppThemeMode.dark);
    expect(store.value, contains('dark'));

    await tester.scrollUntilVisible(
      find.text('قفل مساحة العمل'),
      250,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(find.text('قفل مساحة العمل'));
    verify(() => auth.add(any(that: isA<AuthLockRequested>()))).called(1);
    expect(tester.takeException(), isNull);
  });
}

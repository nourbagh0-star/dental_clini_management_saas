import 'dart:convert';

import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:dental_clini_management_saas/app/theme/appearance.dart';
import 'package:dental_clini_management_saas/app/theme/appearance_cubit.dart';

import '../support/fakes.dart';

void main() {
  late MemoryPreferences store;
  setUp(() => store = MemoryPreferences());

  blocTest<AppearanceCubit, AppearanceState>(
    'restores preferences with explicit loading',
    build: () {
      store.value = '{"theme":"dark","language":"russian"}';
      return AppearanceCubit(store);
    },
    act: (cubit) => cubit.load(),
    expect: () => [
      const AppearanceState(busy: true),
      const AppearanceState(
        preferences: Appearance(
          theme: AppThemeMode.dark,
          language: AppLanguage.russian,
        ),
      ),
    ],
  );

  blocTest<AppearanceCubit, AppearanceState>(
    'corrupt preferences recover with a visible warning',
    build: () {
      store.value = '{broken';
      return AppearanceCubit(store);
    },
    act: (cubit) => cubit.load(),
    expect: () => [
      const AppearanceState(busy: true),
      const AppearanceState(storageFailed: true),
    ],
  );

  test('appearance survives a new cubit instance', () async {
    final first = AppearanceCubit(store);
    final second = AppearanceCubit(store);
    addTearDown(first.close);
    addTearDown(second.close);
    await first.change(theme: AppThemeMode.dark, language: AppLanguage.russian);
    await second.load();
    expect(second.state.preferences, first.state.preferences);
    expect(jsonDecode(store.value!) as Map<String, dynamic>, {
      'theme': 'dark',
      'language': 'russian',
    });
  });

  test('failed write keeps selection usable and reports failure', () async {
    store.fail = true;
    final cubit = AppearanceCubit(store);
    addTearDown(cubit.close);
    await cubit.change(theme: AppThemeMode.dark);
    expect(cubit.state.preferences.theme, AppThemeMode.dark);
    expect(cubit.state.storageFailed, isTrue);
    expect(cubit.state.busy, isFalse);
  });
}

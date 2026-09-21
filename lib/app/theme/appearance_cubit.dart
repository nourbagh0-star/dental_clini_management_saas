import 'dart:convert';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';

import '../../core/storage/preferences_store.dart';
import 'appearance.dart';

@injectable
class AppearanceCubit extends Cubit<AppearanceState> {
  AppearanceCubit(this._store) : super(const AppearanceState());
  final PreferencesStore _store;

  Future<void> load() async {
    emit(state.copyWith(busy: true));
    try {
      final raw = await _store.readAppearance();
      final preferences = raw == null
          ? const Appearance()
          : Appearance.fromJson(jsonDecode(raw) as Map<String, dynamic>);
      emit(AppearanceState(preferences: preferences));
    } on Object {
      // Corrupt/unavailable preferences never prevent access to the demo shell.
      emit(const AppearanceState(storageFailed: true));
    }
  }

  Future<void> change({AppThemeMode? theme, AppLanguage? language}) async {
    if (state.busy) return;
    final next = state.preferences.copyWith(
      theme: theme ?? state.preferences.theme,
      language: language ?? state.preferences.language,
    );
    emit(AppearanceState(preferences: next, busy: true));
    try {
      await _store.writeAppearance(jsonEncode(next.toJson()));
      if (!isClosed) emit(AppearanceState(preferences: next));
    } on Object {
      if (!isClosed) {
        emit(AppearanceState(preferences: next, storageFailed: true));
      }
    }
  }
}

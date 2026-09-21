import 'package:injectable/injectable.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../error/app_failure.dart';

abstract interface class PreferencesStore {
  Future<String?> readAppearance();
  Future<void> writeAppearance(String value);
}

@LazySingleton(as: PreferencesStore)
class LocalPreferencesStore implements PreferencesStore {
  static const _key = 'dentaflow.appearance.v1';
  // Initialize inside the guarded operation so plugin failures reach the UI
  // as a preferences warning instead of preventing application startup.
  SharedPreferencesAsync? _instance;
  SharedPreferencesAsync get _preferences =>
      _instance ??= SharedPreferencesAsync();

  @override
  Future<String?> readAppearance() async {
    try {
      return await _preferences.getString(_key);
    } on Object {
      throw const UnknownFailure();
    }
  }

  @override
  Future<void> writeAppearance(String value) async {
    try {
      await _preferences.setString(_key, value);
    } on Object {
      throw const UnknownFailure();
    }
  }
}

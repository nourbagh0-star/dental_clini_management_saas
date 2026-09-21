import 'package:injectable/injectable.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../error/app_failure.dart';

/// Stores only a user-scoped clinic identifier. It contains no patient or
/// clinic content and is cleared when the account changes.
abstract interface class ActiveClinicStore {
  Future<String?> readForUser(String userId);
  Future<void> writeForUser(String userId, String clinicId);
  Future<void> clearForUser(String userId);
}

@LazySingleton(as: ActiveClinicStore)
class LocalActiveClinicStore implements ActiveClinicStore {
  static const _prefix = 'dentaflow.active-clinic.v1.';
  SharedPreferencesAsync? _instance;
  SharedPreferencesAsync get _preferences =>
      _instance ??= SharedPreferencesAsync();

  String _key(String userId) => '$_prefix$userId';

  @override
  Future<String?> readForUser(String userId) async {
    try {
      return await _preferences.getString(_key(userId));
    } on Object {
      throw const UnknownFailure();
    }
  }

  @override
  Future<void> writeForUser(String userId, String clinicId) async {
    try {
      await _preferences.setString(_key(userId), clinicId);
    } on Object {
      throw const UnknownFailure();
    }
  }

  @override
  Future<void> clearForUser(String userId) async {
    try {
      await _preferences.remove(_key(userId));
    } on Object {
      throw const UnknownFailure();
    }
  }
}

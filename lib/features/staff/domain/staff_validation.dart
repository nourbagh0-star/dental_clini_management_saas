import 'staff_models.dart';

abstract final class StaffValidation {
  static final _emailPattern = RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$');
  static final _uuidPattern = RegExp(
    r'^[0-9a-f]{8}-[0-9a-f]{4}-[1-5][0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$',
    caseSensitive: false,
  );
  static final _tokenPattern = RegExp(r'^[A-Za-z0-9_-]{43}$');

  static String email(String value) {
    final normalized = value.trim().toLowerCase();
    if (normalized.length < 3 ||
        normalized.length > 320 ||
        !_emailPattern.hasMatch(normalized)) {
      throw const StaffOperationException(StaffOperationIssue.invalidInput);
    }
    return normalized;
  }

  static String id(String value) {
    if (!_uuidPattern.hasMatch(value)) {
      throw const StaffOperationException(StaffOperationIssue.invalidInput);
    }
    return value;
  }

  static Set<StaffRole> roles(Iterable<StaffRole> value) {
    final result = Set<StaffRole>.of(value);
    if (result.isEmpty) {
      throw const StaffOperationException(StaffOperationIssue.invalidInput);
    }
    return result;
  }

  static String invitationToken(String value) {
    if (!_tokenPattern.hasMatch(value)) {
      throw const StaffOperationException(StaffOperationIssue.invalidInput);
    }
    return value;
  }

  static Uri appOrigin(Uri value) {
    final validScheme = value.scheme == 'http' || value.scheme == 'https';
    if (!validScheme ||
        value.host.isEmpty ||
        value.userInfo.isNotEmpty ||
        value.hasQuery ||
        value.hasFragment ||
        (value.path.isNotEmpty && value.path != '/')) {
      throw const StaffOperationException(StaffOperationIssue.invalidInput);
    }
    return value.replace(path: '', query: null, fragment: null);
  }
}

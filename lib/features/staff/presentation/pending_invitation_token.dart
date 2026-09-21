import 'package:injectable/injectable.dart';

import '../domain/staff_validation.dart';

/// Short-lived invitation secret held only in process memory.
@lazySingleton
class PendingInvitationToken {
  String? _value;

  String? get value => _value;

  bool captureFragment(String? fragment) {
    if (fragment == null || fragment.isEmpty) return false;
    try {
      final candidate = Uri.splitQueryString(fragment)['token'];
      if (candidate == null) return false;
      _value = StaffValidation.invitationToken(candidate);
      return true;
    } on Object {
      return false;
    }
  }

  void clear() => _value = null;

  @override
  String toString() => 'PendingInvitationToken(redacted)';
}

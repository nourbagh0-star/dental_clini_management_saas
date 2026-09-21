import 'package:web/web.dart' as web;

/// Consume the credential before routing; fragments never reach hosting logs.
String? takeEmailConfirmationLink() {
  var fragment = Uri.base.fragment;
  if (fragment.contains('#')) {
    final sub = fragment.substring(fragment.indexOf('#') + 1);
    if (sub.contains('access_token=') ||
        sub.contains('error=') ||
        sub.contains('error_code=')) {
      fragment = sub;
    }
  }
  if (fragment.startsWith('/')) {
    final sub = fragment.substring(1);
    if (sub.contains('access_token=') ||
        sub.contains('error=') ||
        sub.contains('error_code=')) {
      fragment = sub;
    }
  }

  String? candidate;
  if (fragment.contains('access_token=') ||
      fragment.contains('error=') ||
      fragment.contains('error_code=')) {
    candidate = fragment;
  } else {
    final query = Uri.base.query;
    if (query.contains('access_token=') ||
        query.contains('error=') ||
        query.contains('error_code=')) {
      candidate = query;
    }
  }

  if (candidate == null) return null;

  final isRecovery = candidate.contains('type=recovery');
  final cleanRoute = isRecovery ? '/#/reset-password' : '/#/login';
  web.window.history.replaceState(null, '', cleanRoute);
  return candidate;
}

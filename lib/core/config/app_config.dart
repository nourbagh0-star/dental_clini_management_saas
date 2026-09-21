import 'dart:convert';

enum AppEnvironment { development, staging, production }

enum ConfigurationIssue {
  environment,
  productionDisabled,
  incompleteBackend,
  url,
  key,
}

final class ConfigurationException implements Exception {
  const ConfigurationException(this.issue);

  final ConfigurationIssue issue;

  @override
  String toString() => 'ConfigurationException(${issue.name})';
}

/// Public client configuration only. Never put privileged keys in Dart defines.
final class AppConfig {
  const AppConfig._(this.environment, this.supabaseUrl, this.publishableKey);

  factory AppConfig.fromEnvironment() {
    const url = String.fromEnvironment('SUPABASE_URL');
    const key = String.fromEnvironment('SUPABASE_PUBLISHABLE_KEY');
    // Public client settings only. Explicit build settings still override the
    // hosted default as a pair; incomplete overrides fail validation below.
    final useHostedDefault = url.isEmpty && key.isEmpty;
    return AppConfig.parse(
      environment: const String.fromEnvironment(
        'APP_ENV',
        defaultValue: 'development',
      ),
      supabaseUrl: useHostedDefault
          ? 'https://tmjerkzlsbopbvfmxlrj.supabase.co'
          : url,
      publishableKey: useHostedDefault
          ? 'sb_publishable_U6s79EFct-a6-YqTqW27Tw_CbdsNJeP'
          : key,
    );
  }

  factory AppConfig.parse({
    String environment = 'development',
    String supabaseUrl = '',
    String publishableKey = '',
  }) {
    final matches = AppEnvironment.values.where(
      (value) => value.name == environment,
    );
    if (matches.isEmpty) {
      throw const ConfigurationException(ConfigurationIssue.environment);
    }
    final selected = matches.single;
    if (selected == AppEnvironment.production) {
      throw const ConfigurationException(ConfigurationIssue.productionDisabled);
    }
    final url = supabaseUrl.trim();
    final key = publishableKey.trim();
    if (url.isEmpty && key.isEmpty) return AppConfig._(selected, null, null);
    if (url.isEmpty || key.isEmpty) {
      throw const ConfigurationException(ConfigurationIssue.incompleteBackend);
    }
    final uri = Uri.tryParse(url);
    final local =
        uri != null &&
        selected == AppEnvironment.development &&
        {'localhost', '127.0.0.1', '::1', '10.0.2.2'}.contains(uri.host);
    if (uri == null ||
        uri.host.isEmpty ||
        (uri.scheme != 'https' && !(local && uri.scheme == 'http')) ||
        uri.userInfo.isNotEmpty ||
        uri.hasQuery ||
        uri.hasFragment ||
        (uri.path.isNotEmpty && uri.path != '/')) {
      throw const ConfigurationException(ConfigurationIssue.url);
    }
    if (!_isPublicKey(key)) {
      throw const ConfigurationException(ConfigurationIssue.key);
    }
    return AppConfig._(selected, uri.replace(path: ''), key);
  }

  final AppEnvironment environment;
  final Uri? supabaseUrl;
  final String? publishableKey;
  bool get backendConfigured => supabaseUrl != null;

  static bool _isPublicKey(String key) {
    if (RegExp(r'^sb_publishable_[A-Za-z0-9_-]+$').hasMatch(key)) return true;
    // Legacy anon JWTs are permitted for local Supabase compatibility only as
    // client keys. Decoding here is a configuration guard, not authentication.
    try {
      final parts = key.split('.');
      if (parts.length != 3) return false;
      final payload = jsonDecode(
        utf8.decode(base64Url.decode(base64Url.normalize(parts[1]))),
      );
      return payload is Map<String, dynamic> && payload['role'] == 'anon';
    } on FormatException {
      return false;
    }
  }
}

import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:dental_clini_management_saas/core/config/app_config.dart';

void main() {
  test('normal runs have a public backend configuration', () {
    final config = AppConfig.fromEnvironment();
    expect(config.backendConfigured, isTrue);
    expect(config.publishableKey, isNot(startsWith('sb_secret_')));
  });
  test('empty development config boots a disconnected demo', () {
    final config = AppConfig.parse();
    expect(config.environment, AppEnvironment.development);
    expect(config.backendConfigured, isFalse);
  });

  test('production is blocked and unknown environments fail closed', () {
    for (final environment in ['production', 'prod', 'Development', '']) {
      expect(
        () => AppConfig.parse(environment: environment),
        throwsA(isA<ConfigurationException>()),
      );
    }
  });

  test('partial configuration is rejected without leaking values', () {
    expect(
      () => AppConfig.parse(publishableKey: 'sensitive-value'),
      throwsA(
        isA<ConfigurationException>().having(
          (error) => error.toString(),
          'safe error',
          isNot(contains('sensitive-value')),
        ),
      ),
    );
  });

  test('HTTPS public key config normalizes trailing slash', () {
    final config = AppConfig.parse(
      supabaseUrl: 'https://demo.supabase.co/',
      publishableKey: 'sb_publishable_demo',
    );
    expect(config.supabaseUrl.toString(), 'https://demo.supabase.co');
    expect(config.backendConfigured, isTrue);
  });

  test('unsafe URLs and embedded credentials are rejected', () {
    for (final url in [
      'http://demo.supabase.co',
      'https://user:password@demo.supabase.co',
      'https://demo.supabase.co?token=private',
      'https://demo.supabase.co/path',
      'https://demo.supabase.co#fragment',
      'file:///tmp/backend',
    ]) {
      expect(
        () => AppConfig.parse(
          supabaseUrl: url,
          publishableKey: 'sb_publishable_demo',
        ),
        throwsA(isA<ConfigurationException>()),
        reason: url,
      );
    }
  });

  test('HTTP loopback works only in development', () {
    expect(
      AppConfig.parse(
        supabaseUrl: 'http://127.0.0.1:54321',
        publishableKey: 'sb_publishable_demo',
      ).backendConfigured,
      isTrue,
    );
    expect(
      () => AppConfig.parse(
        environment: 'staging',
        supabaseUrl: 'http://127.0.0.1:54321',
        publishableKey: 'sb_publishable_demo',
      ),
      throwsA(isA<ConfigurationException>()),
    );
  });

  test('legacy anon keys allowed; privileged and malformed keys rejected', () {
    String jwt(String role) =>
        'header.${base64Url.encode(utf8.encode(jsonEncode({'role': role})))}.signature';
    expect(
      AppConfig.parse(
        supabaseUrl: 'https://demo.supabase.co',
        publishableKey: jwt('anon'),
      ).backendConfigured,
      isTrue,
    );
    for (final key in [
      'sb_secret_private',
      jwt('service_role'),
      jwt('authenticated'),
      'broken',
      'a.!!!.c',
    ]) {
      expect(
        () => AppConfig.parse(
          supabaseUrl: 'https://demo.supabase.co',
          publishableKey: key,
        ),
        throwsA(isA<ConfigurationException>()),
      );
    }
  });
}

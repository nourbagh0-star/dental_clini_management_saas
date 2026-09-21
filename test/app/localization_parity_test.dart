import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  const directory = 'lib/app/localization/arb';

  test('English, Russian, and Arabic contain the same message keys', () {
    final catalogs = {
      for (final locale in ['en', 'ru', 'ar'])
        locale: _messages('$directory/app_$locale.arb'),
    };
    final expected = catalogs['en']!.keys.toSet();
    for (final entry in catalogs.entries) {
      expect(
        entry.value.keys.toSet(),
        expected,
        reason: '${entry.key} must translate every application message.',
      );
      expect(
        entry.value.values.where((value) => value.trim().isEmpty),
        isEmpty,
        reason: '${entry.key} must not contain empty translations.',
      );
    }
  });

  test('presentation widgets do not introduce direct English labels', () {
    final files = Directory('lib/features')
        .listSync(recursive: true)
        .whereType<File>()
        .where(
          (file) =>
              file.path.contains('/presentation/') &&
              file.path.endsWith('.dart') &&
              !file.path.endsWith('.freezed.dart') &&
              !file.path.endsWith('.g.dart'),
        );
    final directText = RegExp(
      r'''(?:const\s+)?Text\(\s*['"]([A-Za-z][^'"]*)['"]''',
      multiLine: true,
    );
    final directProperty = RegExp(
      r'''(?:labelText|helperText|hintText|tooltip):\s*['"]([A-Za-z][^'"]*)['"]''',
    );
    final directEnglishLiteral = RegExp(
      r'''['"]([A-Z][A-Za-z][^'"\n]{2,})['"]''',
    );
    const technicalValues = {
      'RUB',
      'USD',
      'EUR',
      'Etc/UTC',
      'AuthEvent(redacted)',
      'PendingInvitationToken(redacted)',
    };
    final violations = <String>[];
    for (final file in files) {
      final source = file.readAsStringSync();
      for (final pattern in [
        directText,
        directProperty,
        directEnglishLiteral,
      ]) {
        for (final match in pattern.allMatches(source)) {
          final value = match.group(1)!;
          if (!technicalValues.contains(value)) {
            violations.add('${file.path}:${_line(source, match.start)} $value');
          }
        }
      }
    }
    expect(
      violations,
      isEmpty,
      reason: 'Move user-facing labels to the ARB localization catalogs.',
    );
  });
}

Map<String, String> _messages(String path) {
  final value =
      jsonDecode(File(path).readAsStringSync()) as Map<String, dynamic>;
  return {
    for (final entry in value.entries)
      if (!entry.key.startsWith('@')) entry.key: entry.value as String,
  };
}

int _line(String source, int offset) =>
    '\n'.allMatches(source.substring(0, offset)).length + 1;

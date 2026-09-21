import 'package:dental_clini_management_saas/core/value/money.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('parses and formats canonical decimal money exactly', () {
    expect(Money.parseCanonical('0').toDecimalString(), '0.00');
    expect(Money.parseCanonical('12.3').minorUnits, 1230);
    expect(
      Money.parseCanonical('9999999999.99').toDecimalString(),
      '9999999999.99',
    );
  });

  test('accepts a decimal comma only at the user-input boundary', () {
    expect(
      Money.tryParseUserInput(' 12,34 '),
      const Money.fromMinorUnits(1234),
    );
    expect(() => Money.parseCanonical('12,34'), throwsFormatException);
  });

  test('rejects floating-point and ambiguous formats', () {
    for (final value in ['-1', '1.234', '01.00', '1e2', 'NaN', '']) {
      expect(() => Money.parseCanonical(value), throwsFormatException);
    }
  });
}

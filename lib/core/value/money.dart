/// An exact, non-negative monetary amount stored in the currency's minor unit.
///
/// DentaFlow currently supports currencies with two decimal places. Database
/// amounts cross the API boundary as decimal strings so binary floating-point
/// values never enter financial calculations.
final class Money implements Comparable<Money> {
  const Money.fromMinorUnits(this.minorUnits)
    : assert(minorUnits >= 0),
      assert(minorUnits <= maximumMinorUnits);

  static const zero = Money.fromMinorUnits(0);
  static const maximumMinorUnits = 999999999999;

  final int minorUnits;

  static Money parseCanonical(String value) {
    final match = RegExp(
      r'^(0|[1-9]\d{0,9})(?:\.(\d{1,2}))?$',
    ).firstMatch(value);
    if (match == null) throw const FormatException('Invalid money amount');
    final whole = int.parse(match.group(1)!);
    final fraction = (match.group(2) ?? '').padRight(2, '0');
    final minorUnits =
        whole * 100 + (fraction.isEmpty ? 0 : int.parse(fraction));
    if (minorUnits > maximumMinorUnits) {
      throw const FormatException('Money amount is too large');
    }
    return Money.fromMinorUnits(minorUnits);
  }

  static Money? tryParseUserInput(String value) {
    try {
      return parseCanonical(value.trim().replaceAll(',', '.'));
    } on FormatException {
      return null;
    }
  }

  String toDecimalString() {
    final whole = minorUnits ~/ 100;
    final fraction = (minorUnits % 100).toString().padLeft(2, '0');
    return '$whole.$fraction';
  }

  Money operator +(Money other) =>
      Money.fromMinorUnits(minorUnits + other.minorUnits);

  Money operator -(Money other) {
    final result = minorUnits - other.minorUnits;
    if (result < 0) throw StateError('A money amount cannot be negative');
    return Money.fromMinorUnits(result);
  }

  @override
  int compareTo(Money other) => minorUnits.compareTo(other.minorUnits);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Money && other.minorUnits == minorUnits;

  @override
  int get hashCode => minorUnits.hashCode;

  @override
  String toString() => toDecimalString();
}

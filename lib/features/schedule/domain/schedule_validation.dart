import '../../../core/error/app_failure.dart';
import 'schedule_models.dart';

abstract final class ScheduleValidation {
  static final _uuid = RegExp(
    r'^[0-9a-f]{8}-[0-9a-f]{4}-[1-5][0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$',
    caseSensitive: false,
  );
  static final _date = RegExp(r'^\d{4}-\d{2}-\d{2}$');
  static final _time = RegExp(r'^(?:[01]\d|2[0-3]):[0-5]\d$');
  static final _databaseTime = RegExp(
    r'^((?:[01]\d|2[0-3]):[0-5]\d):00(?:\.0+)?$',
  );

  static String id(String value) {
    if (!_uuid.hasMatch(value)) throw const ValidationFailure();
    return value;
  }

  static String localDate(String value) {
    if (!_date.hasMatch(value) || DateTime.tryParse(value) == null) {
      throw const ValidationFailure();
    }
    return value;
  }

  static String time(String value) {
    if (!_time.hasMatch(value)) throw const ValidationFailure();
    return value;
  }

  /// Converts PostgreSQL `time` output to the minute precision used by the UI.
  ///
  /// Supabase serializes a value inserted as `09:00` as `09:00:00`. Keeping
  /// this conversion at the data boundary prevents a successful save from
  /// failing when the schedule is immediately reloaded.
  static String databaseTime(String value) {
    if (_time.hasMatch(value)) return value;
    final match = _databaseTime.firstMatch(value);
    if (match == null) throw const ServerFailure();
    return match.group(1)!;
  }

  static List<DoctorWorkingPeriod> periods(List<DoctorWorkingPeriod> value) {
    if (value.length > 14) throw const ValidationFailure();
    for (final period in value) {
      if (period.weekday < 1 ||
          period.weekday > 7 ||
          time(period.startsAt).compareTo(time(period.endsAt)) >= 0 ||
          period.breaks.length > 4) {
        throw const ValidationFailure();
      }
      for (final pause in period.breaks) {
        if (time(pause.startsAt).compareTo(time(pause.endsAt)) >= 0 ||
            pause.startsAt.compareTo(period.startsAt) < 0 ||
            pause.endsAt.compareTo(period.endsAt) > 0) {
          throw const ValidationFailure();
        }
      }
    }
    return value;
  }

  static String? reason(String? value) {
    if (value == null) return null;
    final trimmed = value.trim();
    if (trimmed.isEmpty) return null;
    if (trimmed.length > 1000) throw const ValidationFailure();
    return trimmed;
  }

  static DateTime intervalStart(DateTime value) => value.toUtc();

  static DateTime intervalEnd(DateTime start, DateTime end) {
    if (!end.isAfter(start)) throw const ValidationFailure();
    return end.toUtc();
  }
}

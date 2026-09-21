import 'package:injectable/injectable.dart';

import '../../../core/error/app_failure.dart';
import '../domain/schedule_models.dart';
import '../domain/schedule_repository.dart';
import '../domain/schedule_validation.dart';
import 'schedule_data_source.dart';

@LazySingleton(as: ScheduleRepository)
class SupabaseScheduleRepository implements ScheduleRepository {
  SupabaseScheduleRepository(this._source);

  final ScheduleDataSource _source;

  @override
  Future<List<DoctorScheduleVersion>> getScheduleVersions(
    String clinicId,
  ) async => (await _source.getScheduleVersionRows(
    ScheduleValidation.id(clinicId),
  )).map(_versionFromRow).toList(growable: false);

  @override
  Future<List<DoctorScheduleException>> getScheduleExceptions(
    String clinicId,
  ) async => (await _source.getScheduleExceptionRows(
    ScheduleValidation.id(clinicId),
  )).map(_exceptionFromRow).toList(growable: false);

  @override
  Future<List<ScheduleDentist>> getManageableDentists(String clinicId) async {
    final rows = await _source.getManageableDentistRows(
      ScheduleValidation.id(clinicId),
    );
    return rows
        .map(
          (row) => ScheduleDentist(
            memberId: _string(row, 'member_id'),
            displayName: _string(row, 'display_name'),
          ),
        )
        .toList(growable: false);
  }

  @override
  Future<String> replaceWeeklySchedule({
    required String dentistMemberId,
    required String effectiveFrom,
    required List<DoctorWorkingPeriod> periods,
    bool confirmAffectedAppointments = false,
    String? appointmentImpactReason,
  }) async {
    final response = await _source.invokeScheduleAction({
      'action': 'replace_weekly',
      'dentistMemberId': ScheduleValidation.id(dentistMemberId),
      'effectiveFrom': ScheduleValidation.localDate(effectiveFrom),
      'periods': _periods(periods),
      'confirmAffectedAppointments': confirmAffectedAppointments,
      'appointmentImpactReason': ScheduleValidation.reason(
        appointmentImpactReason,
      ),
    });
    return _string(response, 'scheduleVersionId');
  }

  @override
  Future<ScheduleImpactPreview> previewWeeklyImpact({
    required String dentistMemberId,
    required String effectiveFrom,
    required List<DoctorWorkingPeriod> periods,
  }) async {
    final response = await _source.invokeScheduleAction({
      'action': 'preview_weekly_impact',
      'dentistMemberId': ScheduleValidation.id(dentistMemberId),
      'effectiveFrom': ScheduleValidation.localDate(effectiveFrom),
      'periods': _periods(periods),
    });
    final count = response['count'];
    if (count is! int || count < 0) throw const ServerFailure();
    return ScheduleImpactPreview(count: count);
  }

  @override
  Future<String> createException({
    required String dentistMemberId,
    required ScheduleExceptionKind kind,
    required DateTime startsAt,
    required DateTime endsAt,
    String? reason,
    bool confirmAffectedAppointments = false,
    String? appointmentImpactReason,
  }) async {
    final start = ScheduleValidation.intervalStart(startsAt);
    final end = ScheduleValidation.intervalEnd(start, endsAt);
    final response = await _source.invokeScheduleAction({
      'action': 'create_exception',
      'dentistMemberId': ScheduleValidation.id(dentistMemberId),
      'kind': kind.apiValue,
      'startsAt': start.toIso8601String(),
      'endsAt': end.toIso8601String(),
      'reason': ScheduleValidation.reason(reason),
      'confirmAffectedAppointments': confirmAffectedAppointments,
      'appointmentImpactReason': ScheduleValidation.reason(
        appointmentImpactReason,
      ),
    });
    return _string(response, 'exceptionId');
  }

  @override
  Future<ScheduleImpactPreview> previewExceptionImpact({
    required String dentistMemberId,
    required DateTime startsAt,
    required DateTime endsAt,
  }) async {
    final start = ScheduleValidation.intervalStart(startsAt);
    final end = ScheduleValidation.intervalEnd(start, endsAt);
    final response = await _source.invokeScheduleAction({
      'action': 'preview_exception_impact',
      'dentistMemberId': ScheduleValidation.id(dentistMemberId),
      'startsAt': start.toIso8601String(),
      'endsAt': end.toIso8601String(),
    });
    final count = response['count'];
    if (count is! int || count < 0) throw const ServerFailure();
    return ScheduleImpactPreview(count: count);
  }

  @override
  Future<void> updateException({
    required String exceptionId,
    required ScheduleExceptionKind kind,
    required DateTime startsAt,
    required DateTime endsAt,
    String? reason,
  }) async {
    final start = ScheduleValidation.intervalStart(startsAt);
    final end = ScheduleValidation.intervalEnd(start, endsAt);
    await _complete({
      'action': 'update_exception',
      'exceptionId': ScheduleValidation.id(exceptionId),
      'kind': kind.apiValue,
      'startsAt': start.toIso8601String(),
      'endsAt': end.toIso8601String(),
      'reason': ScheduleValidation.reason(reason),
    });
  }

  @override
  Future<void> deleteException(String exceptionId) => _complete({
    'action': 'delete_exception',
    'exceptionId': ScheduleValidation.id(exceptionId),
  });

  Future<void> _complete(Map<String, dynamic> request) async {
    final response = await _source.invokeScheduleAction(request);
    if (response['ok'] != true) throw const ServerFailure();
  }

  List<Map<String, Object>> _periods(List<DoctorWorkingPeriod> periods) =>
      ScheduleValidation.periods(periods)
          .map(
            (period) => <String, Object>{
              'weekday': period.weekday,
              'startsAt': period.startsAt,
              'endsAt': period.endsAt,
              'breaks': period.breaks
                  .map(
                    (pause) => <String, Object>{
                      'startsAt': pause.startsAt,
                      'endsAt': pause.endsAt,
                    },
                  )
                  .toList(growable: false),
            },
          )
          .toList(growable: false);

  DoctorScheduleVersion _versionFromRow(Map<String, dynamic> row) =>
      DoctorScheduleVersion(
        id: _string(row, 'id'),
        clinicId: _string(row, 'clinic_id'),
        dentistMemberId: _string(row, 'dentist_member_id'),
        effectiveFrom: ScheduleValidation.localDate(
          _string(row, 'effective_from'),
        ),
        workingPeriods: _list(
          row,
          'doctor_working_hours',
        ).map(_periodFromRow).toList(growable: false),
      );

  DoctorWorkingPeriod _periodFromRow(Map<String, dynamic> row) =>
      DoctorWorkingPeriod(
        id: _string(row, 'id'),
        weekday: _weekday(row['weekday']),
        startsAt: ScheduleValidation.databaseTime(_string(row, 'starts_at')),
        endsAt: ScheduleValidation.databaseTime(_string(row, 'ends_at')),
        breaks: _list(row, 'doctor_schedule_breaks')
            .map(
              (pause) => DoctorScheduleBreak(
                id: _string(pause, 'id'),
                startsAt: ScheduleValidation.databaseTime(
                  _string(pause, 'starts_at'),
                ),
                endsAt: ScheduleValidation.databaseTime(
                  _string(pause, 'ends_at'),
                ),
              ),
            )
            .toList(growable: false),
      );

  DoctorScheduleException _exceptionFromRow(Map<String, dynamic> row) =>
      DoctorScheduleException(
        id: _string(row, 'id'),
        clinicId: _string(row, 'clinic_id'),
        dentistMemberId: _string(row, 'dentist_member_id'),
        kind:
            ScheduleExceptionKind.fromApi(row['kind']) ??
            (throw const ServerFailure()),
        startsAt: _date(row, 'starts_at'),
        endsAt: _date(row, 'ends_at'),
        reason: _optionalReason(row['reason']),
      );

  List<Map<String, dynamic>> _list(Map<String, dynamic> row, String key) {
    final value = row[key];
    if (value is! List) throw const ServerFailure();
    return value
        .map((item) {
          if (item is! Map) throw const ServerFailure();
          return Map<String, dynamic>.from(item);
        })
        .toList(growable: false);
  }

  String _string(Map<String, dynamic> value, String key) {
    final result = value[key];
    if (result is! String || result.isEmpty) throw const ServerFailure();
    return result;
  }

  int _weekday(Object? value) => value is int && value >= 1 && value <= 7
      ? value
      : throw const ServerFailure();

  DateTime _date(Map<String, dynamic> value, String key) {
    final raw = _string(value, key);
    return DateTime.tryParse(raw)?.toUtc() ?? (throw const ServerFailure());
  }

  String? _optionalReason(Object? value) {
    if (value == null) return null;
    if (value is! String || value.isEmpty) throw const ServerFailure();
    return value;
  }
}

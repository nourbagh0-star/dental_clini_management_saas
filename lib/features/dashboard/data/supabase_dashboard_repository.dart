import 'package:injectable/injectable.dart';

import '../../../core/error/app_failure.dart';
import '../../../core/value/money.dart';
import '../../appointment/domain/appointment_models.dart';
import '../domain/dashboard_models.dart';
import '../domain/dashboard_repository.dart';
import 'dashboard_data_source.dart';

@LazySingleton(as: DashboardRepository)
class SupabaseDashboardRepository implements DashboardRepository {
  SupabaseDashboardRepository(this._source);

  final DashboardDataSource _source;

  static final RegExp _uuid = RegExp(
    r'^[0-9a-f]{8}-[0-9a-f]{4}-[1-5][0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$',
    caseSensitive: false,
  );

  @override
  Future<DashboardSnapshot> load(String clinicId) async {
    if (!_uuid.hasMatch(clinicId)) throw const ValidationFailure();
    try {
      final row = await _source.snapshot(clinicId);
      final capabilities = _map(row, 'capabilities');
      final metrics = _map(row, 'metrics');
      final canViewCompleted = _boolean(
        capabilities,
        'canViewCompletedTreatments',
      );
      final canViewFinancial = _boolean(
        capabilities,
        'canViewFinancialSummary',
      );
      final completed = metrics['completedTreatmentsThisMonth'];
      final financial = metrics['financial'];
      if (canViewCompleted != (completed != null) ||
          canViewFinancial != (financial != null)) {
        throw const ServerFailure();
      }
      final snapshot = DashboardSnapshot(
        clinicId: _id(row, 'clinicId'),
        clinicTimeZone: _text(row, 'clinicTimeZone'),
        generatedAt: _date(row, 'generatedAt'),
        period: _period(_map(row, 'periods')),
        capabilities: DashboardCapabilities(
          canViewCompletedTreatments: canViewCompleted,
          canViewFinancialSummary: canViewFinancial,
        ),
        metrics: DashboardMetrics(
          totalPatients: _count(metrics, 'totalPatients'),
          appointmentsThisWeek: _count(metrics, 'appointmentsThisWeek'),
          completedTreatmentsThisMonth: completed == null
              ? null
              : _count(metrics, 'completedTreatmentsThisMonth'),
          financial: financial == null
              ? null
              : _financial(Map<String, dynamic>.from(financial as Map)),
        ),
        todayAppointments: _section(_map(row, 'todayAppointments')),
        upcomingAppointments: _section(_map(row, 'upcomingAppointments')),
      );
      if (snapshot.clinicId != clinicId) throw const ServerFailure();
      return snapshot;
    } on AppFailure {
      rethrow;
    } on Object {
      throw const ServerFailure();
    }
  }

  DashboardPeriod _period(Map<String, dynamic> row) => DashboardPeriod(
    todayStart: _date(row, 'todayStart'),
    tomorrowStart: _date(row, 'tomorrowStart'),
    upcomingEnd: _date(row, 'upcomingEnd'),
    weekStart: _date(row, 'weekStart'),
    weekEnd: _date(row, 'weekEnd'),
    monthStart: _date(row, 'monthStart'),
    nextMonthStart: _date(row, 'nextMonthStart'),
  );

  DashboardFinancialSummary _financial(Map<String, dynamic> row) {
    final currency = _text(row, 'currencyCode');
    if (!RegExp(r'^[A-Z]{3}$').hasMatch(currency)) {
      throw const ServerFailure();
    }
    return DashboardFinancialSummary(
      outstandingInvoiceCount: _count(row, 'outstandingInvoiceCount'),
      outstandingAmount: Money.parseCanonical(_text(row, 'outstandingAmount')),
      currencyCode: currency,
    );
  }

  DashboardAppointmentSection _section(Map<String, dynamic> row) {
    final values = row['items'];
    if (values is! List) throw const ServerFailure();
    final items = values
        .map((value) {
          if (value is! Map) throw const ServerFailure();
          final item = Map<String, dynamic>.from(value);
          final rawStatus = _text(item, 'status');
          if (!const {
            'scheduled',
            'confirmed',
            'in_progress',
            'completed',
            'cancelled',
            'no_show',
          }.contains(rawStatus)) {
            throw const ServerFailure();
          }
          return DashboardAppointmentPreview(
            id: _id(item, 'id'),
            patientId: _id(item, 'patientId'),
            patientName: _text(item, 'patientName'),
            patientNumber: _text(item, 'patientNumber'),
            dentistMemberId: _id(item, 'dentistMemberId'),
            dentistLabel: _text(item, 'dentistLabel'),
            startsAt: _date(item, 'startsAt'),
            endsAt: _date(item, 'endsAt'),
            status: AppointmentStatus.fromApi(rawStatus),
          );
        })
        .toList(growable: false);
    final totalCount = _count(row, 'totalCount');
    if (items.length > totalCount) throw const ServerFailure();
    return DashboardAppointmentSection(
      totalCount: totalCount,
      hasMore: _boolean(row, 'hasMore'),
      items: items,
    );
  }

  Map<String, dynamic> _map(Map<String, dynamic> row, String key) {
    final value = row[key];
    return value is Map
        ? Map<String, dynamic>.from(value)
        : throw const ServerFailure();
  }

  String _id(Map<String, dynamic> row, String key) {
    final value = _text(row, key);
    return _uuid.hasMatch(value) ? value : throw const ServerFailure();
  }

  String _text(Map<String, dynamic> row, String key) {
    final value = row[key];
    return value is String && value.isNotEmpty
        ? value
        : throw const ServerFailure();
  }

  bool _boolean(Map<String, dynamic> row, String key) =>
      row[key] is bool ? row[key] as bool : throw const ServerFailure();

  int _count(Map<String, dynamic> row, String key) {
    final value = row[key];
    return value is int && value >= 0 ? value : throw const ServerFailure();
  }

  DateTime _date(Map<String, dynamic> row, String key) {
    final raw = _text(row, key);
    final value = DateTime.tryParse(raw);
    return value != null && raw.contains(RegExp(r'(Z|[+-]\d\d:\d\d)$'))
        ? value.toUtc()
        : throw const ServerFailure();
  }
}

import 'dart:math';

import 'package:injectable/injectable.dart';

import '../../../core/error/app_failure.dart';
import '../domain/audit_models.dart';
import '../domain/audit_repository.dart';
import 'audit_data_source.dart';

@LazySingleton(as: AuditRepository)
class SupabaseAuditRepository implements AuditRepository {
  SupabaseAuditRepository(this._source);

  final AuditDataSource _source;
  static final _uuid = RegExp(
    r'^[0-9a-f]{8}-[0-9a-f]{4}-[1-5][0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$',
    caseSensitive: false,
  );
  static final _plainDate = RegExp(r'^\d{4}-\d{2}-\d{2}$');
  static const _roles = {'owner', 'dentist', 'assistant', 'receptionist'};
  static const _contextKeys = {
    'patient_id',
    'invoice_id',
    'appointment_id',
    'amendment_id',
    'category',
    'currency',
    'amount',
    'total',
    'command_id',
    'invoice_number',
    'financial_revision',
    'locale',
    'result_count',
    'page_size',
    'search_present',
    'access_intent',
    'previous_status',
    'next_status',
    'member_id',
    'roles',
  };

  @override
  Future<AuditPage> page({
    required String clinicId,
    required AuditFilter filter,
    AuditCursor? cursor,
    int limit = 50,
  }) async {
    _requireId(clinicId);
    if (limit < 1 ||
        limit > 50 ||
        filter.toDateExclusive.difference(filter.fromDate).inDays > 90 ||
        !filter.toDateExclusive.isAfter(filter.fromDate)) {
      throw const ValidationFailure();
    }
    if (filter.actorUserId case final actor?) _requireId(actor);
    try {
      final row = await _source.page({
        'clinicId': clinicId,
        'from': _dateOnly(filter.fromDate),
        'to': _dateOnly(filter.toDateExclusive),
        'limit': limit,
        if (filter.actorUserId != null) 'actorUserId': filter.actorUserId,
        if (filter.category != null) 'category': filter.category!.apiValue,
        if (filter.eventType != null) 'eventType': filter.eventType,
        if (filter.subjectType != null) 'subjectType': filter.subjectType,
        if (cursor != null) ...{
          'cursorAt': cursor.occurredAt.toUtc().toIso8601String(),
          'cursorId': cursor.id,
        },
      });
      final page = _page(row);
      if (page.clinicId != clinicId ||
          !_sameDate(page.fromDate, filter.fromDate) ||
          !_sameDate(page.toDateExclusive, filter.toDateExclusive)) {
        throw const ServerFailure();
      }
      return page;
    } on AppFailure {
      rethrow;
    } on Object {
      throw const ServerFailure();
    }
  }

  @override
  Future<void> recordAccess({
    required String clinicId,
    required AuditAccessIntent intent,
    required String subjectId,
    String? requestId,
    int? resultCount,
    int? pageSize,
    bool? searchPresent,
  }) async {
    _requireId(clinicId);
    _requireId(subjectId);
    final id = requestId ?? _requestId();
    _requireId(id);
    final response = await _source.recordAccess({
      'clinicId': clinicId,
      'intent': intent.apiValue,
      'subjectId': subjectId,
      'requestId': id,
      'resultCount': ?resultCount,
      'pageSize': ?pageSize,
      'searchPresent': ?searchPresent,
    });
    _requireId(_text(response, 'eventId'));
  }

  AuditPage _page(Map<String, dynamic> row) {
    final rawItems = row['items'];
    final rawActors = row['actors'];
    if (rawItems is! List || rawActors is! List) throw const ServerFailure();
    final cursorValue = row['nextCursor'];
    final cursor = cursorValue == null
        ? null
        : _cursor(Map<String, dynamic>.from(cursorValue as Map));
    final hasMore = _boolean(row, 'hasMore');
    if (hasMore != (cursor != null)) throw const ServerFailure();
    return AuditPage(
      clinicId: _id(row, 'clinicId'),
      clinicTimeZone: _text(row, 'clinicTimeZone'),
      fromDate: _date(row, 'rangeFrom'),
      toDateExclusive: _date(row, 'rangeToExclusive'),
      items: rawItems
          .map((value) => _event(_map(value)))
          .toList(growable: false),
      actors: rawActors
          .map((value) => _actor(_map(value)))
          .toList(growable: false),
      hasMore: hasMore,
      nextCursor: cursor,
    );
  }

  AuditEvent _event(Map<String, dynamic> row) {
    final rawRoles = row['actorRoles'];
    if (rawRoles is! List || rawRoles.any((role) => !_roles.contains(role))) {
      throw const ServerFailure();
    }
    final rawContext = row['context'];
    if (rawContext is! Map) throw const ServerFailure();
    final context = Map<String, dynamic>.from(rawContext);
    if (context.keys.any((key) => !_contextKeys.contains(key))) {
      throw const ServerFailure();
    }
    final category = AuditCategory.fromApi(row['category']);
    if (category == null) throw const ServerFailure();
    return AuditEvent(
      id: _id(row, 'id'),
      actorUserId: _id(row, 'actorUserId'),
      actorMemberId: _optionalId(row['actorMemberId']),
      actorEmail: _optionalText(row['actorEmail']),
      actorRoles: Set<String>.unmodifiable(rawRoles.cast<String>()),
      category: category,
      eventType: _text(row, 'eventType'),
      subjectType: _text(row, 'subjectType'),
      subjectId: _id(row, 'subjectId'),
      reason: _optionalText(row['reason']),
      context: _context(context),
      occurredAt: _instant(row, 'occurredAt'),
    );
  }

  AuditContext _context(Map<String, dynamic> value) => AuditContext(
    patientId: _contextId(value['patient_id']),
    invoiceId: _contextId(value['invoice_id']),
    appointmentId: _contextId(value['appointment_id']),
    memberId: _contextId(value['member_id']),
    amount: _contextText(value['amount']),
    currency: _contextText(value['currency']),
    previousStatus: _contextText(value['previous_status']),
    nextStatus: _contextText(value['next_status']),
    resultCount: _contextInt(value['result_count']),
    searchPresent: _contextBool(value['search_present']),
  );

  AuditActorOption _actor(Map<String, dynamic> row) => AuditActorOption(
    userId: _id(row, 'userId'),
    memberId: _id(row, 'memberId'),
    email: _text(row, 'email'),
    isActive: _boolean(row, 'isActive'),
  );

  AuditCursor _cursor(Map<String, dynamic> row) =>
      AuditCursor(occurredAt: _instant(row, 'occurredAt'), id: _id(row, 'id'));

  Map<String, dynamic> _map(Object? value) => value is Map
      ? Map<String, dynamic>.from(value)
      : throw const ServerFailure();
  String _text(Map<String, dynamic> row, String key) =>
      row[key] is String && (row[key] as String).isNotEmpty
      ? row[key] as String
      : throw const ServerFailure();
  String _id(Map<String, dynamic> row, String key) {
    final value = _text(row, key);
    _requireId(value);
    return value;
  }

  String? _optionalId(Object? value) {
    if (value == null) return null;
    if (value is! String) throw const ServerFailure();
    _requireId(value);
    return value;
  }

  String? _optionalText(Object? value) => value == null
      ? null
      : value is String && value.isNotEmpty
      ? value
      : throw const ServerFailure();
  bool _boolean(Map<String, dynamic> row, String key) =>
      row[key] is bool ? row[key] as bool : throw const ServerFailure();
  DateTime _instant(Map<String, dynamic> row, String key) {
    final raw = _text(row, key);
    final value = DateTime.tryParse(raw);
    return value != null && raw.contains(RegExp(r'(Z|[+-]\d\d:\d\d)$'))
        ? value.toUtc()
        : throw const ServerFailure();
  }

  DateTime _date(Map<String, dynamic> row, String key) {
    final raw = _text(row, key);
    if (!_plainDate.hasMatch(raw)) throw const ServerFailure();
    return DateTime.parse(raw);
  }

  String? _contextId(Object? value) {
    if (value == null) return null;
    if (value is! String || !_uuid.hasMatch(value)) throw const ServerFailure();
    return value;
  }

  String? _contextText(Object? value) => value == null
      ? null
      : value is String
      ? value
      : throw const ServerFailure();
  int? _contextInt(Object? value) => value == null
      ? null
      : value is int && value >= 0
      ? value
      : throw const ServerFailure();
  bool? _contextBool(Object? value) => value == null
      ? null
      : value is bool
      ? value
      : throw const ServerFailure();
  void _requireId(String value) {
    if (!_uuid.hasMatch(value)) throw const ValidationFailure();
  }

  String _dateOnly(DateTime value) =>
      '${value.year.toString().padLeft(4, '0')}-'
      '${value.month.toString().padLeft(2, '0')}-'
      '${value.day.toString().padLeft(2, '0')}';
  bool _sameDate(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  String _requestId() {
    final random = Random.secure();
    final bytes = List<int>.generate(16, (_) => random.nextInt(256));
    bytes[6] = (bytes[6] & 0x0f) | 0x40;
    bytes[8] = (bytes[8] & 0x3f) | 0x80;
    final value = bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
    return '${value.substring(0, 8)}-${value.substring(8, 12)}-'
        '${value.substring(12, 16)}-${value.substring(16, 20)}-'
        '${value.substring(20)}';
  }
}

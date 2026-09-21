import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:injectable/injectable.dart';

import '../config/app_config.dart';
import '../network/supabase_connection.dart';

abstract interface class ServerSession {
  Future<void> restore();
  Future<void> unlock(String password);
  Future<void> completePasswordSetup();
  Future<void> renew();
  Future<void> lock();
  void clear();
}

class ServerSessionException implements Exception {
  const ServerSessionException(this.kind);
  final ServerSessionIssue kind;
}

enum ServerSessionIssue {
  passwordChangeRequired,
  credentials,
  authentication,
  locked,
  unavailable,
}

@lazySingleton
class SupabaseServerSession implements ServerSession {
  SupabaseServerSession(AppConfig config, this._connection)
    : _key = config.publishableKey ?? '',
      _client = Dio(
        BaseOptions(
          baseUrl:
              '${config.supabaseUrl ?? Uri.parse('https://backend.invalid')}/functions/v1/',
          connectTimeout: const Duration(seconds: 15),
          sendTimeout: kIsWeb ? null : const Duration(seconds: 15),
          receiveTimeout: const Duration(seconds: 20),
          followRedirects: false,
          validateStatus: (status) => status != null && status < 600,
        ),
      ) {
    if (kIsWeb) {
      _client.interceptors.add(
        InterceptorsWrapper(
          onRequest: (options, handler) {
            if (options.data == null) {
              options.sendTimeout = null;
            }
            handler.next(options);
          },
        ),
      );
    }
  }

  final Dio _client;
  final SupabaseConnection _connection;
  final String _key;
  int? _revision;
  DateTime? _unlockedUntil;
  Future<void>? _renewing;

  Options _options() {
    final token = _connection.accessToken;
    if (token == null) {
      throw const ServerSessionException(ServerSessionIssue.authentication);
    }
    return Options(
      headers: {'apikey': _key, 'authorization': 'Bearer $token'},
      contentType: Headers.jsonContentType,
    );
  }

  Future<Map<String, dynamic>> _post(Map<String, Object?> body) async {
    try {
      final response = await _client.post<dynamic>(
        'security-session',
        data: body,
        options: _options(),
      );
      final data = response.data;
      if (response.statusCode == 200 && data is Map) {
        return Map<String, dynamic>.from(data);
      }
      final code = data is Map ? data['error'] : null;
      if (code == 'password_change_required') {
        throw const ServerSessionException(
          ServerSessionIssue.passwordChangeRequired,
        );
      }
      if (code == 'credentials_invalid') {
        throw const ServerSessionException(ServerSessionIssue.credentials);
      }
      if (code == 'authentication_required') {
        throw const ServerSessionException(ServerSessionIssue.authentication);
      }
      if (code == 'session_locked') {
        throw const ServerSessionException(ServerSessionIssue.locked);
      }
      throw const ServerSessionException(ServerSessionIssue.unavailable);
    } on ServerSessionException {
      rethrow;
    } on Object {
      throw const ServerSessionException(ServerSessionIssue.unavailable);
    }
  }

  void _accept(Map<String, dynamic> value) {
    final revision = value['revision'];
    final until = DateTime.tryParse(value['unlockedUntil'] as String? ?? '');
    if (revision is! int || revision < 1 || until == null || !until.isUtc) {
      throw const ServerSessionException(ServerSessionIssue.unavailable);
    }
    _revision = revision;
    _unlockedUntil = until;
  }

  @override
  Future<void> restore() async {
    final result = await _post({'action': 'restore'});
    _accept(result);
  }

  @override
  Future<void> unlock(String password) async {
    final result = await _post({'action': 'unlock', 'password': password});
    _accept(result);
  }

  @override
  Future<void> completePasswordSetup() async {
    final result = await _post({'action': 'complete_password_setup'});
    if (result['ok'] != true) {
      throw const ServerSessionException(ServerSessionIssue.unavailable);
    }
    clear();
  }

  @override
  Future<void> renew() {
    final current = _renewing;
    if (current != null) return current;
    final revision = _revision;
    if (revision == null ||
        _unlockedUntil == null ||
        !_unlockedUntil!.isAfter(DateTime.now().toUtc())) {
      return Future.error(
        const ServerSessionException(ServerSessionIssue.locked),
      );
    }
    final pending = _post({
      'action': 'renew',
      'revision': revision,
    }).then(_accept);
    _renewing = pending;
    return pending.whenComplete(() {
      if (identical(_renewing, pending)) _renewing = null;
    });
  }

  @override
  Future<void> lock() async {
    try {
      await _post({'action': 'lock'});
    } finally {
      clear();
    }
  }

  @override
  void clear() {
    _revision = null;
    _unlockedUntil = null;
  }

  @disposeMethod
  void dispose() => _client.close(force: true);
}

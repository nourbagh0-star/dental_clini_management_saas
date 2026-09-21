import 'package:dio/dio.dart';
import 'package:injectable/injectable.dart';

import '../../../core/error/app_failure.dart';
import '../../../core/network/dio_client.dart';
import '../../../core/network/interceptors/auth_interceptor.dart';
import 'audit_data_source.dart';

@LazySingleton(as: AuditDataSource)
class SupabaseAuditDataSource implements AuditDataSource {
  SupabaseAuditDataSource(this._functions);

  final DioClient _functions;

  @override
  Future<Map<String, dynamic>> page(Map<String, dynamic> query) => _request(
    () => _functions.client.get<Map<String, dynamic>>(
      'audit-events',
      queryParameters: query,
      options: Options(extra: {AuthInterceptor.requiresAuth: true}),
    ),
  );

  @override
  Future<Map<String, dynamic>> recordAccess(Map<String, dynamic> body) =>
      _request(
        () => _functions.client.post<Map<String, dynamic>>(
          'audit-events',
          data: body,
          options: Options(extra: {AuthInterceptor.requiresAuth: true}),
        ),
      );

  Future<Map<String, dynamic>> _request(
    Future<Response<Map<String, dynamic>>> Function() action,
  ) async {
    try {
      final response = await action();
      if (response.data == null) throw const ServerFailure();
      return Map<String, dynamic>.from(response.data!);
    } on DioException catch (error) {
      final body = error.response?.data;
      final code = body is Map ? body['error'] : null;
      if (code == 'audit_forbidden') throw const AuthorizationFailure();
      if (code == 'authentication_required') {
        throw const AuthenticationFailure();
      }
      if (code == 'invalid_audit_request') throw const ValidationFailure();
      if (code == 'audit_unavailable') throw const ServerFailure();
      if (error.error case final AppFailure failure) throw failure;
      throw const UnknownFailure();
    }
  }
}

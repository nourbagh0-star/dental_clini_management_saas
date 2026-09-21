import 'package:dio/dio.dart';
import 'package:injectable/injectable.dart';

import '../../../core/error/app_failure.dart';
import '../../../core/network/dio_client.dart';
import '../../../core/network/interceptors/auth_interceptor.dart';
import 'dashboard_data_source.dart';

@LazySingleton(as: DashboardDataSource)
class SupabaseDashboardDataSource implements DashboardDataSource {
  SupabaseDashboardDataSource(this._functions);

  final DioClient _functions;

  @override
  Future<Map<String, dynamic>> snapshot(String clinicId) async {
    try {
      final response = await _functions.client.get<Map<String, dynamic>>(
        'dashboard',
        queryParameters: {'clinicId': clinicId},
        options: Options(extra: {AuthInterceptor.requiresAuth: true}),
      );
      if (response.data == null) throw const ServerFailure();
      return Map<String, dynamic>.from(response.data!);
    } on DioException catch (error) {
      final body = error.response?.data;
      final code = body is Map ? body['error'] : null;
      if (code == 'dashboard_forbidden') {
        throw const AuthorizationFailure();
      }
      if (code == 'authentication_required') {
        throw const AuthenticationFailure();
      }
      if (code == 'invalid_dashboard_request') {
        throw const ValidationFailure();
      }
      if (code == 'dashboard_unavailable') throw const ServerFailure();
      if (error.error case final AppFailure failure) throw failure;
      throw const UnknownFailure();
    }
  }
}

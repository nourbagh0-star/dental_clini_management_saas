import 'package:injectable/injectable.dart';
import 'package:dio/dio.dart';

import '../../../core/error/app_failure.dart';
import '../../../core/network/dio_client.dart';
import '../../../core/network/interceptors/auth_interceptor.dart';

@lazySingleton
class SupabaseClinicDataSource {
  SupabaseClinicDataSource(this._functions);
  final DioClient _functions;

  Future<List<Map<String, dynamic>>> getMyActiveMembershipRows() async {
    try {
      return await _rows({'action': 'memberships'});
    } on AppFailure {
      rethrow;
    }
  }

  Future<List<Map<String, dynamic>>> getRolesForMembershipIds(
    List<String> membershipIds,
  ) async {
    if (membershipIds.isEmpty) return const [];
    try {
      return await _rows({'action': 'roles', 'membershipIds': membershipIds});
    } on AppFailure {
      rethrow;
    }
  }

  Future<List<Map<String, dynamic>>> getClinicsByIds(
    List<String> clinicIds,
  ) async {
    if (clinicIds.isEmpty) return const [];
    try {
      return await _rows({'action': 'clinics', 'clinicIds': clinicIds});
    } on AppFailure {
      rethrow;
    }
  }

  Future<Map<String, dynamic>> createClinic({
    required String name,
    required String ownerDisplayName,
    required String currencyCode,
    required String timeZone,
  }) async {
    try {
      return await _invoke({
        'action': 'create',
        'name': name.trim(),
        'ownerDisplayName': ownerDisplayName.trim(),
        'currencyCode': currencyCode,
        'timeZone': timeZone,
      });
    } on AppFailure {
      rethrow;
    }
  }

  Future<List<Map<String, dynamic>>> _rows(Map<String, dynamic> request) async {
    final body = await _invoke(request);
    return List<Map<String, dynamic>>.from(body['rows'] as List? ?? const []);
  }

  Future<Map<String, dynamic>> _invoke(Map<String, dynamic> request) async {
    try {
      final response = await _functions.client.post<Map<String, dynamic>>(
        'workspace',
        data: request,
        options: Options(extra: {AuthInterceptor.requiresAuth: true}),
      );
      if (response.data == null) throw const ServerFailure();
      return Map<String, dynamic>.from(response.data!);
    } on DioException catch (error) {
      if (error.error case final AppFailure failure) throw failure;
      throw const NetworkFailure();
    }
  }
}

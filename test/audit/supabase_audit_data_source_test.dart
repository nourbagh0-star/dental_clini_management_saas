import 'package:dental_clini_management_saas/core/config/app_config.dart';
import 'package:dental_clini_management_saas/core/error/app_failure.dart';
import 'package:dental_clini_management_saas/core/network/dio_client.dart';
import 'package:dental_clini_management_saas/features/audit/data/supabase_audit_data_source.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/fakes.dart';

void main() {
  late DioClient functions;
  late SupabaseAuditDataSource source;
  late FakeHttpAdapter adapter;

  setUp(() {
    functions = DioClient(
      AppConfig.parse(
        supabaseUrl: 'https://demo.supabase.co',
        publishableKey: 'sb_publishable_demo',
      ),
      FakeTokens(),
    );
    source = SupabaseAuditDataSource(functions);
    adapter = FakeHttpAdapter((_) => jsonResponse(200, '{"items":[]}'));
    functions.client.httpClientAdapter = adapter;
  });

  tearDown(() => functions.dispose());

  test('uses authenticated GET for an owner page', () async {
    await source.page({'clinicId': 'clinic-1', 'from': '2026-09-01'});

    final request = adapter.requests.single;
    expect(request.method, 'GET');
    expect(request.uri.path, '/functions/v1/audit-events');
    expect(request.headers['Authorization'], 'Bearer expired');
    expect(request.uri.queryParameters['clinicId'], 'clinic-1');
  });

  test('uses a non-replayed POST for access recording', () async {
    await source.recordAccess({'intent': 'audit_log'});

    final request = adapter.requests.single;
    expect(request.method, 'POST');
    expect(request.uri.path, '/functions/v1/audit-events');
    expect(request.data, {'intent': 'audit_log'});
  });

  test('maps owner denial without exposing provider details', () async {
    adapter = FakeHttpAdapter(
      (_) => jsonResponse(403, '{"error":"audit_forbidden"}'),
    );
    functions.client.httpClientAdapter = adapter;

    await expectLater(source.page({}), throwsA(isA<AuthorizationFailure>()));
  });
}

import 'package:dental_clini_management_saas/core/config/app_config.dart';
import 'package:dental_clini_management_saas/core/error/app_failure.dart';
import 'package:dental_clini_management_saas/core/network/dio_client.dart';
import 'package:dental_clini_management_saas/features/dashboard/data/supabase_dashboard_data_source.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/fakes.dart';

void main() {
  late DioClient functions;
  late SupabaseDashboardDataSource source;
  late FakeHttpAdapter adapter;

  setUp(() {
    final config = AppConfig.parse(
      supabaseUrl: 'https://demo.supabase.co',
      publishableKey: 'sb_publishable_demo',
    );
    functions = DioClient(config, FakeTokens());
    source = SupabaseDashboardDataSource(functions);
    adapter = FakeHttpAdapter(
      (_) => jsonResponse(200, '{"clinicId":"clinic-1"}'),
    );
    functions.client.httpClientAdapter = adapter;
  });

  tearDown(() => functions.dispose());

  test('uses an authenticated safe GET scoped to one clinic', () async {
    await source.snapshot('clinic-1');

    final request = adapter.requests.single;
    expect(request.method, 'GET');
    expect(request.uri.path, '/functions/v1/dashboard');
    expect(request.uri.queryParameters, {'clinicId': 'clinic-1'});
    expect(request.headers['Authorization'], 'Bearer expired');
    expect(request.data, isNull);
  });

  test('maps server permission denial to authorization failure', () async {
    adapter = FakeHttpAdapter(
      (_) => jsonResponse(403, '{"error":"dashboard_forbidden"}'),
    );
    functions.client.httpClientAdapter = adapter;

    await expectLater(
      source.snapshot('clinic-1'),
      throwsA(isA<AuthorizationFailure>()),
    );
  });
}

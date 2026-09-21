import 'package:dental_clini_management_saas/core/config/app_config.dart';
import 'package:dental_clini_management_saas/core/network/dio_client.dart';
import 'package:dental_clini_management_saas/core/network/supabase_connection.dart';
import 'package:dental_clini_management_saas/features/treatment_plan/data/supabase_treatment_plan_data_source.dart';
import 'package:dental_clini_management_saas/features/treatment_plan/domain/treatment_plan_models.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/fakes.dart';

void main() {
  late SupabaseConnection connection;
  late DioClient functions;
  late SupabaseTreatmentPlanDataSource source;
  late FakeHttpAdapter adapter;

  setUp(() {
    final config = AppConfig.parse(
      supabaseUrl: 'https://demo.supabase.co',
      publishableKey: 'sb_publishable_demo',
    );
    connection = SupabaseConnection(config);
    functions = DioClient(config, FakeTokens());
    source = SupabaseTreatmentPlanDataSource(functions);
    adapter = FakeHttpAdapter((_) => jsonResponse(200, '{"ok":true}'));
    functions.client.httpClientAdapter = adapter;
  });

  tearDown(() async {
    functions.dispose();
    await connection.dispose();
  });

  test('sends mutations through the authenticated Edge Function', () async {
    await source.invokeAction({
      'action': 'transition_plan',
      'planId': 'plan-1',
      'status': 'active',
    });

    final request = adapter.requests.single;
    expect(request.uri.path, '/functions/v1/treatment-plans');
    expect(request.headers['Authorization'], 'Bearer expired');
    expect(request.data, {
      'action': 'transition_plan',
      'planId': 'plan-1',
      'status': 'active',
    });
  });

  test('maps a second active plan to a typed safe outcome', () async {
    adapter = FakeHttpAdapter(
      (_) => jsonResponse(409, '{"error":"treatment_plan_active_exists"}'),
    );
    functions.client.httpClientAdapter = adapter;

    await expectLater(
      source.invokeAction({'action': 'transition_plan'}),
      throwsA(
        isA<TreatmentPlanOperationException>().having(
          (error) => error.issue,
          'issue',
          TreatmentPlanOperationIssue.activePlanExists,
        ),
      ),
    );
  });
}

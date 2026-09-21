import 'package:dental_clini_management_saas/core/config/app_config.dart';
import 'package:dental_clini_management_saas/core/network/dio_client.dart';
import 'package:dental_clini_management_saas/core/network/supabase_connection.dart';
import 'package:dental_clini_management_saas/features/odontogram/data/supabase_odontogram_data_source.dart';
import 'package:dental_clini_management_saas/features/odontogram/domain/odontogram_models.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/fakes.dart';

void main() {
  late SupabaseConnection connection;
  late DioClient functions;
  late SupabaseOdontogramDataSource source;
  late FakeHttpAdapter adapter;

  setUp(() {
    final config = AppConfig.parse(
      supabaseUrl: 'https://demo.supabase.co',
      publishableKey: 'sb_publishable_demo',
    );
    connection = SupabaseConnection(config);
    functions = DioClient(config, FakeTokens());
    source = SupabaseOdontogramDataSource(functions);
    adapter = FakeHttpAdapter((_) => jsonResponse(200, '{"ok":true}'));
    functions.client.httpClientAdapter = adapter;
  });

  tearDown(() async {
    functions.dispose();
    await connection.dispose();
  });

  test(
    'sends Dental Chart mutations through the authenticated Edge Function',
    () async {
      await source.invokeAction({
        'action': 'resolve_condition',
        'conditionId': 'condition-1',
      });

      final request = adapter.requests.single;
      expect(request.uri.path, '/functions/v1/odontogram');
      expect(request.headers['Authorization'], 'Bearer expired');
      expect(request.data, {
        'action': 'resolve_condition',
        'conditionId': 'condition-1',
      });
    },
  );

  test('maps a missing-tooth conflict to a typed safe outcome', () async {
    adapter = FakeHttpAdapter(
      (_) => jsonResponse(409, '{"error":"missing_tooth_conflict"}'),
    );
    functions.client.httpClientAdapter = adapter;

    await expectLater(
      source.invokeAction({'action': 'create_condition'}),
      throwsA(
        isA<OdontogramOperationException>().having(
          (error) => error.issue,
          'issue',
          OdontogramOperationIssue.missingToothConflict,
        ),
      ),
    );
  });
}

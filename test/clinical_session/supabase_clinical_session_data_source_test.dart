import 'package:dental_clini_management_saas/core/config/app_config.dart';
import 'package:dental_clini_management_saas/core/network/dio_client.dart';
import 'package:dental_clini_management_saas/core/network/supabase_connection.dart';
import 'package:dental_clini_management_saas/features/clinical_session/data/supabase_clinical_session_data_source.dart';
import 'package:dental_clini_management_saas/features/clinical_session/domain/clinical_session_models.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/fakes.dart';

void main() {
  late SupabaseConnection connection;
  late DioClient functions;
  late SupabaseClinicalSessionDataSource source;
  late FakeHttpAdapter adapter;

  setUp(() {
    final config = AppConfig.parse(
      supabaseUrl: 'https://demo.supabase.co',
      publishableKey: 'sb_publishable_demo',
    );
    connection = SupabaseConnection(config);
    functions = DioClient(config, FakeTokens());
    source = SupabaseClinicalSessionDataSource(functions);
    adapter = FakeHttpAdapter((_) => jsonResponse(200, '{"ok":true}'));
    functions.client.httpClientAdapter = adapter;
  });

  tearDown(() async {
    functions.dispose();
    await connection.dispose();
  });

  test('sends draft saves through the authenticated Edge Function', () async {
    await source.invokeAction({
      'action': 'update_draft_session',
      'sessionId': 'session-1',
      'expectedRevision': 2,
    });

    final request = adapter.requests.single;
    expect(request.uri.path, '/functions/v1/clinical-sessions');
    expect(request.headers['Authorization'], 'Bearer expired');
    expect(request.data, {
      'action': 'update_draft_session',
      'sessionId': 'session-1',
      'expectedRevision': 2,
    });
  });

  test('maps stale saves to a typed revision conflict', () async {
    adapter = FakeHttpAdapter(
      (_) =>
          jsonResponse(409, '{"error":"clinical_session_revision_conflict"}'),
    );
    functions.client.httpClientAdapter = adapter;

    await expectLater(
      source.invokeAction({'action': 'update_draft_session'}),
      throwsA(
        isA<ClinicalSessionOperationException>().having(
          (error) => error.issue,
          'issue',
          ClinicalSessionOperationIssue.revisionConflict,
        ),
      ),
    );
  });
}

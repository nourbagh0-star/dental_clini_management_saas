import 'package:dental_clini_management_saas/core/config/app_config.dart';
import 'package:dental_clini_management_saas/core/network/dio_client.dart';
import 'package:dental_clini_management_saas/core/network/supabase_connection.dart';
import 'package:dental_clini_management_saas/features/staff/data/supabase_staff_data_source.dart';
import 'package:dental_clini_management_saas/features/staff/domain/staff_models.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/fakes.dart';

void main() {
  late SupabaseConnection connection;
  late DioClient functions;
  late SupabaseStaffDataSource source;
  late FakeHttpAdapter adapter;

  setUp(() {
    final config = AppConfig.parse(
      supabaseUrl: 'https://demo.supabase.co',
      publishableKey: 'sb_publishable_demo',
    );
    connection = SupabaseConnection(config);
    functions = DioClient(config, FakeTokens());
    source = SupabaseStaffDataSource(functions);
    adapter = FakeHttpAdapter((_) => jsonResponse(200, '{"ok":true}'));
    functions.client.httpClientAdapter = adapter;
  });

  tearDown(() async {
    functions.dispose();
    await connection.dispose();
  });

  test(
    'sends staff actions through the authenticated Edge Function only',
    () async {
      await source.invokeStaffAction({
        'action': 'revoke',
        'invitationId': 'id',
      });

      final request = adapter.requests.single;
      expect(request.uri.path, '/functions/v1/staff-invitations');
      expect(request.headers['Authorization'], 'Bearer expired');
      expect(request.headers['apikey'], 'sb_publishable_demo');
      expect(request.data, {'action': 'revoke', 'invitationId': 'id'});
    },
  );

  test(
    'maps the safe owner reauthentication code to a typed outcome',
    () async {
      adapter = FakeHttpAdapter(
        (_) => jsonResponse(403, '{"error":"owner_reauthentication_required"}'),
      );
      functions.client.httpClientAdapter = adapter;

      await expectLater(
        source.invokeStaffAction({'action': 'revoke', 'invitationId': 'id'}),
        throwsA(
          isA<StaffOperationException>().having(
            (error) => error.issue,
            'issue',
            StaffOperationIssue.ownerReauthenticationRequired,
          ),
        ),
      );
    },
  );
}

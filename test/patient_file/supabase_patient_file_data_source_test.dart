import 'package:dental_clini_management_saas/core/config/app_config.dart';
import 'package:dental_clini_management_saas/core/network/dio_client.dart';
import 'package:dental_clini_management_saas/core/network/supabase_connection.dart';
import 'package:dental_clini_management_saas/features/patient_file/data/supabase_patient_file_data_source.dart';
import 'package:dental_clini_management_saas/features/patient_file/domain/patient_file_models.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/fakes.dart';

void main() {
  late SupabaseConnection connection;
  late DioClient functions;
  late SupabasePatientFileDataSource source;
  late FakeHttpAdapter adapter;

  setUp(() {
    final config = AppConfig.parse(
      supabaseUrl: 'https://demo.supabase.co',
      publishableKey: 'sb_publishable_demo',
    );
    connection = SupabaseConnection(config);
    functions = DioClient(config, FakeTokens());
    source = SupabasePatientFileDataSource(functions);
    adapter = FakeHttpAdapter((_) => jsonResponse(200, '{"ok":true}'));
    functions.client.httpClientAdapter = adapter;
  });

  tearDown(() async {
    functions.dispose();
    await connection.dispose();
  });

  test(
    'sends archive through the authenticated patient-files function',
    () async {
      await source.invokeAction({
        'action': 'archive_file',
        'fileId': 'file-1',
        'reason': 'Replacement available',
      });

      final request = adapter.requests.single;
      expect(request.uri.path, '/functions/v1/patient-files');
      expect(request.headers['Authorization'], 'Bearer expired');
      expect(request.data, containsPair('fileId', 'file-1'));
    },
  );

  test('maps signature mismatch to a typed operation issue', () async {
    adapter = FakeHttpAdapter(
      (_) => jsonResponse(415, '{"error":"patient_file_signature_mismatch"}'),
    );
    functions.client.httpClientAdapter = adapter;

    await expectLater(
      source.invokeAction({'action': 'complete_upload', 'fileId': 'file-1'}),
      throwsA(
        isA<PatientFileOperationException>().having(
          (error) => error.issue,
          'issue',
          PatientFileOperationIssue.signatureMismatch,
        ),
      ),
    );
  });
}

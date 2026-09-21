import 'dart:typed_data';

import 'package:dental_clini_management_saas/core/config/app_config.dart';
import 'package:dental_clini_management_saas/core/error/app_failure.dart';
import 'package:dental_clini_management_saas/features/patient_file/data/supabase_tus_file_transfer_client.dart';
import 'package:dental_clini_management_saas/features/patient_file/domain/patient_file_models.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/fakes.dart';

void main() {
  late FakeTokens tokens;
  late Dio dio;
  late FakeHttpAdapter adapter;
  late SupabaseTusFileTransferClient client;

  final config = AppConfig.parse(
    supabaseUrl: 'https://demo.supabase.co',
    publishableKey: 'sb_publishable_demo',
  );
  final file = SelectedPatientFile(
    name: 'fictional.pdf',
    extension: 'pdf',
    mimeType: 'application/pdf',
    bytes: Uint8List.fromList([0x25, 0x50, 0x44, 0x46, 0x2d]),
  );
  final target = PatientFileUploadTarget(
    fileId: 'file-1',
    bucket: 'patient-files',
    objectPath: 'clinic/patient/file-1/file.pdf',
    expiresAt: DateTime.utc(2026, 9, 10, 12),
  );

  setUp(() {
    tokens = FakeTokens()..accessToken = 'active';
    dio = Dio();
  });

  tearDown(() => client.dispose());

  test('creates a private TUS upload and reports confirmed progress', () async {
    adapter = FakeHttpAdapter((request) {
      if (request.method == 'POST') {
        return _response(
          201,
          headers: {
            'location': ['/storage/v1/upload/resumable/upload-1'],
          },
        );
      }
      return _response(
        204,
        headers: {
          'upload-offset': [file.sizeBytes.toString()],
        },
      );
    });
    dio.httpClientAdapter = adapter;
    client = SupabaseTusFileTransferClient.testing(config, tokens, dio);
    final progress = <int>[];

    await client.upload(
      target: target,
      file: file,
      onProgress: (sent, _) => progress.add(sent),
    );

    expect(adapter.requests.map((item) => item.method), ['POST', 'PATCH']);
    final create = adapter.requests.first;
    expect(create.uri.host, 'demo.storage.supabase.co');
    expect(create.headers['x-upsert'], 'false');
    expect(create.headers['Upload-Length'], '${file.sizeBytes}');
    expect(create.headers['Upload-Metadata'], contains('bucketName'));
    expect(progress, [file.sizeBytes]);
  });

  test('refreshes once, reads the remote offset, and resumes there', () async {
    var patchCount = 0;
    adapter = FakeHttpAdapter((request) {
      if (request.method == 'POST') {
        return _response(
          201,
          headers: {
            'location': [
              'https://demo.storage.supabase.co/storage/v1/upload/resumable/upload-2',
            ],
          },
        );
      }
      if (request.method == 'HEAD') {
        return _response(
          204,
          headers: {
            'upload-offset': ['2'],
          },
        );
      }
      patchCount++;
      if (patchCount == 1) return _response(401);
      return _response(
        204,
        headers: {
          'upload-offset': [file.sizeBytes.toString()],
        },
      );
    });
    dio.httpClientAdapter = adapter;
    client = SupabaseTusFileTransferClient.testing(config, tokens, dio);

    await client.upload(target: target, file: file, onProgress: (_, _) {});

    expect(tokens.refreshCount, 1);
    expect(adapter.requests.map((item) => item.method), [
      'POST',
      'PATCH',
      'HEAD',
      'PATCH',
    ]);
    expect(adapter.requests.last.headers['Upload-Offset'], '2');
    expect(adapter.requests.last.headers['Authorization'], 'Bearer renewed');
  });

  test('rejects a provider upload location on another origin', () async {
    adapter = FakeHttpAdapter(
      (_) => _response(
        201,
        headers: {
          'location': ['https://outside.example/upload-3'],
        },
      ),
    );
    dio.httpClientAdapter = adapter;
    client = SupabaseTusFileTransferClient.testing(config, tokens, dio);

    await expectLater(
      client.upload(target: target, file: file, onProgress: (_, _) {}),
      throwsA(isA<AuthorizationFailure>()),
    );
    expect(adapter.requests, hasLength(1));
  });
}

ResponseBody _response(
  int status, {
  Map<String, List<String>> headers = const {},
}) => ResponseBody.fromString('', status, headers: headers);

import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:injectable/injectable.dart';

import '../../../core/config/app_config.dart';
import '../../../core/error/app_failure.dart';
import '../../../core/network/session_token_provider.dart';
import '../domain/file_transfer_client.dart';
import '../domain/patient_file_models.dart';

@LazySingleton(as: FileTransferClient)
class SupabaseTusFileTransferClient implements FileTransferClient {
  SupabaseTusFileTransferClient(AppConfig config, this._tokens)
    : _config = config,
      _dio = Dio(
        BaseOptions(
          connectTimeout: const Duration(seconds: 20),
          sendTimeout: kIsWeb ? null : const Duration(minutes: 2),
          receiveTimeout: const Duration(seconds: 30),
          followRedirects: false,
        ),
      ) {
    if (kIsWeb) {
      _dio.interceptors.add(
        InterceptorsWrapper(
          onRequest: (options, handler) {
            if (options.data == null) {
              options.sendTimeout = null;
            }
            handler.next(options);
          },
        ),
      );
    }
  }

  SupabaseTusFileTransferClient.testing(this._config, this._tokens, this._dio);

  static const _chunkSize = 6 * 1024 * 1024;
  final AppConfig _config;
  final SessionTokenProvider _tokens;
  final Dio _dio;
  CancelToken? _cancelToken;

  @override
  Future<void> upload({
    required PatientFileUploadTarget target,
    required SelectedPatientFile file,
    required void Function(int sentBytes, int totalBytes) onProgress,
  }) async {
    final base = _config.supabaseUrl;
    final publicKey = _config.publishableKey;
    var token = _tokens.accessToken;
    if (base == null || publicKey == null) throw const ValidationFailure();
    if (token == null) throw const AuthenticationFailure();
    final endpoint = _endpoint(base);
    final cancel = CancelToken();
    _cancelToken?.cancel();
    _cancelToken = cancel;
    try {
      final metadata =
          {
                'bucketName': target.bucket,
                'objectName': target.objectPath,
                'contentType': file.mimeType,
                'cacheControl': '0',
              }.entries
              .map((entry) {
                final encoded = base64Encode(utf8.encode(entry.value));
                return '${entry.key} $encoded';
              })
              .join(',');
      final created = await _dio.postUri<void>(
        endpoint,
        data: const <int>[],
        cancelToken: cancel,
        options: Options(
          headers: {
            'Authorization': 'Bearer $token',
            'apikey': publicKey,
            'Tus-Resumable': '1.0.0',
            'Upload-Length': file.sizeBytes.toString(),
            'Upload-Metadata': metadata,
            'x-upsert': 'false',
          },
          validateStatus: (status) => status == 201,
        ),
      );
      final rawLocation = created.headers.value('location');
      if (rawLocation == null) throw const ServerFailure();
      final location = endpoint.resolve(rawLocation);
      if (location.origin != endpoint.origin) {
        throw const AuthorizationFailure();
      }
      var offset = 0;
      var refreshAttempted = false;
      while (offset < file.sizeBytes) {
        final end = (offset + _chunkSize).clamp(0, file.sizeBytes);
        final chunk = Uint8List.sublistView(file.bytes, offset, end);
        try {
          final response = await _dio.patchUri<void>(
            location,
            data: chunk,
            cancelToken: cancel,
            options: Options(
              headers: {
                'Authorization': 'Bearer $token',
                'apikey': publicKey,
                'Tus-Resumable': '1.0.0',
                'Upload-Offset': offset.toString(),
                'Content-Type': 'application/offset+octet-stream',
              },
              validateStatus: (status) => status == 204,
            ),
          );
          final next = int.tryParse(
            response.headers.value('upload-offset') ?? '',
          );
          if (next == null || next <= offset || next > file.sizeBytes) {
            throw const ServerFailure();
          }
          offset = next;
          onProgress(offset, file.sizeBytes);
        } on DioException catch (error) {
          if (error.response?.statusCode == 401 && !refreshAttempted) {
            refreshAttempted = true;
            token = await _tokens.refreshAccessToken();
            if (token == null) throw const AuthenticationFailure();
            offset = await _remoteOffset(location, token, publicKey, cancel);
            continue;
          }
          rethrow;
        }
      }
    } on DioException catch (error) {
      if (CancelToken.isCancel(error)) throw const NetworkFailure();
      if (error.response?.statusCode == 401) {
        throw const AuthenticationFailure();
      }
      if (error.response?.statusCode == 403) {
        throw const AuthorizationFailure();
      }
      throw error.response == null
          ? const NetworkFailure()
          : const ServerFailure();
    } finally {
      if (identical(_cancelToken, cancel)) _cancelToken = null;
    }
  }

  Future<int> _remoteOffset(
    Uri location,
    String token,
    String publicKey,
    CancelToken cancel,
  ) async {
    final response = await _dio.headUri<void>(
      location,
      cancelToken: cancel,
      options: Options(
        headers: {
          'Authorization': 'Bearer $token',
          'apikey': publicKey,
          'Tus-Resumable': '1.0.0',
        },
        validateStatus: (status) => status == 200 || status == 204,
      ),
    );
    final offset = int.tryParse(response.headers.value('upload-offset') ?? '');
    if (offset == null || offset < 0) throw const ServerFailure();
    return offset;
  }

  Uri _endpoint(Uri base) {
    final host = base.host;
    if (base.scheme == 'https' && host.endsWith('.supabase.co')) {
      final project = host.substring(0, host.length - '.supabase.co'.length);
      return base.replace(
        host: '$project.storage.supabase.co',
        path: '/storage/v1/upload/resumable',
      );
    }
    return base.replace(path: '/storage/v1/upload/resumable');
  }

  @override
  void cancelActiveUpload() => _cancelToken?.cancel('patient_cancelled');

  @disposeMethod
  @override
  void dispose() => _dio.close(force: true);
}

import 'dart:async';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:dental_clini_management_saas/core/network/session_token_provider.dart';
import 'package:dental_clini_management_saas/core/storage/preferences_store.dart';

class MemoryPreferences implements PreferencesStore {
  String? value;
  bool fail = false;

  @override
  Future<String?> readAppearance() async {
    if (fail) throw StateError('Storage unavailable');
    return value;
  }

  @override
  Future<void> writeAppearance(String next) async {
    if (fail) throw StateError('Storage unavailable');
    value = next;
  }
}

class FakeTokens implements SessionTokenProvider {
  @override
  String? accessToken = 'expired';
  int refreshCount = 0;
  Future<String?> Function()? refresh;

  @override
  Future<String?> refreshAccessToken() async {
    refreshCount++;
    accessToken = await (refresh?.call() ?? Future.value('renewed'));
    return accessToken;
  }
}

class FakeHttpAdapter implements HttpClientAdapter {
  FakeHttpAdapter(this.respond);
  final FutureOr<ResponseBody> Function(RequestOptions) respond;
  final requests = <RequestOptions>[];

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    requests.add(
      options.copyWith(
        headers: Map.of(options.headers),
        extra: Map.of(options.extra),
      ),
    );
    return await respond(options);
  }

  @override
  void close({bool force = false}) {}
}

ResponseBody jsonResponse(int status, [String body = '{}']) =>
    ResponseBody.fromString(
      body,
      status,
      headers: {
        Headers.contentTypeHeader: ['application/json'],
      },
    );

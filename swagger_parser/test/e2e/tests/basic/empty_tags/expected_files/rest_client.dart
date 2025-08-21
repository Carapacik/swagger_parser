// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:dio/dio.dart';

import 'clients/client_client.dart';
import 'clients/test_client.dart';

///  `v0.0.0 (v1)`
class RestClient {
  RestClient(
    Dio dio, {
    String? baseUrl,
  })  : _dio = dio,
        _baseUrl = baseUrl;

  final Dio _dio;
  final String? _baseUrl;

  static String get version => '0.0.0 (v1)';

  ClientClient? _client;
  TestClient? _test;

  ClientClient get client => _client ??= ClientClient(_dio, baseUrl: _baseUrl);

  TestClient get test => _test ??= TestClient(_dio, baseUrl: _baseUrl);
}

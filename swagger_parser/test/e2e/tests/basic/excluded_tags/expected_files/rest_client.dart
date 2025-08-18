// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import

import 'package:dio/dio.dart';

import 'clients/client_client.dart';
import 'clients/default_client.dart';

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
  DefaultClient? _default;

  ClientClient get client => _client ??= ClientClient(_dio, baseUrl: _baseUrl);

  DefaultClient get default => _default ??= DefaultClient(_dio, baseUrl: _baseUrl);
}

// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import

import 'package:dio/dio.dart';

import 'clients/default_client.dart';

/// Swagger Petstore `v1.0.0`
class RestClient {
  RestClient(
    Dio dio, {
    String? baseUrl,
  })  : _dio = dio,
        _baseUrl = baseUrl;

  final Dio _dio;
  final String? _baseUrl;

  static String get version => '1.0.0';

  DefaultClient? _default;

  DefaultClient get default => _default ??= DefaultClient(_dio, baseUrl: _baseUrl);
}

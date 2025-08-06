// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import

import 'package:dio/dio.dart';

import 'clients/myapi_client.dart';

/// My Pl@ntNet API `v2.2.1`.
///
/// API Service for developers.
class RestClient {
  RestClient(
    Dio dio, {
    String? baseUrl,
  })  : _dio = dio,
        _baseUrl = baseUrl;

  final Dio _dio;
  final String? _baseUrl;

  static String get version => '2.2.1';

  MyapiClient? _myapi;

  MyapiClient get myapi => _myapi ??= MyapiClient(_dio, baseUrl: _baseUrl);
}

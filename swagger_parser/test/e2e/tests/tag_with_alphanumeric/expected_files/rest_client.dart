// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:dio/dio.dart';

import 'clients/items_2a3_client.dart';

/// Test API `v1.0.0`
class RestClient {
  RestClient(
    Dio dio, {
    String? baseUrl,
  })  : _dio = dio,
        _baseUrl = baseUrl;

  final Dio _dio;
  final String? _baseUrl;

  static String get version => '1.0.0';

  Items2a3Client? _items2a3;

  Items2a3Client get items2a3 =>
      _items2a3 ??= Items2a3Client(_dio, baseUrl: _baseUrl);
}

// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:dio/dio.dart';

import 'clients/pets_client.dart';
import 'clients/fallback_client.dart';

/// Pet Store API with Excluded Tags `v1.0.0`
class RestClient {
  RestClient(
    Dio dio, {
    String? baseUrl,
  })  : _dio = dio,
        _baseUrl = baseUrl;

  final Dio _dio;
  final String? _baseUrl;

  static String get version => '1.0.0';

  PetsClient? _pets;
  FallbackClient? _fallback;

  PetsClient get pets => _pets ??= PetsClient(_dio, baseUrl: _baseUrl);

  FallbackClient get fallback =>
      _fallback ??= FallbackClient(_dio, baseUrl: _baseUrl);
}

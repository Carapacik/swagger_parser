// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:dio/dio.dart';

import 'clients/pet_client.dart';

/// OpenAPI Petstore `v1.0.0`.
///
/// This is a sample server Petstore server. For this sample, you can use the api key `special-key` to test the authorization filters.
class RestClient {
  RestClient(
    Dio dio, {
    String? baseUrl,
  })  : _dio = dio,
        _baseUrl = baseUrl;

  final Dio _dio;
  final String? _baseUrl;

  static String get version => '1.0.0';

  PetClient? _pet;

  PetClient get pet => _pet ??= PetClient(_dio, baseUrl: _baseUrl);
}

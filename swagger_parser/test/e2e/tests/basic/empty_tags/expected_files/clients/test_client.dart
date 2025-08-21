// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:dio/dio.dart';
import 'package:retrofit/retrofit.dart';

part 'test_client.g.dart';

@RestApi()
abstract class TestClient {
  factory TestClient(Dio dio, {String? baseUrl}) = _TestClient;

  @GET('/api/v1/no-tags/')
  Future<void> apiV1CategoryList();
}

// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:dio/dio.dart';
import 'package:retrofit/retrofit.dart';

part 'fallback_client.g.dart';

@RestApi()
abstract class FallbackClient {
  factory FallbackClient(Dio dio, {String? baseUrl}) = _FallbackClient;

  @GET('/api/v1/untagged-should-go-to-default-client/')
  Future<void> apiV1CategoryList();

  @GET('/api/v1/tagged-as-client-should-not-be-lost/')
  Future<void> apiV1CategoryList();
}

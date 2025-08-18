// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import

import 'package:dio/dio.dart';
import 'package:retrofit/retrofit.dart';

import '../models/get_api_v1_empty_tags_endpoint_response.dart';
import '../models/get_api_v1_no_tags_endpoint_response.dart';

part 'fallback_client.g.dart';

@RestApi()
abstract class FallbackClient {
  factory FallbackClient(Dio dio, {String? baseUrl}) = _FallbackClient;

  @GET('/api/v1/no-tags-endpoint')
  Future<GetApiV1NoTagsEndpointResponse> apiV1NoTags();

  @GET('/api/v1/empty-tags-endpoint')
  Future<GetApiV1EmptyTagsEndpointResponse> apiV1EmptyTags();
}

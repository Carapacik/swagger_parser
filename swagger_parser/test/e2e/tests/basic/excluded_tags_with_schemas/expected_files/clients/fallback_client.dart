// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:dio/dio.dart';
import 'package:retrofit/retrofit.dart';

import '../models/get_api_v1_empty_tags_response.dart';
import '../models/get_api_v1_no_tags_response.dart';

part 'fallback_client.g.dart';

@RestApi()
abstract class FallbackClient {
  factory FallbackClient(Dio dio, {String? baseUrl}) = _FallbackClient;

  @GET('/api/v1/no-tags')
  Future<GetApiV1NoTagsResponse> getNoTags();

  @GET('/api/v1/empty-tags')
  Future<GetApiV1EmptyTagsResponse> getEmptyTags();
}

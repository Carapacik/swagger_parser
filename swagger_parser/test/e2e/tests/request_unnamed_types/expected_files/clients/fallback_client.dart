// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:dio/dio.dart';
import 'package:retrofit/retrofit.dart';

import '../models/get_test2_response.dart';
import '../models/test1_request_body.dart';
import '../models/test2_request_body.dart';

part 'fallback_client.g.dart';

@RestApi()
abstract class FallbackClient {
  factory FallbackClient(Dio dio, {String? baseUrl}) = _FallbackClient;

  @POST('/test1')
  Future<dynamic> test({
    @Body() required Test1RequestBody body,
  });

  @GET('/test2')
  Future<GetTest2Response> test({
    @Body() Test2RequestBody? body,
  });
}

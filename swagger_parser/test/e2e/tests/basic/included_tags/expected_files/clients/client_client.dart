// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:dio/dio.dart';
import 'package:retrofit/retrofit.dart';

import '../models/api_v1_tagged_as_include_should_be_included_request_body.dart';
import '../models/get_api_v1_tagged_as_include_should_be_included_response.dart';

part 'client_client.g.dart';

@RestApi()
abstract class ClientClient {
  factory ClientClient(Dio dio, {String? baseUrl}) = _ClientClient;

  @GET('/api/v1/tagged-as-include-should-be-included/')
  Future<GetApiV1TaggedAsIncludeShouldBeIncludedResponse> apiV1CategoryList({
    @Body() required ApiV1TaggedAsIncludeShouldBeIncludedRequestBody body,
  });
}

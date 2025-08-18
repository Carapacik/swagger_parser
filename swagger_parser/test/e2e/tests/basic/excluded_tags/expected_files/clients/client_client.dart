// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import

import 'package:dio/dio.dart';
import 'package:retrofit/retrofit.dart';

import '../models/get_api_v1_not_tagged_should_be_included_response.dart';
import '../models/object0.dart';

part 'client_client.g.dart';

@RestApi()
abstract class ClientClient {
  factory ClientClient(Dio dio, {String? baseUrl}) = _ClientClient;

  /// [body] - Name not received and was auto-generated.
  @GET('/api/v1/not-tagged-should-be-included/')
  Future<GetApiV1NotTaggedShouldBeIncludedResponse> apiV1CategoryList({
    @Body() required Object0 body,
  });
}

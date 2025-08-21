// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:dio/dio.dart';
import 'package:retrofit/retrofit.dart';

import '../models/get_api_v1_tagged_as_exclude_but_included_should_be_included_response.dart';
import '../models/object0.dart';

part 'client_client.g.dart';

@RestApi()
abstract class ClientClient {
  factory ClientClient(Dio dio, {String? baseUrl}) = _ClientClient;

  /// [body] - Name not received and was auto-generated.
  @GET('/api/v1/tagged-as-exclude-but-included-should-be-included/')
  Future<GetApiV1TaggedAsExcludeButIncludedShouldBeIncludedResponse>
      apiV1CategoryList({
    @Body() required Object0 body,
  });
}

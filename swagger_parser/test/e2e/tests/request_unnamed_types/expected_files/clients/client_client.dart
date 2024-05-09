// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import

import 'package:dio/dio.dart';
import 'package:retrofit/retrofit.dart';

import '../models/get_test2_response.dart';
import '../models/object0.dart';
import '../models/object1.dart';

part 'client_client.g.dart';

@RestApi()
abstract class ClientClient {
  factory ClientClient(Dio dio, {String? baseUrl}) = _ClientClient;

  /// [body] - Name not received and was auto-generated.
  @POST('/test1')
  Future<dynamic> test({
    @Body() required Object0 body,
  });

  /// [body] - Name not received and was auto-generated.
  @GET('/test2')
  Future<GetTest2Response> test({
    @Body() Object1? body,
  });
}

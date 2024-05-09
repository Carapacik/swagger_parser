// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import

import 'package:dio/dio.dart';
import 'package:retrofit/retrofit.dart';

import '../models/get_test_response.dart';
import '../models/object0.dart';

part 'client_client.g.dart';

@RestApi()
abstract class ClientClient {
  factory ClientClient(Dio dio, {String? baseUrl}) = _ClientClient;

  /// [body] - Name not received and was auto-generated.
  @GET('/test')
  Future<GetTestResponse> test({
    @Body() Object0? body,
  });
}

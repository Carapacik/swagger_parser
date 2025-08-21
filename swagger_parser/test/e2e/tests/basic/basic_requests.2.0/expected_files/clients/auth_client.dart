// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:dio/dio.dart' hide Headers;
import 'package:retrofit/retrofit.dart';

import '../models/register_user_dto.dart';

part 'auth_client.g.dart';

@RestApi()
abstract class AuthClient {
  factory AuthClient(Dio dio, {String? baseUrl}) = _AuthClient;

  @Headers(<String, String>{'Content-Type': 'text/json'})
  @POST('/api/Auth/register')
  Future<String> postApiAuthRegister({
    @Body() RegisterUserDto? body,
  });
}

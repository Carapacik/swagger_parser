// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart' show compute;
import 'package:retrofit/retrofit.dart';

import '../models/user_dto.dart';

part 'user_client.g.dart';

@RestApi(parser: Parser.FlutterCompute)
abstract class UserClient {
  factory UserClient(Dio dio, {String? baseUrl}) = _UserClient;

  @GET('/users')
  Future<List<UserDto>> getUsers();
}

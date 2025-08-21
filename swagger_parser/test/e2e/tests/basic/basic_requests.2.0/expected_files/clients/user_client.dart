// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'dart:convert';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:retrofit/retrofit.dart';

import '../models/user_info_dto.dart';

part 'user_client.g.dart';

@RestApi()
abstract class UserClient {
  factory UserClient(Dio dio, {String? baseUrl}) = _UserClient;

  /// [tags] - tags to filter by.
  ///
  /// [limit] - maximum number of results to return.
  @GET('/api/User/info')
  Future<UserInfoDto> getApiUserInfo({
    @Query('tags') List<String>? tags,
    @Query('limit') int? limit,
  });

  @MultiPart()
  @PATCH('/api/User/{id}/avatar')
  Future<void> patchApiUserIdAvatar({
    @Part(name: 'avatar') File? avatar,
    @Path('id') int? id,
  });
}

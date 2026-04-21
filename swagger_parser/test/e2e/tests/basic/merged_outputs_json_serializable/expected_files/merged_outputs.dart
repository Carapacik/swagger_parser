// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'dart:convert';
import 'dart:io';

import 'package:dio/dio.dart' hide Headers;
import 'package:dio/dio.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:retrofit/retrofit.dart';

part 'merged_outputs.g.dart';

@RestApi()
abstract class AuthClient {
  factory AuthClient(Dio dio, {String? baseUrl}) = _AuthClient;

  @Headers(<String, String>{'Content-Type': 'text/json'})
  @POST('/api/Auth/register')
  Future<String> postApiAuthRegister({
    @Body() RegisterUserDto? body,
  });
}

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

@JsonSerializable()
class RegisterUserDto {
  const RegisterUserDto({
    required this.email,
    required this.name,
    required this.password,
  });

  factory RegisterUserDto.fromJson(Map<String, Object?> json) =>
      _$RegisterUserDtoFromJson(json);

  final String email;
  final String name;
  final String password;

  Map<String, Object?> toJson() => _$RegisterUserDtoToJson(this);
}

@JsonSerializable()
class UserInfoDto {
  const UserInfoDto({
    required this.email,
    required this.name,
    required this.phone,
  });

  factory UserInfoDto.fromJson(Map<String, Object?> json) =>
      _$UserInfoDtoFromJson(json);

  final String email;
  final String name;
  final String phone;

  Map<String, Object?> toJson() => _$UserInfoDtoToJson(this);
}

class RestClient {
  RestClient(
    Dio dio, {
    String? baseUrl,
  })  : _dio = dio,
        _baseUrl = baseUrl;

  final Dio _dio;
  final String? _baseUrl;

  static String get version => '';

  AuthClient? _auth;
  UserClient? _user;

  AuthClient get auth => _auth ??= AuthClient(_dio, baseUrl: _baseUrl);

  UserClient get user => _user ??= UserClient(_dio, baseUrl: _baseUrl);
}

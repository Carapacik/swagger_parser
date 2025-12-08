// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'dart:async';

import 'package:freezed_annotation/freezed_annotation.dart';

part 'user_dto.freezed.dart';
part 'user_dto.g.dart';

@Freezed()
class UserDto with _$UserDto {
  const factory UserDto({
    required int id,
    required String name,
    required String email,
  }) = _UserDto;

  factory UserDto.fromJson(Map<String, Object?> json) =>
      _$UserDtoFromJson(json);
}

// Flutter compute serialization functions for UserDto
FutureOr<UserDto> deserializeUserDto(Map<String, dynamic> json) =>
    UserDto.fromJson(json);

FutureOr<List<UserDto>> deserializeUserDtoList(
        List<Map<String, dynamic>> json) =>
    json.map((e) => UserDto.fromJson(e)).toList();

FutureOr<Map<String, dynamic>> serializeUserDto(UserDto? object) =>
    object?.toJson() ?? <String, dynamic>{};

FutureOr<List<Map<String, dynamic>>> serializeUserDtoList(
        List<UserDto>? objects) =>
    objects?.map((e) => e.toJson()).toList() ?? [];

// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:freezed_annotation/freezed_annotation.dart';

import 'user_dto.dart';

part 'nullable_user_dto.freezed.dart';
part 'nullable_user_dto.g.dart';

@Freezed()
class NullableUserDto with _$NullableUserDto {
  const factory NullableUserDto({
    required UserDto? data,
  }) = _NullableUserDto;

  factory NullableUserDto.fromJson(Map<String, Object?> json) =>
      _$NullableUserDtoFromJson(json);
}

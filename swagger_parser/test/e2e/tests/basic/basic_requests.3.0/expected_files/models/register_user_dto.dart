// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:freezed_annotation/freezed_annotation.dart';

part 'register_user_dto.freezed.dart';
part 'register_user_dto.g.dart';

@Freezed()
class RegisterUserDto with _$RegisterUserDto {
  const factory RegisterUserDto({
    required String email,
    required String name,
    required String password,
  }) = _RegisterUserDto;

  factory RegisterUserDto.fromJson(Map<String, Object?> json) =>
      _$RegisterUserDtoFromJson(json);
}

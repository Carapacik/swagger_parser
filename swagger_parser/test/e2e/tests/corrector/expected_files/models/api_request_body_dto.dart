// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:freezed_annotation/freezed_annotation.dart';

import 'p1_class_dto.dart';
import 'p2_enum_dto.dart';

part 'api_request_body_dto.freezed.dart';
part 'api_request_body_dto.g.dart';

@Freezed()
class ApiRequestBodyDto with _$ApiRequestBodyDto {
  const factory ApiRequestBodyDto({
    @JsonKey(name: 'p1_class') required P1ClassDto p1Class,
    @JsonKey(includeIfNull: false, name: 'p2_enum') P2EnumDto? p2Enum,
  }) = _ApiRequestBodyDto;

  factory ApiRequestBodyDto.fromJson(Map<String, Object?> json) =>
      _$ApiRequestBodyDtoFromJson(json);
}

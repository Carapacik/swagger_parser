// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:freezed_annotation/freezed_annotation.dart';

import 'p1_class_dto.dart';
import 'p2_enum_dto.dart';

part 'object1_dto.freezed.dart';
part 'object1_dto.g.dart';

@Freezed()
class Object1Dto with _$Object1Dto {
  const factory Object1Dto({
    @JsonKey(name: 'p1_class') required P1ClassDto p1Class,
    @JsonKey(includeIfNull: false, name: 'p2_enum') P2EnumDto? p2Enum,
  }) = _Object1Dto;

  factory Object1Dto.fromJson(Map<String, Object?> json) =>
      _$Object1DtoFromJson(json);
}

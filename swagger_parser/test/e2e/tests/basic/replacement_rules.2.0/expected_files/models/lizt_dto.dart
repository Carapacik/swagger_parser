// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

part 'lizt_dto.g.dart';

@JsonSerializable()
class LiztDto {
  const LiztDto({
    required this.message,
  });

  factory LiztDto.fromJson(Map<String, Object?> json) =>
      _$LiztDtoFromJson(json);

  final String message;

  Map<String, Object?> toJson() => _$LiztDtoToJson(this);
}

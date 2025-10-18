// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

import 'new_pet_dto_action_dto.dart';

part 'pet_dto.g.dart';

@JsonSerializable()
class PetDto {
  const PetDto({
    required this.name,
    required this.id,
    this.tag,
    this.action,
  });

  factory PetDto.fromJson(Map<String, Object?> json) => _$PetDtoFromJson(json);

  final String name;
  @JsonKey(includeIfNull: false)
  final String? tag;
  @JsonKey(includeIfNull: false)
  final NewPetDtoActionDto? action;
  final int id;

  Map<String, Object?> toJson() => _$PetDtoToJson(this);
}

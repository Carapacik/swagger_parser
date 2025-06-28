// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

import 'new_pet_dto_action_dto.dart';

part 'new_pet_dto.g.dart';

@JsonSerializable()
class NewPetDto {
  const NewPetDto({
    required this.name,
    this.tag,
    this.action,
  });

  factory NewPetDto.fromJson(Map<String, Object?> json) =>
      _$NewPetDtoFromJson(json);

  final String name;
  @JsonKey(includeIfNull: false)
  final String? tag;
  @JsonKey(includeIfNull: false)
  final NewPetDtoActionDto? action;

  Map<String, Object?> toJson() => _$NewPetDtoToJson(this);
}

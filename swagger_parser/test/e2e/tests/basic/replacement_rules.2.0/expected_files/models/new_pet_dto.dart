// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import

import 'package:json_annotation/json_annotation.dart';

import 'new_pet_dto_action_dto.dart';

part 'new_pet_dto.g.dart';

@JsonSerializable()
class NewPetDto {
  const NewPetDto({
    required this.name,
    required this.tag,
    required this.action,
  });

  factory NewPetDto.fromJson(Map<String, Object?> json) =>
      _$NewPetDtoFromJson(json);

  final String name;
  final String tag;
  final NewPetDtoActionDto action;

  Map<String, Object?> toJson() => _$NewPetDtoToJson(this);
}

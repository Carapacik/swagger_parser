// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

import 'dog_type.dart';

part 'dog.g.dart';

@JsonSerializable()
class Dog {
  const Dog({
    required this.type,
    required this.barkSound,
  });

  factory Dog.fromJson(Map<String, Object?> json) => _$DogFromJson(json);

  final DogType type;

  /// The sound of the dog's bark.
  final String barkSound;

  Map<String, Object?> toJson() => _$DogToJson(this);
}

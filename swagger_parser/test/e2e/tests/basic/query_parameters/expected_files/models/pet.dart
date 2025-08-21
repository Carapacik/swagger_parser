// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:freezed_annotation/freezed_annotation.dart';

part 'pet.freezed.dart';
part 'pet.g.dart';

@Freezed()
class Pet with _$Pet {
  const factory Pet({
    required int id,
  }) = _Pet;

  factory Pet.fromJson(Map<String, Object?> json) => _$PetFromJson(json);
}

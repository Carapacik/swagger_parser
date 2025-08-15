// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import

import 'package:freezed_annotation/freezed_annotation.dart';

import 'category.dart';
import 'pet_status.dart';

part 'pet.freezed.dart';
part 'pet.g.dart';

@Freezed()
class Pet with _$Pet {
  const factory Pet({
    int? id,
    String? name,
    PetStatus? status,
    Category? category,
  }) = _Pet;

  factory Pet.fromJson(Map<String, Object?> json) => _$PetFromJson(json);
}

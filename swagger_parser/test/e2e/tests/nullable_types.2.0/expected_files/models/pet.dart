// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:freezed_annotation/freezed_annotation.dart';

import 'category.dart';
import 'pet_status.dart';
import 'tag.dart';

part 'pet.freezed.dart';
part 'pet.g.dart';

/// A pet for sale in the pet store
@Freezed()
class Pet with _$Pet {
  const factory Pet({
    required String name,
    required List<String> photoUrls,
    @JsonKey(includeIfNull: false) int? id,
    @JsonKey(includeIfNull: false) Category? category,
    @JsonKey(includeIfNull: false) List<Tag>? tags,

    /// pet status in the store
    @JsonKey(includeIfNull: false) PetStatus? status,
  }) = _Pet;

  factory Pet.fromJson(Map<String, Object?> json) => _$PetFromJson(json);
}

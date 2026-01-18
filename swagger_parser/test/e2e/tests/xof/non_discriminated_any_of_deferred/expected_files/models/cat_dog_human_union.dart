// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:json_annotation/json_annotation.dart';

part 'cat_dog_human_union.freezed.dart';
part 'cat_dog_human_union.g.dart';

@Freezed()
sealed class CatDogHumanUnion with _$CatDogHumanUnion {
  @JsonSerializable()
  const factory CatDogHumanUnion.cat({
    /// Number of times the cat meows.
    required int mewCount,
  }) = CatDogHumanUnionCat;

  @JsonSerializable()
  const factory CatDogHumanUnion.dog({
    /// The sound of the dog's bark.
    required String barkSound,
  }) = CatDogHumanUnionDog;

  @JsonSerializable()
  const factory CatDogHumanUnion.human({
    /// The job of the human.
    required String job,
  }) = CatDogHumanUnionHuman;

  factory CatDogHumanUnion.fromJson(Map<String, Object?> json) =>
      // TODO: No discriminator in OpenAPI spec - you must implement this manually.
      //
      // Inspect the JSON and return the matching variant. Each variant has a fromJson:
      //   CatDogHumanUnionVariantName.fromJson(json)
      //
      // Example pattern (check for unique fields):
      //   json.containsKey('uniqueFieldA') ? CatDogHumanUnionTypeA.fromJson(json) :
      //   json.containsKey('uniqueFieldB') ? CatDogHumanUnionTypeB.fromJson(json) :
      //   CatDogHumanUnionDefault.fromJson(json);
      //
      // IMPORTANT: Keep the => arrow syntax. Converting to a { } body will cause
      // freezed to skip generating toJson/fromJson for this class.
      throw UnimplementedError();
}

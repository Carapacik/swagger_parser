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
      // TODO: Deserialization must be implemented by the user, because the OpenAPI specification did not provide a discriminator.
      // Use _$$CatDogHumanUnion<UnionName>ImplFromJson(json) to deserialize the union <UnionName>.
      throw UnimplementedError();

  Map<String, Object?> toJson() => switch (this) {
        CatDogHumanUnionCat() => _$$CatDogHumanUnionCatImplToJson(this),
        CatDogHumanUnionDog() => _$$CatDogHumanUnionDogImplToJson(this),
        CatDogHumanUnionHuman() => _$$CatDogHumanUnionHumanImplToJson(this),
      };
}

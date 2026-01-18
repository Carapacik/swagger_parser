// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:json_annotation/json_annotation.dart';

part 'family_members_union.freezed.dart';
part 'family_members_union.g.dart';

@Freezed()
sealed class FamilyMembersUnion with _$FamilyMembersUnion {
  @JsonSerializable()
  const factory FamilyMembersUnion.cat({
    /// Number of times the cat meows.
    required int mewCount,
  }) = FamilyMembersUnionCat;

  @JsonSerializable()
  const factory FamilyMembersUnion.dog({
    /// The sound of the dog's bark.
    required String barkSound,
  }) = FamilyMembersUnionDog;

  @JsonSerializable()
  const factory FamilyMembersUnion.human({
    /// The job of the human.
    required String job,
  }) = FamilyMembersUnionHuman;

  factory FamilyMembersUnion.fromJson(Map<String, Object?> json) =>
      // TODO: No discriminator in OpenAPI spec - you must implement this manually.
      //
      // Inspect the JSON and return the matching variant. Each variant has a fromJson:
      //   FamilyMembersUnionVariantName.fromJson(json)
      //
      // Example pattern (check for unique fields):
      //   json.containsKey('uniqueFieldA') ? FamilyMembersUnionTypeA.fromJson(json) :
      //   json.containsKey('uniqueFieldB') ? FamilyMembersUnionTypeB.fromJson(json) :
      //   FamilyMembersUnionDefault.fromJson(json);
      //
      // IMPORTANT: Keep the => arrow syntax. Converting to a { } body will cause
      // freezed to skip generating toJson/fromJson for this class.
      throw UnimplementedError();
}

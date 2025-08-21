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
      // TODO: Deserialization must be implemented by the user, because the OpenAPI specification did not provide a discriminator.
      // Use _$$FamilyMembersUnion<UnionName>ImplFromJson(json) to deserialize the union <UnionName>.
      throw UnimplementedError();

  Map<String, Object?> toJson() => switch (this) {
        FamilyMembersUnionCat() => _$$FamilyMembersUnionCatImplToJson(this),
        FamilyMembersUnionDog() => _$$FamilyMembersUnionDogImplToJson(this),
        FamilyMembersUnionHuman() => _$$FamilyMembersUnionHumanImplToJson(this),
      };
}

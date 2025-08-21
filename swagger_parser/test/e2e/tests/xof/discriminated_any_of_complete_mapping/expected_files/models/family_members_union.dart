// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:freezed_annotation/freezed_annotation.dart';

import 'cat.dart';
import 'cat_type.dart';
import 'dog.dart';
import 'dog_type.dart';
import 'human.dart';
import 'human_type.dart';

part 'family_members_union.freezed.dart';
part 'family_members_union.g.dart';

@Freezed(unionKey: 'type')
sealed class FamilyMembersUnion with _$FamilyMembersUnion {
  @FreezedUnionValue('Cat')
  const factory FamilyMembersUnion.cat({
    required CatType type,

    /// Number of times the cat meows.
    required int mewCount,
  }) = FamilyMembersUnionCat;

  @FreezedUnionValue('Dog')
  const factory FamilyMembersUnion.dog({
    required DogType type,

    /// The sound of the dog's bark.
    required String barkSound,
  }) = FamilyMembersUnionDog;

  @FreezedUnionValue('Human')
  const factory FamilyMembersUnion.human({
    required HumanType type,

    /// The job of the human.
    required String job,
  }) = FamilyMembersUnionHuman;

  factory FamilyMembersUnion.fromJson(Map<String, Object?> json) =>
      _$FamilyMembersUnionFromJson(json);
}

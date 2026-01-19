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

part 'get_family_members_response_union.freezed.dart';
part 'get_family_members_response_union.g.dart';

@Freezed(unionKey: 'type')
sealed class GetFamilyMembersResponseUnion
    with _$GetFamilyMembersResponseUnion {
  @FreezedUnionValue('Cat')
  const factory GetFamilyMembersResponseUnion.cat({
    required CatType type,

    /// Number of times the cat meows.
    required int mewCount,
  }) = GetFamilyMembersResponseUnionCat;

  @FreezedUnionValue('Dog')
  const factory GetFamilyMembersResponseUnion.dog({
    required DogType type,

    /// The sound of the dog's bark.
    required String barkSound,
  }) = GetFamilyMembersResponseUnionDog;

  @FreezedUnionValue('Human')
  const factory GetFamilyMembersResponseUnion.human({
    required HumanType type,

    /// The job of the human.
    required String job,
  }) = GetFamilyMembersResponseUnionHuman;

  factory GetFamilyMembersResponseUnion.fromJson(Map<String, Object?> json) =>
      _$GetFamilyMembersResponseUnionFromJson(json);
}

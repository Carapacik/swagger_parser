// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

import 'cat.dart';
import 'dog.dart';
import 'human.dart';

part 'family_members_union.g.dart';

@JsonSerializable(createFactory: false)
sealed class FamilyMembersUnion {
  const FamilyMembersUnion();

  factory FamilyMembersUnion.fromJson(Map<String, dynamic> json) =>
      _FamilyMembersUnionHelper._tryDeserialize(json);

  Map<String, dynamic> toJson();
}

class _FamilyMembersUnionHelper {
  static FamilyMembersUnion _tryDeserialize(Map<String, dynamic> json) {
    try {
      return FamilyMembersUnionCat.fromJson(json);
    } catch (_) {}
    try {
      return FamilyMembersUnionDog.fromJson(json);
    } catch (_) {}
    try {
      return FamilyMembersUnionHuman.fromJson(json);
    } catch (_) {}

    throw FormatException(
        'Could not determine the correct type for FamilyMembersUnion from: $json');
  }
}

@JsonSerializable()
class FamilyMembersUnionCat extends FamilyMembersUnion implements Cat {
  @override
  final int mewCount;

  const FamilyMembersUnionCat({
    required this.mewCount,
  });

  factory FamilyMembersUnionCat.fromJson(Map<String, dynamic> json) =>
      _$FamilyMembersUnionCatFromJson(json);

  @override
  Map<String, dynamic> toJson() => _$FamilyMembersUnionCatToJson(this);
}

@JsonSerializable()
class FamilyMembersUnionDog extends FamilyMembersUnion implements Dog {
  @override
  final String barkSound;

  const FamilyMembersUnionDog({
    required this.barkSound,
  });

  factory FamilyMembersUnionDog.fromJson(Map<String, dynamic> json) =>
      _$FamilyMembersUnionDogFromJson(json);

  @override
  Map<String, dynamic> toJson() => _$FamilyMembersUnionDogToJson(this);
}

@JsonSerializable()
class FamilyMembersUnionHuman extends FamilyMembersUnion implements Human {
  @override
  final String job;

  const FamilyMembersUnionHuman({
    required this.job,
  });

  factory FamilyMembersUnionHuman.fromJson(Map<String, dynamic> json) =>
      _$FamilyMembersUnionHumanFromJson(json);

  @override
  Map<String, dynamic> toJson() => _$FamilyMembersUnionHumanToJson(this);
}

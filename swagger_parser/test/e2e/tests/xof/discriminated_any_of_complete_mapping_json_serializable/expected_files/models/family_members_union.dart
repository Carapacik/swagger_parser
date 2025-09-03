// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

import 'cat.dart';
import 'cat_type.dart';
import 'dog.dart';
import 'dog_type.dart';
import 'human.dart';
import 'human_type.dart';

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
    if (json['type'] == 'Cat') {
      return FamilyMembersUnionCat.fromJson(json);
    } else if (json['type'] == 'Dog') {
      return FamilyMembersUnionDog.fromJson(json);
    } else if (json['type'] == 'Human') {
      return FamilyMembersUnionHuman.fromJson(json);
    } else {
      throw FormatException(
          'Unknown discriminator value "${json['type']}" for FamilyMembersUnion');
    }
  }
}

@JsonSerializable()
class FamilyMembersUnionCat extends FamilyMembersUnion implements Cat {
  @override
  final CatType type;
  @override
  final int mewCount;

  const FamilyMembersUnionCat({
    required this.type,
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
  final DogType type;
  @override
  final String barkSound;

  const FamilyMembersUnionDog({
    required this.type,
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
  final HumanType type;
  @override
  final String job;

  const FamilyMembersUnionHuman({
    required this.type,
    required this.job,
  });

  factory FamilyMembersUnionHuman.fromJson(Map<String, dynamic> json) =>
      _$FamilyMembersUnionHumanFromJson(json);

  @override
  Map<String, dynamic> toJson() => _$FamilyMembersUnionHumanToJson(this);
}

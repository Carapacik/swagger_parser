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
      FamilyMembersUnionUnionDeserializer.tryDeserialize(json);

  Map<String, dynamic> toJson();
}

extension FamilyMembersUnionUnionDeserializer on FamilyMembersUnion {
  static FamilyMembersUnion tryDeserialize(
    Map<String, dynamic> json, {
    String key = 'type',
    Map<Type, Object?>? mapping,
  }) {
    final mappingFallback = const <Type, Object?>{
      FamilyMembersUnionCat: 'Cat',
      FamilyMembersUnionDog: 'Dog',
      FamilyMembersUnionHuman: 'Human',
    };
    final value = json[key];
    final effective = mapping ?? mappingFallback;
    return switch (value) {
      effective[FamilyMembersUnionCat] => FamilyMembersUnionCat.fromJson(json),
      effective[FamilyMembersUnionDog] => FamilyMembersUnionDog.fromJson(json),
      effective[FamilyMembersUnionHuman] =>
        FamilyMembersUnionHuman.fromJson(json),
      _ => throw FormatException(
          'Unknown discriminator value "${json[key]}" for FamilyMembersUnion'),
    };
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

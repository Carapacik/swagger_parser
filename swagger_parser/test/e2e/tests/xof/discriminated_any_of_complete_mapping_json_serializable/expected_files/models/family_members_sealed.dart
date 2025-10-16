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

part 'family_members_sealed.g.dart';

@JsonSerializable(createFactory: false)
sealed class FamilyMembersSealed {
  const FamilyMembersSealed();

  factory FamilyMembersSealed.fromJson(Map<String, dynamic> json) =>
      FamilyMembersSealedDeserializer.tryDeserialize(json);

  Map<String, dynamic> toJson();
}

extension FamilyMembersSealedDeserializer on FamilyMembersSealed {
  static FamilyMembersSealed tryDeserialize(
    Map<String, dynamic> json, {
    String key = 'type',
    Map<Type, Object?>? mapping,
  }) {
    final mappingFallback = const <Type, Object?>{
      FamilyMembersSealedCat: 'Cat',
      FamilyMembersSealedDog: 'Dog',
      FamilyMembersSealedHuman: 'Human',
    };
    final value = json[key];
    final effective = mapping ?? mappingFallback;
    return switch (value) {
      _ when value == effective[FamilyMembersSealedCat] =>
        FamilyMembersSealedCat.fromJson(json),
      _ when value == effective[FamilyMembersSealedDog] =>
        FamilyMembersSealedDog.fromJson(json),
      _ when value == effective[FamilyMembersSealedHuman] =>
        FamilyMembersSealedHuman.fromJson(json),
      _ => throw FormatException(
          'Unknown discriminator value "${json[key]}" for FamilyMembersSealed'),
    };
  }
}

@JsonSerializable()
class FamilyMembersSealedCat extends FamilyMembersSealed implements Cat {
  @override
  final CatType type;
  @override
  final int mewCount;

  const FamilyMembersSealedCat({
    required this.type,
    required this.mewCount,
  });

  factory FamilyMembersSealedCat.fromJson(Map<String, dynamic> json) =>
      _$FamilyMembersSealedCatFromJson(json);

  @override
  Map<String, dynamic> toJson() => _$FamilyMembersSealedCatToJson(this);
}

@JsonSerializable()
class FamilyMembersSealedDog extends FamilyMembersSealed implements Dog {
  @override
  final DogType type;
  @override
  final String barkSound;

  const FamilyMembersSealedDog({
    required this.type,
    required this.barkSound,
  });

  factory FamilyMembersSealedDog.fromJson(Map<String, dynamic> json) =>
      _$FamilyMembersSealedDogFromJson(json);

  @override
  Map<String, dynamic> toJson() => _$FamilyMembersSealedDogToJson(this);
}

@JsonSerializable()
class FamilyMembersSealedHuman extends FamilyMembersSealed implements Human {
  @override
  final HumanType type;
  @override
  final String job;

  const FamilyMembersSealedHuman({
    required this.type,
    required this.job,
  });

  factory FamilyMembersSealedHuman.fromJson(Map<String, dynamic> json) =>
      _$FamilyMembersSealedHumanFromJson(json);

  @override
  Map<String, dynamic> toJson() => _$FamilyMembersSealedHumanToJson(this);
}

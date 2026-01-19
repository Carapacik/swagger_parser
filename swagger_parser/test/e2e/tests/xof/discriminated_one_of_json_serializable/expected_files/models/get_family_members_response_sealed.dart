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

part 'get_family_members_response_sealed.g.dart';

@JsonSerializable(createFactory: false)
sealed class GetFamilyMembersResponseSealed {
  const GetFamilyMembersResponseSealed();

  factory GetFamilyMembersResponseSealed.fromJson(Map<String, dynamic> json) =>
      GetFamilyMembersResponseSealedDeserializer.tryDeserialize(json);

  Map<String, dynamic> toJson();
}

extension GetFamilyMembersResponseSealedDeserializer
    on GetFamilyMembersResponseSealed {
  static GetFamilyMembersResponseSealed tryDeserialize(
    Map<String, dynamic> json, {
    String key = 'type',
    Map<Type, Object?>? mapping,
  }) {
    final mappingFallback = const <Type, Object?>{
      GetFamilyMembersResponseSealedCat: 'Cat',
      GetFamilyMembersResponseSealedDog: 'Dog',
      GetFamilyMembersResponseSealedHuman: 'Human',
    };
    final value = json[key];
    final effective = mapping ?? mappingFallback;
    return switch (value) {
      _ when value == effective[GetFamilyMembersResponseSealedCat] =>
        GetFamilyMembersResponseSealedCat.fromJson(json),
      _ when value == effective[GetFamilyMembersResponseSealedDog] =>
        GetFamilyMembersResponseSealedDog.fromJson(json),
      _ when value == effective[GetFamilyMembersResponseSealedHuman] =>
        GetFamilyMembersResponseSealedHuman.fromJson(json),
      _ => throw FormatException(
          'Unknown discriminator value "${json[key]}" for GetFamilyMembersResponseSealed'),
    };
  }
}

@JsonSerializable()
class GetFamilyMembersResponseSealedCat extends GetFamilyMembersResponseSealed
    implements Cat {
  @override
  final CatType type;
  @override
  final int mewCount;

  const GetFamilyMembersResponseSealedCat({
    required this.type,
    required this.mewCount,
  });

  factory GetFamilyMembersResponseSealedCat.fromJson(
          Map<String, dynamic> json) =>
      _$GetFamilyMembersResponseSealedCatFromJson(json);

  @override
  Map<String, dynamic> toJson() =>
      _$GetFamilyMembersResponseSealedCatToJson(this);
}

@JsonSerializable()
class GetFamilyMembersResponseSealedDog extends GetFamilyMembersResponseSealed
    implements Dog {
  @override
  final DogType type;
  @override
  final String barkSound;

  const GetFamilyMembersResponseSealedDog({
    required this.type,
    required this.barkSound,
  });

  factory GetFamilyMembersResponseSealedDog.fromJson(
          Map<String, dynamic> json) =>
      _$GetFamilyMembersResponseSealedDogFromJson(json);

  @override
  Map<String, dynamic> toJson() =>
      _$GetFamilyMembersResponseSealedDogToJson(this);
}

@JsonSerializable()
class GetFamilyMembersResponseSealedHuman extends GetFamilyMembersResponseSealed
    implements Human {
  @override
  final HumanType type;
  @override
  final String job;

  const GetFamilyMembersResponseSealedHuman({
    required this.type,
    required this.job,
  });

  factory GetFamilyMembersResponseSealedHuman.fromJson(
          Map<String, dynamic> json) =>
      _$GetFamilyMembersResponseSealedHumanFromJson(json);

  @override
  Map<String, dynamic> toJson() =>
      _$GetFamilyMembersResponseSealedHumanToJson(this);
}

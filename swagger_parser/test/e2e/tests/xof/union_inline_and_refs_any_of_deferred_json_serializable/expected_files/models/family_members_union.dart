// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

import 'cat.dart';
import 'dog.dart';

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
      return FamilyMembersUnionVariant2.fromJson(json);
    } catch (_) {}
    try {
      return FamilyMembersUnionDog.fromJson(json);
    } catch (_) {}
    try {
      return FamilyMembersUnionVariant4.fromJson(json);
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
class FamilyMembersUnionVariant2 extends FamilyMembersUnion {
  @override
  final int chirpVolume;

  const FamilyMembersUnionVariant2({
    required this.chirpVolume,
  });

  factory FamilyMembersUnionVariant2.fromJson(Map<String, dynamic> json) =>
      _$FamilyMembersUnionVariant2FromJson(json);

  @override
  Map<String, dynamic> toJson() => _$FamilyMembersUnionVariant2ToJson(this);
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
class FamilyMembersUnionVariant4 extends FamilyMembersUnion {
  @override
  final String job;

  const FamilyMembersUnionVariant4({
    required this.job,
  });

  factory FamilyMembersUnionVariant4.fromJson(Map<String, dynamic> json) =>
      _$FamilyMembersUnionVariant4FromJson(json);

  @override
  Map<String, dynamic> toJson() => _$FamilyMembersUnionVariant4ToJson(this);
}

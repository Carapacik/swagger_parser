// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

import 'cat.dart';
import 'dog.dart';

part 'family_members_sealed.g.dart';

@JsonSerializable(createFactory: false)
sealed class FamilyMembersSealed {
  const FamilyMembersSealed();

  factory FamilyMembersSealed.fromJson(Map<String, dynamic> json) =>
      FamilyMembersSealedDeserializer.tryDeserialize(json);

  Map<String, dynamic> toJson();
}

extension FamilyMembersSealedDeserializer on FamilyMembersSealed {
  static FamilyMembersSealed tryDeserialize(Map<String, dynamic> json) {
    try {
      return FamilyMembersSealedCat.fromJson(json);
    } catch (_) {}
    try {
      return FamilyMembersSealedVariant2.fromJson(json);
    } catch (_) {}
    try {
      return FamilyMembersSealedDog.fromJson(json);
    } catch (_) {}
    try {
      return FamilyMembersSealedVariant4.fromJson(json);
    } catch (_) {}

    throw FormatException(
        'Could not determine the correct type for FamilyMembersSealed from: $json');
  }
}

@JsonSerializable()
class FamilyMembersSealedCat extends FamilyMembersSealed implements Cat {
  @override
  final int mewCount;

  const FamilyMembersSealedCat({
    required this.mewCount,
  });

  factory FamilyMembersSealedCat.fromJson(Map<String, dynamic> json) =>
      _$FamilyMembersSealedCatFromJson(json);

  @override
  Map<String, dynamic> toJson() => _$FamilyMembersSealedCatToJson(this);
}

@JsonSerializable()
class FamilyMembersSealedVariant2 extends FamilyMembersSealed {
  @override
  final int chirpVolume;

  const FamilyMembersSealedVariant2({
    required this.chirpVolume,
  });

  factory FamilyMembersSealedVariant2.fromJson(Map<String, dynamic> json) =>
      _$FamilyMembersSealedVariant2FromJson(json);

  @override
  Map<String, dynamic> toJson() => _$FamilyMembersSealedVariant2ToJson(this);
}

@JsonSerializable()
class FamilyMembersSealedDog extends FamilyMembersSealed implements Dog {
  @override
  final String barkSound;

  const FamilyMembersSealedDog({
    required this.barkSound,
  });

  factory FamilyMembersSealedDog.fromJson(Map<String, dynamic> json) =>
      _$FamilyMembersSealedDogFromJson(json);

  @override
  Map<String, dynamic> toJson() => _$FamilyMembersSealedDogToJson(this);
}

@JsonSerializable()
class FamilyMembersSealedVariant4 extends FamilyMembersSealed {
  @override
  final String job;

  const FamilyMembersSealedVariant4({
    required this.job,
  });

  factory FamilyMembersSealedVariant4.fromJson(Map<String, dynamic> json) =>
      _$FamilyMembersSealedVariant4FromJson(json);

  @override
  Map<String, dynamic> toJson() => _$FamilyMembersSealedVariant4ToJson(this);
}

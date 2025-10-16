// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

import 'cat.dart';
import 'dog.dart';
import 'human.dart';

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
      return FamilyMembersSealedDog.fromJson(json);
    } catch (_) {}
    try {
      return FamilyMembersSealedHuman.fromJson(json);
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
class FamilyMembersSealedHuman extends FamilyMembersSealed implements Human {
  @override
  final String job;

  const FamilyMembersSealedHuman({
    required this.job,
  });

  factory FamilyMembersSealedHuman.fromJson(Map<String, dynamic> json) =>
      _$FamilyMembersSealedHumanFromJson(json);

  @override
  Map<String, dynamic> toJson() => _$FamilyMembersSealedHumanToJson(this);
}

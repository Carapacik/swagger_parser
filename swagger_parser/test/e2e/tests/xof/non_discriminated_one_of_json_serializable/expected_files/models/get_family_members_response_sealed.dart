// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

import 'cat.dart';
import 'dog.dart';
import 'human.dart';

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
      Map<String, dynamic> json) {
    try {
      return GetFamilyMembersResponseSealedCat.fromJson(json);
    } catch (_) {}
    try {
      return GetFamilyMembersResponseSealedDog.fromJson(json);
    } catch (_) {}
    try {
      return GetFamilyMembersResponseSealedHuman.fromJson(json);
    } catch (_) {}

    throw FormatException(
        'Could not determine the correct type for GetFamilyMembersResponseSealed from: $json');
  }
}

@JsonSerializable()
class GetFamilyMembersResponseSealedCat extends GetFamilyMembersResponseSealed
    implements Cat {
  @override
  final int mewCount;

  const GetFamilyMembersResponseSealedCat({
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
  final String barkSound;

  const GetFamilyMembersResponseSealedDog({
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
  final String job;

  const GetFamilyMembersResponseSealedHuman({
    required this.job,
  });

  factory GetFamilyMembersResponseSealedHuman.fromJson(
          Map<String, dynamic> json) =>
      _$GetFamilyMembersResponseSealedHumanFromJson(json);

  @override
  Map<String, dynamic> toJson() =>
      _$GetFamilyMembersResponseSealedHumanToJson(this);
}

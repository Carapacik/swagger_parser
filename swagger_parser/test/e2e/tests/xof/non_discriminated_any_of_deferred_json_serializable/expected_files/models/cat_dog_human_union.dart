// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

import 'cat.dart';
import 'dog.dart';
import 'human.dart';

part 'cat_dog_human_union.g.dart';

@JsonSerializable(createFactory: false)
sealed class CatDogHumanUnion {
  const CatDogHumanUnion();

  factory CatDogHumanUnion.fromJson(Map<String, dynamic> json) =>
      CatDogHumanUnionUnionDeserializer.tryDeserialize(json);

  Map<String, dynamic> toJson();
}

extension CatDogHumanUnionUnionDeserializer on CatDogHumanUnion {
  static CatDogHumanUnion tryDeserialize(Map<String, dynamic> json) {
    try {
      return CatDogHumanUnionCat.fromJson(json);
    } catch (_) {}
    try {
      return CatDogHumanUnionDog.fromJson(json);
    } catch (_) {}
    try {
      return CatDogHumanUnionHuman.fromJson(json);
    } catch (_) {}

    throw FormatException(
        'Could not determine the correct type for CatDogHumanUnion from: $json');
  }
}

@JsonSerializable()
class CatDogHumanUnionCat extends CatDogHumanUnion implements Cat {
  @override
  final int mewCount;

  const CatDogHumanUnionCat({
    required this.mewCount,
  });

  factory CatDogHumanUnionCat.fromJson(Map<String, dynamic> json) =>
      _$CatDogHumanUnionCatFromJson(json);

  @override
  Map<String, dynamic> toJson() => _$CatDogHumanUnionCatToJson(this);
}

@JsonSerializable()
class CatDogHumanUnionDog extends CatDogHumanUnion implements Dog {
  @override
  final String barkSound;

  const CatDogHumanUnionDog({
    required this.barkSound,
  });

  factory CatDogHumanUnionDog.fromJson(Map<String, dynamic> json) =>
      _$CatDogHumanUnionDogFromJson(json);

  @override
  Map<String, dynamic> toJson() => _$CatDogHumanUnionDogToJson(this);
}

@JsonSerializable()
class CatDogHumanUnionHuman extends CatDogHumanUnion implements Human {
  @override
  final String job;

  const CatDogHumanUnionHuman({
    required this.job,
  });

  factory CatDogHumanUnionHuman.fromJson(Map<String, dynamic> json) =>
      _$CatDogHumanUnionHumanFromJson(json);

  @override
  Map<String, dynamic> toJson() => _$CatDogHumanUnionHumanToJson(this);
}

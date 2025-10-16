// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

import 'cat.dart';
import 'dog.dart';
import 'human.dart';

part 'cat_dog_human_sealed.g.dart';

@JsonSerializable(createFactory: false)
sealed class CatDogHumanSealed {
  const CatDogHumanSealed();

  factory CatDogHumanSealed.fromJson(Map<String, dynamic> json) =>
      CatDogHumanSealedDeserializer.tryDeserialize(json);

  Map<String, dynamic> toJson();
}

extension CatDogHumanSealedDeserializer on CatDogHumanSealed {
  static CatDogHumanSealed tryDeserialize(Map<String, dynamic> json) {
    try {
      return CatDogHumanSealedCat.fromJson(json);
    } catch (_) {}
    try {
      return CatDogHumanSealedDog.fromJson(json);
    } catch (_) {}
    try {
      return CatDogHumanSealedHuman.fromJson(json);
    } catch (_) {}

    throw FormatException(
        'Could not determine the correct type for CatDogHumanSealed from: $json');
  }
}

@JsonSerializable()
class CatDogHumanSealedCat extends CatDogHumanSealed implements Cat {
  @override
  final int mewCount;

  const CatDogHumanSealedCat({
    required this.mewCount,
  });

  factory CatDogHumanSealedCat.fromJson(Map<String, dynamic> json) =>
      _$CatDogHumanSealedCatFromJson(json);

  @override
  Map<String, dynamic> toJson() => _$CatDogHumanSealedCatToJson(this);
}

@JsonSerializable()
class CatDogHumanSealedDog extends CatDogHumanSealed implements Dog {
  @override
  final String barkSound;

  const CatDogHumanSealedDog({
    required this.barkSound,
  });

  factory CatDogHumanSealedDog.fromJson(Map<String, dynamic> json) =>
      _$CatDogHumanSealedDogFromJson(json);

  @override
  Map<String, dynamic> toJson() => _$CatDogHumanSealedDogToJson(this);
}

@JsonSerializable()
class CatDogHumanSealedHuman extends CatDogHumanSealed implements Human {
  @override
  final String job;

  const CatDogHumanSealedHuman({
    required this.job,
  });

  factory CatDogHumanSealedHuman.fromJson(Map<String, dynamic> json) =>
      _$CatDogHumanSealedHumanFromJson(json);

  @override
  Map<String, dynamic> toJson() => _$CatDogHumanSealedHumanToJson(this);
}

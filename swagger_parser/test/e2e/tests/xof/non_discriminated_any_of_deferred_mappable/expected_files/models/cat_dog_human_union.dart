// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:dart_mappable/dart_mappable.dart';

import 'cat.dart';
import 'dog.dart';
import 'human.dart';

part 'cat_dog_human_union.mapper.dart';

@MappableClass(includeSubClasses: [
  CatDogHumanUnionCat,
  CatDogHumanUnionDog,
  CatDogHumanUnionHuman
])
sealed class CatDogHumanUnion with CatDogHumanUnionMappable {
  const CatDogHumanUnion();

  static CatDogHumanUnion fromJson(Map<String, dynamic> json) {
    return _CatDogHumanUnionHelper._tryDeserialize(json);
  }
}

class _CatDogHumanUnionHelper {
  static CatDogHumanUnion _tryDeserialize(Map<String, dynamic> json) {
    try {
      return CatDogHumanUnionCatMapper.ensureInitialized()
          .decodeMap<CatDogHumanUnionCat>(json);
    } catch (_) {}
    try {
      return CatDogHumanUnionDogMapper.ensureInitialized()
          .decodeMap<CatDogHumanUnionDog>(json);
    } catch (_) {}
    try {
      return CatDogHumanUnionHumanMapper.ensureInitialized()
          .decodeMap<CatDogHumanUnionHuman>(json);
    } catch (_) {}

    throw FormatException(
        'Could not determine the correct type for CatDogHumanUnion from: $json');
  }
}

@MappableClass()
class CatDogHumanUnionCat extends CatDogHumanUnion
    with CatDogHumanUnionCatMappable
    implements Cat {
  final Cat _cat;

  const CatDogHumanUnionCat(this._cat);

  @override
  int get mewCount => _cat.mewCount;

  static CatDogHumanUnionCat fromJson(Map<String, dynamic> json) =>
      CatDogHumanUnionCat(CatMapper.ensureInitialized().decodeMap<Cat>(json));
}

@MappableClass()
class CatDogHumanUnionDog extends CatDogHumanUnion
    with CatDogHumanUnionDogMappable
    implements Dog {
  final Dog _dog;

  const CatDogHumanUnionDog(this._dog);

  @override
  String get barkSound => _dog.barkSound;

  static CatDogHumanUnionDog fromJson(Map<String, dynamic> json) =>
      CatDogHumanUnionDog(DogMapper.ensureInitialized().decodeMap<Dog>(json));
}

@MappableClass()
class CatDogHumanUnionHuman extends CatDogHumanUnion
    with CatDogHumanUnionHumanMappable
    implements Human {
  final Human _human;

  const CatDogHumanUnionHuman(this._human);

  @override
  String get job => _human.job;

  static CatDogHumanUnionHuman fromJson(Map<String, dynamic> json) =>
      CatDogHumanUnionHuman(
          HumanMapper.ensureInitialized().decodeMap<Human>(json));
}

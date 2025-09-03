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
  @override
  final int mewCount;

  const CatDogHumanUnionCat({
    required this.mewCount,
  });
}

@MappableClass()
class CatDogHumanUnionDog extends CatDogHumanUnion
    with CatDogHumanUnionDogMappable
    implements Dog {
  @override
  final String barkSound;

  const CatDogHumanUnionDog({
    required this.barkSound,
  });
}

@MappableClass()
class CatDogHumanUnionHuman extends CatDogHumanUnion
    with CatDogHumanUnionHumanMappable
    implements Human {
  @override
  final String job;

  const CatDogHumanUnionHuman({
    required this.job,
  });
}

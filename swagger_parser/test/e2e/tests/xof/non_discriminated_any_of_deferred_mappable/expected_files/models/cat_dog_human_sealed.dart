// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:dart_mappable/dart_mappable.dart';

import 'cat.dart';
import 'dog.dart';
import 'human.dart';

part 'cat_dog_human_sealed.mapper.dart';

@MappableClass(includeSubClasses: [
  CatDogHumanSealedCat,
  CatDogHumanSealedDog,
  CatDogHumanSealedHuman
])
sealed class CatDogHumanSealed with CatDogHumanSealedMappable {
  const CatDogHumanSealed();

  static CatDogHumanSealed fromJson(Map<String, dynamic> json) {
    return CatDogHumanSealedDeserializer.tryDeserialize(json);
  }
}

extension CatDogHumanSealedDeserializer on CatDogHumanSealed {
  static CatDogHumanSealed tryDeserialize(Map<String, dynamic> json) {
    try {
      return CatDogHumanSealedCatMapper.ensureInitialized()
          .decodeMap<CatDogHumanSealedCat>(json);
    } catch (_) {}
    try {
      return CatDogHumanSealedDogMapper.ensureInitialized()
          .decodeMap<CatDogHumanSealedDog>(json);
    } catch (_) {}
    try {
      return CatDogHumanSealedHumanMapper.ensureInitialized()
          .decodeMap<CatDogHumanSealedHuman>(json);
    } catch (_) {}

    throw FormatException(
        'Could not determine the correct type for CatDogHumanSealed from: $json');
  }
}

@MappableClass()
class CatDogHumanSealedCat extends CatDogHumanSealed
    with CatDogHumanSealedCatMappable
    implements Cat {
  @override
  final int mewCount;

  const CatDogHumanSealedCat({
    required this.mewCount,
  });
}

@MappableClass()
class CatDogHumanSealedDog extends CatDogHumanSealed
    with CatDogHumanSealedDogMappable
    implements Dog {
  @override
  final String barkSound;

  const CatDogHumanSealedDog({
    required this.barkSound,
  });
}

@MappableClass()
class CatDogHumanSealedHuman extends CatDogHumanSealed
    with CatDogHumanSealedHumanMappable
    implements Human {
  @override
  final String job;

  const CatDogHumanSealedHuman({
    required this.job,
  });
}

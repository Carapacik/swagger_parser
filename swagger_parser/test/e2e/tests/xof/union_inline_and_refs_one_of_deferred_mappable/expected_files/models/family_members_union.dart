// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:dart_mappable/dart_mappable.dart';

import 'cat.dart';
import 'variant2.dart';
import 'dog.dart';
import 'variant4.dart';

part 'family_members_union.mapper.dart';

@MappableClass(includeSubClasses: [
  FamilyMembersUnionCat,
  FamilyMembersUnionVariant2,
  FamilyMembersUnionDog,
  FamilyMembersUnionVariant4
])
sealed class FamilyMembersUnion with FamilyMembersUnionMappable {
  const FamilyMembersUnion();

  static FamilyMembersUnion fromJson(Map<String, dynamic> json) {
    return _FamilyMembersUnionHelper._tryDeserialize(json);
  }
}

class _FamilyMembersUnionHelper {
  static FamilyMembersUnion _tryDeserialize(Map<String, dynamic> json) {
    try {
      return FamilyMembersUnionCatMapper.ensureInitialized()
          .decodeMap<FamilyMembersUnionCat>(json);
    } catch (_) {}
    try {
      return FamilyMembersUnionVariant2Mapper.ensureInitialized()
          .decodeMap<FamilyMembersUnionVariant2>(json);
    } catch (_) {}
    try {
      return FamilyMembersUnionDogMapper.ensureInitialized()
          .decodeMap<FamilyMembersUnionDog>(json);
    } catch (_) {}
    try {
      return FamilyMembersUnionVariant4Mapper.ensureInitialized()
          .decodeMap<FamilyMembersUnionVariant4>(json);
    } catch (_) {}

    throw FormatException(
        'Could not determine the correct type for FamilyMembersUnion from: $json');
  }
}

@MappableClass()
class FamilyMembersUnionCat extends FamilyMembersUnion
    with FamilyMembersUnionCatMappable
    implements Cat {
  final Cat _cat;

  const FamilyMembersUnionCat(this._cat);

  @override
  int get mewCount => _cat.mewCount;

  static FamilyMembersUnionCat fromJson(Map<String, dynamic> json) =>
      FamilyMembersUnionCat(CatMapper.ensureInitialized().decodeMap<Cat>(json));
}

@MappableClass()
class FamilyMembersUnionVariant2 extends FamilyMembersUnion
    with FamilyMembersUnionVariant2Mappable
    implements Variant2 {
  final Variant2 _variant2;

  const FamilyMembersUnionVariant2(this._variant2);

  @override
  int get chirpVolume => _variant2.chirpVolume;

  static FamilyMembersUnionVariant2 fromJson(Map<String, dynamic> json) =>
      FamilyMembersUnionVariant2(
          Variant2Mapper.ensureInitialized().decodeMap<Variant2>(json));
}

@MappableClass()
class FamilyMembersUnionDog extends FamilyMembersUnion
    with FamilyMembersUnionDogMappable
    implements Dog {
  final Dog _dog;

  const FamilyMembersUnionDog(this._dog);

  @override
  String get barkSound => _dog.barkSound;

  static FamilyMembersUnionDog fromJson(Map<String, dynamic> json) =>
      FamilyMembersUnionDog(DogMapper.ensureInitialized().decodeMap<Dog>(json));
}

@MappableClass()
class FamilyMembersUnionVariant4 extends FamilyMembersUnion
    with FamilyMembersUnionVariant4Mappable
    implements Variant4 {
  final Variant4 _variant4;

  const FamilyMembersUnionVariant4(this._variant4);

  @override
  String get job => _variant4.job;

  static FamilyMembersUnionVariant4 fromJson(Map<String, dynamic> json) =>
      FamilyMembersUnionVariant4(
          Variant4Mapper.ensureInitialized().decodeMap<Variant4>(json));
}

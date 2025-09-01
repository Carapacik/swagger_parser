// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:dart_mappable/dart_mappable.dart';

import 'cat.dart';
import 'dog.dart';
import 'human.dart';

part 'family_members_union.mapper.dart';

@MappableClass(includeSubClasses: [
  FamilyMembersUnionCat,
  FamilyMembersUnionDog,
  FamilyMembersUnionHuman
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
      return FamilyMembersUnionDogMapper.ensureInitialized()
          .decodeMap<FamilyMembersUnionDog>(json);
    } catch (_) {}
    try {
      return FamilyMembersUnionHumanMapper.ensureInitialized()
          .decodeMap<FamilyMembersUnionHuman>(json);
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
class FamilyMembersUnionHuman extends FamilyMembersUnion
    with FamilyMembersUnionHumanMappable
    implements Human {
  final Human _human;

  const FamilyMembersUnionHuman(this._human);

  @override
  String get job => _human.job;

  static FamilyMembersUnionHuman fromJson(Map<String, dynamic> json) =>
      FamilyMembersUnionHuman(
          HumanMapper.ensureInitialized().decodeMap<Human>(json));
}

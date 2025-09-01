// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:dart_mappable/dart_mappable.dart';

import 'cat.dart';
import 'cat_type.dart';
import 'dog.dart';
import 'dog_type.dart';
import 'human.dart';
import 'human_type.dart';

part 'family_members_union.mapper.dart';

@MappableClass(discriminatorKey: 'type', includeSubClasses: [
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
    if (json['type'] == 'Cat') {
      return FamilyMembersUnionCatMapper.ensureInitialized()
          .decodeMap<FamilyMembersUnionCat>(json);
    } else if (json['type'] == 'Dog') {
      return FamilyMembersUnionDogMapper.ensureInitialized()
          .decodeMap<FamilyMembersUnionDog>(json);
    } else if (json['type'] == 'Human') {
      return FamilyMembersUnionHumanMapper.ensureInitialized()
          .decodeMap<FamilyMembersUnionHuman>(json);
    } else {
      throw FormatException(
          'Unknown discriminator value "${json['type']}" for FamilyMembersUnion');
    }
  }
}

@MappableClass(discriminatorValue: 'Cat')
class FamilyMembersUnionCat extends FamilyMembersUnion
    with FamilyMembersUnionCatMappable
    implements Cat {
  final Cat _cat;

  const FamilyMembersUnionCat(this._cat);

  @override
  CatType get type => _cat.type;
  @override
  int get mewCount => _cat.mewCount;

  static FamilyMembersUnionCat fromJson(Map<String, dynamic> json) =>
      FamilyMembersUnionCat(CatMapper.ensureInitialized().decodeMap<Cat>(json));
}

@MappableClass(discriminatorValue: 'Dog')
class FamilyMembersUnionDog extends FamilyMembersUnion
    with FamilyMembersUnionDogMappable
    implements Dog {
  final Dog _dog;

  const FamilyMembersUnionDog(this._dog);

  @override
  DogType get type => _dog.type;
  @override
  String get barkSound => _dog.barkSound;

  static FamilyMembersUnionDog fromJson(Map<String, dynamic> json) =>
      FamilyMembersUnionDog(DogMapper.ensureInitialized().decodeMap<Dog>(json));
}

@MappableClass(discriminatorValue: 'Human')
class FamilyMembersUnionHuman extends FamilyMembersUnion
    with FamilyMembersUnionHumanMappable
    implements Human {
  final Human _human;

  const FamilyMembersUnionHuman(this._human);

  @override
  HumanType get type => _human.type;
  @override
  String get job => _human.job;

  static FamilyMembersUnionHuman fromJson(Map<String, dynamic> json) =>
      FamilyMembersUnionHuman(
          HumanMapper.ensureInitialized().decodeMap<Human>(json));
}

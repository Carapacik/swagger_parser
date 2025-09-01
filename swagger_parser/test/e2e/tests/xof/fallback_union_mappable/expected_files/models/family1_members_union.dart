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

part 'family1_members_union.mapper.dart';

@MappableClass(discriminatorKey: 'type', includeSubClasses: [
  Family1MembersUnionCat,
  Family1MembersUnionDog,
  Family1MembersUnionHuman,
  Family1MembersUnionUnknown
])
sealed class Family1MembersUnion with Family1MembersUnionMappable {
  const Family1MembersUnion();

  static Family1MembersUnion fromJson(Map<String, dynamic> json) {
    return _Family1MembersUnionHelper._tryDeserialize(json);
  }
}

class _Family1MembersUnionHelper {
  static Family1MembersUnion _tryDeserialize(Map<String, dynamic> json) {
    if (json['type'] == 'Cat') {
      return Family1MembersUnionCatMapper.ensureInitialized()
          .decodeMap<Family1MembersUnionCat>(json);
    } else if (json['type'] == 'Dog') {
      return Family1MembersUnionDogMapper.ensureInitialized()
          .decodeMap<Family1MembersUnionDog>(json);
    } else if (json['type'] == 'Human') {
      return Family1MembersUnionHumanMapper.ensureInitialized()
          .decodeMap<Family1MembersUnionHuman>(json);
    } else {
      // Return fallback wrapper for unknown discriminator values
      return Family1MembersUnionUnknownMapper.ensureInitialized()
          .decodeMap<Family1MembersUnionUnknown>(json);
    }
  }
}

@MappableClass(discriminatorValue: 'Cat')
class Family1MembersUnionCat extends Family1MembersUnion
    with Family1MembersUnionCatMappable
    implements Cat {
  final Cat _cat;

  const Family1MembersUnionCat(this._cat);

  @override
  CatType get type => _cat.type;
  @override
  int get mewCount => _cat.mewCount;

  static Family1MembersUnionCat fromJson(Map<String, dynamic> json) =>
      Family1MembersUnionCat(
          CatMapper.ensureInitialized().decodeMap<Cat>(json));
}

@MappableClass(discriminatorValue: 'Dog')
class Family1MembersUnionDog extends Family1MembersUnion
    with Family1MembersUnionDogMappable
    implements Dog {
  final Dog _dog;

  const Family1MembersUnionDog(this._dog);

  @override
  DogType get type => _dog.type;
  @override
  String get barkSound => _dog.barkSound;

  static Family1MembersUnionDog fromJson(Map<String, dynamic> json) =>
      Family1MembersUnionDog(
          DogMapper.ensureInitialized().decodeMap<Dog>(json));
}

@MappableClass(discriminatorValue: 'Human')
class Family1MembersUnionHuman extends Family1MembersUnion
    with Family1MembersUnionHumanMappable
    implements Human {
  final Human _human;

  const Family1MembersUnionHuman(this._human);

  @override
  HumanType get type => _human.type;
  @override
  String get job => _human.job;

  static Family1MembersUnionHuman fromJson(Map<String, dynamic> json) =>
      Family1MembersUnionHuman(
          HumanMapper.ensureInitialized().decodeMap<Human>(json));
}

@MappableClass(discriminatorValue: MappableClass.useAsDefault)
class Family1MembersUnionUnknown extends Family1MembersUnion
    with Family1MembersUnionUnknownMappable {
  final Map<String, dynamic> _json;

  const Family1MembersUnionUnknown(this._json);

  /// Access raw JSON data for unknown union variant
  Map<String, dynamic> get json => _json;

  static Family1MembersUnionUnknown fromJson(Map<String, dynamic> json) =>
      Family1MembersUnionUnknown(json);
}

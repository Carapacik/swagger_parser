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
    return Family1MembersUnionUnionDeserializer.tryDeserialize(json);
  }
}

extension Family1MembersUnionUnionDeserializer on Family1MembersUnion {
  static Family1MembersUnion tryDeserialize(
    Map<String, dynamic> json, {
    String key = 'type',
    Map<Type, Object?>? mapping,
  }) {
    final mappingFallback = const <Type, Object?>{
      Family1MembersUnionCat: 'Cat',
      Family1MembersUnionDog: 'Dog',
      Family1MembersUnionHuman: 'Human',
    };
    final value = json[key];
    final effective = mapping ?? mappingFallback;
    return switch (value) {
      effective[Family1MembersUnionCat] =>
        Family1MembersUnionCatMapper.ensureInitialized()
            .decodeMap<Family1MembersUnionCat>(json),
      effective[Family1MembersUnionDog] =>
        Family1MembersUnionDogMapper.ensureInitialized()
            .decodeMap<Family1MembersUnionDog>(json),
      effective[Family1MembersUnionHuman] =>
        Family1MembersUnionHumanMapper.ensureInitialized()
            .decodeMap<Family1MembersUnionHuman>(json),
      _ => Family1MembersUnionUnknownMapper.ensureInitialized()
          .decodeMap<Family1MembersUnionUnknown>(json),
    };
  }
}

@MappableClass(discriminatorValue: 'Cat')
class Family1MembersUnionCat extends Family1MembersUnion
    with Family1MembersUnionCatMappable
    implements Cat {
  @override
  final CatType type;
  @override
  final int mewCount;

  const Family1MembersUnionCat({
    required this.type,
    required this.mewCount,
  });
}

@MappableClass(discriminatorValue: 'Dog')
class Family1MembersUnionDog extends Family1MembersUnion
    with Family1MembersUnionDogMappable
    implements Dog {
  @override
  final DogType type;
  @override
  final String barkSound;

  const Family1MembersUnionDog({
    required this.type,
    required this.barkSound,
  });
}

@MappableClass(discriminatorValue: 'Human')
class Family1MembersUnionHuman extends Family1MembersUnion
    with Family1MembersUnionHumanMappable
    implements Human {
  @override
  final HumanType type;
  @override
  final String job;

  const Family1MembersUnionHuman({
    required this.type,
    required this.job,
  });
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

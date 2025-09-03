// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:dart_mappable/dart_mappable.dart';

import 'cat_type.dart';
import 'dog_type.dart';
import 'human_type.dart';
import 'cat.dart';
import 'dog.dart';
import 'human.dart';

part 'family2_members_union.mapper.dart';

@MappableClass(includeSubClasses: [
  Family2MembersUnionCat,
  Family2MembersUnionDog,
  Family2MembersUnionHuman,
  Family2MembersUnionUnknown
])
sealed class Family2MembersUnion with Family2MembersUnionMappable {
  const Family2MembersUnion();

  static Family2MembersUnion fromJson(Map<String, dynamic> json) {
    return Family2MembersUnionUnionDeserializer.tryDeserialize(json);
  }
}

extension Family2MembersUnionUnionDeserializer on Family2MembersUnion {
  static Family2MembersUnion tryDeserialize(Map<String, dynamic> json) {
    try {
      return Family2MembersUnionCatMapper.ensureInitialized()
          .decodeMap<Family2MembersUnionCat>(json);
    } catch (_) {}
    try {
      return Family2MembersUnionDogMapper.ensureInitialized()
          .decodeMap<Family2MembersUnionDog>(json);
    } catch (_) {}
    try {
      return Family2MembersUnionHumanMapper.ensureInitialized()
          .decodeMap<Family2MembersUnionHuman>(json);
    } catch (_) {}
    // Try fallback variant before throwing exception
    try {
      return Family2MembersUnionUnknownMapper.ensureInitialized()
          .decodeMap<Family2MembersUnionUnknown>(json);
    } catch (_) {}

    throw FormatException(
        'Could not determine the correct type for Family2MembersUnion from: $json');
  }
}

@MappableClass()
class Family2MembersUnionCat extends Family2MembersUnion
    with Family2MembersUnionCatMappable
    implements Cat {
  @override
  final CatType type;
  @override
  final int mewCount;

  const Family2MembersUnionCat({
    required this.type,
    required this.mewCount,
  });
}

@MappableClass()
class Family2MembersUnionDog extends Family2MembersUnion
    with Family2MembersUnionDogMappable
    implements Dog {
  @override
  final DogType type;
  @override
  final String barkSound;

  const Family2MembersUnionDog({
    required this.type,
    required this.barkSound,
  });
}

@MappableClass()
class Family2MembersUnionHuman extends Family2MembersUnion
    with Family2MembersUnionHumanMappable
    implements Human {
  @override
  final HumanType type;
  @override
  final String job;

  const Family2MembersUnionHuman({
    required this.type,
    required this.job,
  });
}

@MappableClass()
class Family2MembersUnionUnknown extends Family2MembersUnion
    with Family2MembersUnionUnknownMappable {
  final Map<String, dynamic> _json;

  const Family2MembersUnionUnknown(this._json);

  /// Access raw JSON data for unknown union variant
  Map<String, dynamic> get json => _json;

  static Family2MembersUnionUnknown fromJson(Map<String, dynamic> json) =>
      Family2MembersUnionUnknown(json);
}

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

part 'family1_members_sealed.mapper.dart';

@MappableClass(discriminatorKey: 'type', includeSubClasses: [
  Family1MembersSealedCat,
  Family1MembersSealedDog,
  Family1MembersSealedHuman,
  Family1MembersSealedUnknown
])
sealed class Family1MembersSealed with Family1MembersSealedMappable {
  const Family1MembersSealed();

  static Family1MembersSealed fromJson(Map<String, dynamic> json) {
    return Family1MembersSealedDeserializer.tryDeserialize(json);
  }
}

extension Family1MembersSealedDeserializer on Family1MembersSealed {
  static Family1MembersSealed tryDeserialize(
    Map<String, dynamic> json, {
    String key = 'type',
    Map<Type, Object?>? mapping,
  }) {
    final mappingFallback = const <Type, Object?>{
      Family1MembersSealedCat: 'Cat',
      Family1MembersSealedDog: 'Dog',
      Family1MembersSealedHuman: 'Human',
    };
    final value = json[key];
    final effective = mapping ?? mappingFallback;
    return switch (value) {
      _ when value == effective[Family1MembersSealedCat] =>
        Family1MembersSealedCatMapper.ensureInitialized()
            .decodeMap<Family1MembersSealedCat>(json),
      _ when value == effective[Family1MembersSealedDog] =>
        Family1MembersSealedDogMapper.ensureInitialized()
            .decodeMap<Family1MembersSealedDog>(json),
      _ when value == effective[Family1MembersSealedHuman] =>
        Family1MembersSealedHumanMapper.ensureInitialized()
            .decodeMap<Family1MembersSealedHuman>(json),
      _ => Family1MembersSealedUnknownMapper.ensureInitialized()
          .decodeMap<Family1MembersSealedUnknown>(json),
    };
  }
}

@MappableClass(discriminatorValue: 'Cat')
class Family1MembersSealedCat extends Family1MembersSealed
    with Family1MembersSealedCatMappable
    implements Cat {
  @override
  final CatType type;
  @override
  final int mewCount;

  const Family1MembersSealedCat({
    required this.type,
    required this.mewCount,
  });
}

@MappableClass(discriminatorValue: 'Dog')
class Family1MembersSealedDog extends Family1MembersSealed
    with Family1MembersSealedDogMappable
    implements Dog {
  @override
  final DogType type;
  @override
  final String barkSound;

  const Family1MembersSealedDog({
    required this.type,
    required this.barkSound,
  });
}

@MappableClass(discriminatorValue: 'Human')
class Family1MembersSealedHuman extends Family1MembersSealed
    with Family1MembersSealedHumanMappable
    implements Human {
  @override
  final HumanType type;
  @override
  final String job;

  const Family1MembersSealedHuman({
    required this.type,
    required this.job,
  });
}

@MappableClass(discriminatorValue: MappableClass.useAsDefault)
class Family1MembersSealedUnknown extends Family1MembersSealed
    with Family1MembersSealedUnknownMappable {
  final Map<String, dynamic> _json;

  const Family1MembersSealedUnknown(this._json);

  /// Access raw JSON data for unknown union variant
  Map<String, dynamic> get json => _json;

  static Family1MembersSealedUnknown fromJson(Map<String, dynamic> json) =>
      Family1MembersSealedUnknown(json);
}

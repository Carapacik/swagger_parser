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
    return FamilyMembersUnionUnionDeserializer.tryDeserialize(json);
  }
}

extension FamilyMembersUnionUnionDeserializer on FamilyMembersUnion {
  static FamilyMembersUnion tryDeserialize(
    Map<String, dynamic> json, {
    String key = 'type',
    Map<Type, Object?>? mapping,
  }) {
    final mappingFallback = const <Type, Object?>{
      FamilyMembersUnionCat: 'Cat',
      FamilyMembersUnionDog: 'Dog',
      FamilyMembersUnionHuman: 'Human',
    };
    final value = json[key];
    final effective = mapping ?? mappingFallback;
    return switch (value) {
      _ when value == effective[FamilyMembersUnionCat] =>
        FamilyMembersUnionCatMapper.ensureInitialized()
            .decodeMap<FamilyMembersUnionCat>(json),
      _ when value == effective[FamilyMembersUnionDog] =>
        FamilyMembersUnionDogMapper.ensureInitialized()
            .decodeMap<FamilyMembersUnionDog>(json),
      _ when value == effective[FamilyMembersUnionHuman] =>
        FamilyMembersUnionHumanMapper.ensureInitialized()
            .decodeMap<FamilyMembersUnionHuman>(json),
      _ => throw FormatException(
          'Unknown discriminator value "${json[key]}" for FamilyMembersUnion'),
    };
  }
}

@MappableClass(discriminatorValue: 'Cat')
class FamilyMembersUnionCat extends FamilyMembersUnion
    with FamilyMembersUnionCatMappable
    implements Cat {
  @override
  final CatType type;
  @override
  final int mewCount;

  const FamilyMembersUnionCat({
    required this.type,
    required this.mewCount,
  });
}

@MappableClass(discriminatorValue: 'Dog')
class FamilyMembersUnionDog extends FamilyMembersUnion
    with FamilyMembersUnionDogMappable
    implements Dog {
  @override
  final DogType type;
  @override
  final String barkSound;

  const FamilyMembersUnionDog({
    required this.type,
    required this.barkSound,
  });
}

@MappableClass(discriminatorValue: 'Human')
class FamilyMembersUnionHuman extends FamilyMembersUnion
    with FamilyMembersUnionHumanMappable
    implements Human {
  @override
  final HumanType type;
  @override
  final String job;

  const FamilyMembersUnionHuman({
    required this.type,
    required this.job,
  });
}

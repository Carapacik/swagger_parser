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

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
    return FamilyMembersUnionUnionDeserializer.tryDeserialize(json);
  }
}

extension FamilyMembersUnionUnionDeserializer on FamilyMembersUnion {
  static FamilyMembersUnion tryDeserialize(Map<String, dynamic> json) {
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
  @override
  final int mewCount;

  const FamilyMembersUnionCat({
    required this.mewCount,
  });
}

@MappableClass()
class FamilyMembersUnionDog extends FamilyMembersUnion
    with FamilyMembersUnionDogMappable
    implements Dog {
  @override
  final String barkSound;

  const FamilyMembersUnionDog({
    required this.barkSound,
  });
}

@MappableClass()
class FamilyMembersUnionHuman extends FamilyMembersUnion
    with FamilyMembersUnionHumanMappable
    implements Human {
  @override
  final String job;

  const FamilyMembersUnionHuman({
    required this.job,
  });
}

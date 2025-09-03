// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:dart_mappable/dart_mappable.dart';

import 'cat.dart';
import 'dog.dart';

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
  @override
  final int mewCount;

  const FamilyMembersUnionCat({
    required this.mewCount,
  });
}

@MappableClass()
class FamilyMembersUnionVariant2 extends FamilyMembersUnion
    with FamilyMembersUnionVariant2Mappable {
  @override
  final int chirpVolume;

  const FamilyMembersUnionVariant2({
    required this.chirpVolume,
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
class FamilyMembersUnionVariant4 extends FamilyMembersUnion
    with FamilyMembersUnionVariant4Mappable {
  @override
  final String job;

  const FamilyMembersUnionVariant4({
    required this.job,
  });
}

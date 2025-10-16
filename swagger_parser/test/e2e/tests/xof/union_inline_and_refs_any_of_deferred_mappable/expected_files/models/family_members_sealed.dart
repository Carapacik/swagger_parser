// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:dart_mappable/dart_mappable.dart';

import 'cat.dart';
import 'dog.dart';

part 'family_members_sealed.mapper.dart';

@MappableClass(includeSubClasses: [
  FamilyMembersSealedCat,
  FamilyMembersSealedVariant2,
  FamilyMembersSealedDog,
  FamilyMembersSealedVariant4
])
sealed class FamilyMembersSealed with FamilyMembersSealedMappable {
  const FamilyMembersSealed();

  static FamilyMembersSealed fromJson(Map<String, dynamic> json) {
    return FamilyMembersSealedDeserializer.tryDeserialize(json);
  }
}

extension FamilyMembersSealedDeserializer on FamilyMembersSealed {
  static FamilyMembersSealed tryDeserialize(Map<String, dynamic> json) {
    try {
      return FamilyMembersSealedCatMapper.ensureInitialized()
          .decodeMap<FamilyMembersSealedCat>(json);
    } catch (_) {}
    try {
      return FamilyMembersSealedVariant2Mapper.ensureInitialized()
          .decodeMap<FamilyMembersSealedVariant2>(json);
    } catch (_) {}
    try {
      return FamilyMembersSealedDogMapper.ensureInitialized()
          .decodeMap<FamilyMembersSealedDog>(json);
    } catch (_) {}
    try {
      return FamilyMembersSealedVariant4Mapper.ensureInitialized()
          .decodeMap<FamilyMembersSealedVariant4>(json);
    } catch (_) {}

    throw FormatException(
        'Could not determine the correct type for FamilyMembersSealed from: $json');
  }
}

@MappableClass()
class FamilyMembersSealedCat extends FamilyMembersSealed
    with FamilyMembersSealedCatMappable
    implements Cat {
  @override
  final int mewCount;

  const FamilyMembersSealedCat({
    required this.mewCount,
  });
}

@MappableClass()
class FamilyMembersSealedVariant2 extends FamilyMembersSealed
    with FamilyMembersSealedVariant2Mappable {
  @override
  final int chirpVolume;

  const FamilyMembersSealedVariant2({
    required this.chirpVolume,
  });
}

@MappableClass()
class FamilyMembersSealedDog extends FamilyMembersSealed
    with FamilyMembersSealedDogMappable
    implements Dog {
  @override
  final String barkSound;

  const FamilyMembersSealedDog({
    required this.barkSound,
  });
}

@MappableClass()
class FamilyMembersSealedVariant4 extends FamilyMembersSealed
    with FamilyMembersSealedVariant4Mappable {
  @override
  final String job;

  const FamilyMembersSealedVariant4({
    required this.job,
  });
}

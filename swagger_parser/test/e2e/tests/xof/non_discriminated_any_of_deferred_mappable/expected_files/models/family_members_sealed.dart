// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:dart_mappable/dart_mappable.dart';

import 'cat.dart';
import 'dog.dart';
import 'human.dart';

part 'family_members_sealed.mapper.dart';

@MappableClass(includeSubClasses: [
  FamilyMembersSealedCat,
  FamilyMembersSealedDog,
  FamilyMembersSealedHuman
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
      return FamilyMembersSealedDogMapper.ensureInitialized()
          .decodeMap<FamilyMembersSealedDog>(json);
    } catch (_) {}
    try {
      return FamilyMembersSealedHumanMapper.ensureInitialized()
          .decodeMap<FamilyMembersSealedHuman>(json);
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
class FamilyMembersSealedHuman extends FamilyMembersSealed
    with FamilyMembersSealedHumanMappable
    implements Human {
  @override
  final String job;

  const FamilyMembersSealedHuman({
    required this.job,
  });
}

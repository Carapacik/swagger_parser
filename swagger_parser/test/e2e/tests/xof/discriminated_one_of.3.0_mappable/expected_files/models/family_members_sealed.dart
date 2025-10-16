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

part 'family_members_sealed.mapper.dart';

@MappableClass(discriminatorKey: 'type', includeSubClasses: [
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
  static FamilyMembersSealed tryDeserialize(
    Map<String, dynamic> json, {
    String key = 'type',
    Map<Type, Object?>? mapping,
  }) {
    final mappingFallback = const <Type, Object?>{
      FamilyMembersSealedCat: 'Cat',
      FamilyMembersSealedDog: 'Dog',
      FamilyMembersSealedHuman: 'Human',
    };
    final value = json[key];
    final effective = mapping ?? mappingFallback;
    return switch (value) {
      _ when value == effective[FamilyMembersSealedCat] =>
        FamilyMembersSealedCatMapper.ensureInitialized()
            .decodeMap<FamilyMembersSealedCat>(json),
      _ when value == effective[FamilyMembersSealedDog] =>
        FamilyMembersSealedDogMapper.ensureInitialized()
            .decodeMap<FamilyMembersSealedDog>(json),
      _ when value == effective[FamilyMembersSealedHuman] =>
        FamilyMembersSealedHumanMapper.ensureInitialized()
            .decodeMap<FamilyMembersSealedHuman>(json),
      _ => throw FormatException(
          'Unknown discriminator value "${json[key]}" for FamilyMembersSealed'),
    };
  }
}

@MappableClass(discriminatorValue: 'Cat')
class FamilyMembersSealedCat extends FamilyMembersSealed
    with FamilyMembersSealedCatMappable
    implements Cat {
  @override
  final CatType type;
  @override
  final int mewCount;

  const FamilyMembersSealedCat({
    required this.type,
    required this.mewCount,
  });
}

@MappableClass(discriminatorValue: 'Dog')
class FamilyMembersSealedDog extends FamilyMembersSealed
    with FamilyMembersSealedDogMappable
    implements Dog {
  @override
  final DogType type;
  @override
  final String barkSound;

  const FamilyMembersSealedDog({
    required this.type,
    required this.barkSound,
  });
}

@MappableClass(discriminatorValue: 'Human')
class FamilyMembersSealedHuman extends FamilyMembersSealed
    with FamilyMembersSealedHumanMappable
    implements Human {
  @override
  final HumanType type;
  @override
  final String job;

  const FamilyMembersSealedHuman({
    required this.type,
    required this.job,
  });
}

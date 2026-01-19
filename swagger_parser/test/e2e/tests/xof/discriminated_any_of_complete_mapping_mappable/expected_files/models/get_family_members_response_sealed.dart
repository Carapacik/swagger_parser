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

part 'get_family_members_response_sealed.mapper.dart';

@MappableClass(discriminatorKey: 'type', includeSubClasses: [
  GetFamilyMembersResponseSealedCat,
  GetFamilyMembersResponseSealedDog,
  GetFamilyMembersResponseSealedHuman
])
sealed class GetFamilyMembersResponseSealed
    with GetFamilyMembersResponseSealedMappable {
  const GetFamilyMembersResponseSealed();

  static GetFamilyMembersResponseSealed fromJson(Map<String, dynamic> json) {
    return GetFamilyMembersResponseSealedDeserializer.tryDeserialize(json);
  }
}

extension GetFamilyMembersResponseSealedDeserializer
    on GetFamilyMembersResponseSealed {
  static GetFamilyMembersResponseSealed tryDeserialize(
    Map<String, dynamic> json, {
    String key = 'type',
    Map<Type, Object?>? mapping,
  }) {
    final mappingFallback = const <Type, Object?>{
      GetFamilyMembersResponseSealedCat: 'Cat',
      GetFamilyMembersResponseSealedDog: 'Dog',
      GetFamilyMembersResponseSealedHuman: 'Human',
    };
    final value = json[key];
    final effective = mapping ?? mappingFallback;
    return switch (value) {
      _ when value == effective[GetFamilyMembersResponseSealedCat] =>
        GetFamilyMembersResponseSealedCatMapper.ensureInitialized()
            .decodeMap<GetFamilyMembersResponseSealedCat>(json),
      _ when value == effective[GetFamilyMembersResponseSealedDog] =>
        GetFamilyMembersResponseSealedDogMapper.ensureInitialized()
            .decodeMap<GetFamilyMembersResponseSealedDog>(json),
      _ when value == effective[GetFamilyMembersResponseSealedHuman] =>
        GetFamilyMembersResponseSealedHumanMapper.ensureInitialized()
            .decodeMap<GetFamilyMembersResponseSealedHuman>(json),
      _ => throw FormatException(
          'Unknown discriminator value "${json[key]}" for GetFamilyMembersResponseSealed'),
    };
  }
}

@MappableClass(discriminatorValue: 'Cat')
class GetFamilyMembersResponseSealedCat extends GetFamilyMembersResponseSealed
    with GetFamilyMembersResponseSealedCatMappable
    implements Cat {
  @override
  final CatType type;
  @override
  final int mewCount;

  const GetFamilyMembersResponseSealedCat({
    required this.type,
    required this.mewCount,
  });
}

@MappableClass(discriminatorValue: 'Dog')
class GetFamilyMembersResponseSealedDog extends GetFamilyMembersResponseSealed
    with GetFamilyMembersResponseSealedDogMappable
    implements Dog {
  @override
  final DogType type;
  @override
  final String barkSound;

  const GetFamilyMembersResponseSealedDog({
    required this.type,
    required this.barkSound,
  });
}

@MappableClass(discriminatorValue: 'Human')
class GetFamilyMembersResponseSealedHuman extends GetFamilyMembersResponseSealed
    with GetFamilyMembersResponseSealedHumanMappable
    implements Human {
  @override
  final HumanType type;
  @override
  final String job;

  const GetFamilyMembersResponseSealedHuman({
    required this.type,
    required this.job,
  });
}

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

part 'family2_members_sealed.mapper.dart';

@MappableClass(includeSubClasses: [
  Family2MembersSealedCat,
  Family2MembersSealedDog,
  Family2MembersSealedHuman,
  Family2MembersSealedUnknown
])
sealed class Family2MembersSealed with Family2MembersSealedMappable {
  const Family2MembersSealed();

  static Family2MembersSealed fromJson(Map<String, dynamic> json) {
    return Family2MembersSealedDeserializer.tryDeserialize(json);
  }
}

extension Family2MembersSealedDeserializer on Family2MembersSealed {
  static Family2MembersSealed tryDeserialize(Map<String, dynamic> json) {
    try {
      return Family2MembersSealedCatMapper.ensureInitialized()
          .decodeMap<Family2MembersSealedCat>(json);
    } catch (_) {}
    try {
      return Family2MembersSealedDogMapper.ensureInitialized()
          .decodeMap<Family2MembersSealedDog>(json);
    } catch (_) {}
    try {
      return Family2MembersSealedHumanMapper.ensureInitialized()
          .decodeMap<Family2MembersSealedHuman>(json);
    } catch (_) {}
    // Try fallback variant before throwing exception
    try {
      return Family2MembersSealedUnknownMapper.ensureInitialized()
          .decodeMap<Family2MembersSealedUnknown>(json);
    } catch (_) {}

    throw FormatException(
        'Could not determine the correct type for Family2MembersSealed from: $json');
  }
}

@MappableClass()
class Family2MembersSealedCat extends Family2MembersSealed
    with Family2MembersSealedCatMappable
    implements Cat {
  @override
  final CatType type;
  @override
  final int mewCount;

  const Family2MembersSealedCat({
    required this.type,
    required this.mewCount,
  });
}

@MappableClass()
class Family2MembersSealedDog extends Family2MembersSealed
    with Family2MembersSealedDogMappable
    implements Dog {
  @override
  final DogType type;
  @override
  final String barkSound;

  const Family2MembersSealedDog({
    required this.type,
    required this.barkSound,
  });
}

@MappableClass()
class Family2MembersSealedHuman extends Family2MembersSealed
    with Family2MembersSealedHumanMappable
    implements Human {
  @override
  final HumanType type;
  @override
  final String job;

  const Family2MembersSealedHuman({
    required this.type,
    required this.job,
  });
}

@MappableClass()
class Family2MembersSealedUnknown extends Family2MembersSealed
    with Family2MembersSealedUnknownMappable {
  final Map<String, dynamic> _json;

  const Family2MembersSealedUnknown(this._json);

  /// Access raw JSON data for unknown union variant
  Map<String, dynamic> get json => _json;

  static Family2MembersSealedUnknown fromJson(Map<String, dynamic> json) =>
      Family2MembersSealedUnknown(json);
}

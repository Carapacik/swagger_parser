// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

import 'cat_type.dart';
import 'dog_type.dart';
import 'human_type.dart';
import 'cat.dart';
import 'dog.dart';
import 'human.dart';

part 'family2_members_sealed.g.dart';

@JsonSerializable(createFactory: false)
sealed class Family2MembersSealed {
  const Family2MembersSealed();

  factory Family2MembersSealed.fromJson(Map<String, dynamic> json) =>
      Family2MembersSealedDeserializer.tryDeserialize(json);

  Map<String, dynamic> toJson();
}

extension Family2MembersSealedDeserializer on Family2MembersSealed {
  static Family2MembersSealed tryDeserialize(Map<String, dynamic> json) {
    try {
      return Family2MembersSealedCat.fromJson(json);
    } catch (_) {}
    try {
      return Family2MembersSealedDog.fromJson(json);
    } catch (_) {}
    try {
      return Family2MembersSealedHuman.fromJson(json);
    } catch (_) {}
    try {
      return Family2MembersSealedUnknown.fromJson(json);
    } catch (_) {}

    throw FormatException(
        'Could not determine the correct type for Family2MembersSealed from: $json');
  }
}

@JsonSerializable()
class Family2MembersSealedCat extends Family2MembersSealed implements Cat {
  @override
  final CatType type;
  @override
  final int mewCount;

  const Family2MembersSealedCat({
    required this.type,
    required this.mewCount,
  });

  factory Family2MembersSealedCat.fromJson(Map<String, dynamic> json) =>
      _$Family2MembersSealedCatFromJson(json);

  @override
  Map<String, dynamic> toJson() => _$Family2MembersSealedCatToJson(this);
}

@JsonSerializable()
class Family2MembersSealedDog extends Family2MembersSealed implements Dog {
  @override
  final DogType type;
  @override
  final String barkSound;

  const Family2MembersSealedDog({
    required this.type,
    required this.barkSound,
  });

  factory Family2MembersSealedDog.fromJson(Map<String, dynamic> json) =>
      _$Family2MembersSealedDogFromJson(json);

  @override
  Map<String, dynamic> toJson() => _$Family2MembersSealedDogToJson(this);
}

@JsonSerializable()
class Family2MembersSealedHuman extends Family2MembersSealed implements Human {
  @override
  final HumanType type;
  @override
  final String job;

  const Family2MembersSealedHuman({
    required this.type,
    required this.job,
  });

  factory Family2MembersSealedHuman.fromJson(Map<String, dynamic> json) =>
      _$Family2MembersSealedHumanFromJson(json);

  @override
  Map<String, dynamic> toJson() => _$Family2MembersSealedHumanToJson(this);
}

@JsonSerializable(createFactory: false)
class Family2MembersSealedUnknown extends Family2MembersSealed {
  final Map<String, dynamic> _json;

  const Family2MembersSealedUnknown(this._json);

  /// Access raw JSON data for unknown union variant
  Map<String, dynamic> get json => _json;

  factory Family2MembersSealedUnknown.fromJson(Map<String, dynamic> json) =>
      Family2MembersSealedUnknown(json);

  @override
  Map<String, dynamic> toJson() => _json;
}

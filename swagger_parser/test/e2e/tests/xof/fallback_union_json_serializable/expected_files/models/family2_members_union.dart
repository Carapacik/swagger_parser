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

part 'family2_members_union.g.dart';

@JsonSerializable(createFactory: false)
sealed class Family2MembersUnion {
  const Family2MembersUnion();

  factory Family2MembersUnion.fromJson(Map<String, dynamic> json) =>
      _Family2MembersUnionHelper._tryDeserialize(json);

  Map<String, dynamic> toJson();
}

class _Family2MembersUnionHelper {
  static Family2MembersUnion _tryDeserialize(Map<String, dynamic> json) {
    try {
      return Family2MembersUnionCat.fromJson(json);
    } catch (_) {}
    try {
      return Family2MembersUnionDog.fromJson(json);
    } catch (_) {}
    try {
      return Family2MembersUnionHuman.fromJson(json);
    } catch (_) {}
    try {
      return Family2MembersUnionUnknown.fromJson(json);
    } catch (_) {}

    throw FormatException(
        'Could not determine the correct type for Family2MembersUnion from: $json');
  }
}

@JsonSerializable()
class Family2MembersUnionCat extends Family2MembersUnion implements Cat {
  @override
  final CatType type;
  @override
  final int mewCount;

  const Family2MembersUnionCat({
    required this.type,
    required this.mewCount,
  });

  factory Family2MembersUnionCat.fromJson(Map<String, dynamic> json) =>
      _$Family2MembersUnionCatFromJson(json);

  @override
  Map<String, dynamic> toJson() => _$Family2MembersUnionCatToJson(this);
}

@JsonSerializable()
class Family2MembersUnionDog extends Family2MembersUnion implements Dog {
  @override
  final DogType type;
  @override
  final String barkSound;

  const Family2MembersUnionDog({
    required this.type,
    required this.barkSound,
  });

  factory Family2MembersUnionDog.fromJson(Map<String, dynamic> json) =>
      _$Family2MembersUnionDogFromJson(json);

  @override
  Map<String, dynamic> toJson() => _$Family2MembersUnionDogToJson(this);
}

@JsonSerializable()
class Family2MembersUnionHuman extends Family2MembersUnion implements Human {
  @override
  final HumanType type;
  @override
  final String job;

  const Family2MembersUnionHuman({
    required this.type,
    required this.job,
  });

  factory Family2MembersUnionHuman.fromJson(Map<String, dynamic> json) =>
      _$Family2MembersUnionHumanFromJson(json);

  @override
  Map<String, dynamic> toJson() => _$Family2MembersUnionHumanToJson(this);
}

@JsonSerializable(createFactory: false)
class Family2MembersUnionUnknown extends Family2MembersUnion {
  final Map<String, dynamic> _json;

  const Family2MembersUnionUnknown(this._json);

  /// Access raw JSON data for unknown union variant
  Map<String, dynamic> get json => _json;

  factory Family2MembersUnionUnknown.fromJson(Map<String, dynamic> json) =>
      Family2MembersUnionUnknown(json);

  @override
  Map<String, dynamic> toJson() => _json;
}

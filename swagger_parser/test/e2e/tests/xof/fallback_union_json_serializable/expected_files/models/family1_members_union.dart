// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

import 'cat.dart';
import 'cat_type.dart';
import 'dog.dart';
import 'dog_type.dart';
import 'human.dart';
import 'human_type.dart';

part 'family1_members_union.g.dart';

@JsonSerializable(createFactory: false)
sealed class Family1MembersUnion {
  const Family1MembersUnion();

  factory Family1MembersUnion.fromJson(Map<String, dynamic> json) =>
      Family1MembersUnionUnionDeserializer.tryDeserialize(json);

  Map<String, dynamic> toJson();
}

extension Family1MembersUnionUnionDeserializer on Family1MembersUnion {
  static Family1MembersUnion tryDeserialize(
    Map<String, dynamic> json, {
    String key = 'type',
    Map<Type, Object?>? mapping,
  }) {
    final mappingFallback = const <Type, Object?>{
      Family1MembersUnionCat: 'Cat',
      Family1MembersUnionDog: 'Dog',
      Family1MembersUnionHuman: 'Human',
    };
    final value = json[key];
    final effective = mapping ?? mappingFallback;
    return switch (value) {
      _ when value == effective[Family1MembersUnionCat] =>
        Family1MembersUnionCat.fromJson(json),
      _ when value == effective[Family1MembersUnionDog] =>
        Family1MembersUnionDog.fromJson(json),
      _ when value == effective[Family1MembersUnionHuman] =>
        Family1MembersUnionHuman.fromJson(json),
      _ => Family1MembersUnionUnknown.fromJson(json),
    };
  }
}

@JsonSerializable()
class Family1MembersUnionCat extends Family1MembersUnion implements Cat {
  @override
  final CatType type;
  @override
  final int mewCount;

  const Family1MembersUnionCat({
    required this.type,
    required this.mewCount,
  });

  factory Family1MembersUnionCat.fromJson(Map<String, dynamic> json) =>
      _$Family1MembersUnionCatFromJson(json);

  @override
  Map<String, dynamic> toJson() => _$Family1MembersUnionCatToJson(this);
}

@JsonSerializable()
class Family1MembersUnionDog extends Family1MembersUnion implements Dog {
  @override
  final DogType type;
  @override
  final String barkSound;

  const Family1MembersUnionDog({
    required this.type,
    required this.barkSound,
  });

  factory Family1MembersUnionDog.fromJson(Map<String, dynamic> json) =>
      _$Family1MembersUnionDogFromJson(json);

  @override
  Map<String, dynamic> toJson() => _$Family1MembersUnionDogToJson(this);
}

@JsonSerializable()
class Family1MembersUnionHuman extends Family1MembersUnion implements Human {
  @override
  final HumanType type;
  @override
  final String job;

  const Family1MembersUnionHuman({
    required this.type,
    required this.job,
  });

  factory Family1MembersUnionHuman.fromJson(Map<String, dynamic> json) =>
      _$Family1MembersUnionHumanFromJson(json);

  @override
  Map<String, dynamic> toJson() => _$Family1MembersUnionHumanToJson(this);
}

@JsonSerializable(createFactory: false)
class Family1MembersUnionUnknown extends Family1MembersUnion {
  final Map<String, dynamic> _json;

  const Family1MembersUnionUnknown(this._json);

  /// Access raw JSON data for unknown union variant
  Map<String, dynamic> get json => _json;

  factory Family1MembersUnionUnknown.fromJson(Map<String, dynamic> json) =>
      Family1MembersUnionUnknown(json);

  @override
  Map<String, dynamic> toJson() => _json;
}

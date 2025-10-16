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

part 'family1_members_sealed.g.dart';

@JsonSerializable(createFactory: false)
sealed class Family1MembersSealed {
  const Family1MembersSealed();

  factory Family1MembersSealed.fromJson(Map<String, dynamic> json) =>
      Family1MembersSealedDeserializer.tryDeserialize(json);

  Map<String, dynamic> toJson();
}

extension Family1MembersSealedDeserializer on Family1MembersSealed {
  static Family1MembersSealed tryDeserialize(
    Map<String, dynamic> json, {
    String key = 'type',
    Map<Type, Object?>? mapping,
  }) {
    final mappingFallback = const <Type, Object?>{
      Family1MembersSealedCat: 'Cat',
      Family1MembersSealedDog: 'Dog',
      Family1MembersSealedHuman: 'Human',
    };
    final value = json[key];
    final effective = mapping ?? mappingFallback;
    return switch (value) {
      _ when value == effective[Family1MembersSealedCat] =>
        Family1MembersSealedCat.fromJson(json),
      _ when value == effective[Family1MembersSealedDog] =>
        Family1MembersSealedDog.fromJson(json),
      _ when value == effective[Family1MembersSealedHuman] =>
        Family1MembersSealedHuman.fromJson(json),
      _ => Family1MembersSealedUnknown.fromJson(json),
    };
  }
}

@JsonSerializable()
class Family1MembersSealedCat extends Family1MembersSealed implements Cat {
  @override
  final CatType type;
  @override
  final int mewCount;

  const Family1MembersSealedCat({
    required this.type,
    required this.mewCount,
  });

  factory Family1MembersSealedCat.fromJson(Map<String, dynamic> json) =>
      _$Family1MembersSealedCatFromJson(json);

  @override
  Map<String, dynamic> toJson() => _$Family1MembersSealedCatToJson(this);
}

@JsonSerializable()
class Family1MembersSealedDog extends Family1MembersSealed implements Dog {
  @override
  final DogType type;
  @override
  final String barkSound;

  const Family1MembersSealedDog({
    required this.type,
    required this.barkSound,
  });

  factory Family1MembersSealedDog.fromJson(Map<String, dynamic> json) =>
      _$Family1MembersSealedDogFromJson(json);

  @override
  Map<String, dynamic> toJson() => _$Family1MembersSealedDogToJson(this);
}

@JsonSerializable()
class Family1MembersSealedHuman extends Family1MembersSealed implements Human {
  @override
  final HumanType type;
  @override
  final String job;

  const Family1MembersSealedHuman({
    required this.type,
    required this.job,
  });

  factory Family1MembersSealedHuman.fromJson(Map<String, dynamic> json) =>
      _$Family1MembersSealedHumanFromJson(json);

  @override
  Map<String, dynamic> toJson() => _$Family1MembersSealedHumanToJson(this);
}

@JsonSerializable(createFactory: false)
class Family1MembersSealedUnknown extends Family1MembersSealed {
  final Map<String, dynamic> _json;

  const Family1MembersSealedUnknown(this._json);

  /// Access raw JSON data for unknown union variant
  Map<String, dynamic> get json => _json;

  factory Family1MembersSealedUnknown.fromJson(Map<String, dynamic> json) =>
      Family1MembersSealedUnknown(json);

  @override
  Map<String, dynamic> toJson() => _json;
}

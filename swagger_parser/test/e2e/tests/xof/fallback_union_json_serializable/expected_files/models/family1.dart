// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

import 'family1_members_sealed.dart';

part 'family1.g.dart';

@JsonSerializable()
class Family1 {
  const Family1({
    required this.members,
  });

  factory Family1.fromJson(Map<String, Object?> json) =>
      _$Family1FromJson(json);

  final List<Family1MembersSealed> members;

  Map<String, Object?> toJson() => _$Family1ToJson(this);
}

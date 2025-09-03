// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

import 'human_type.dart';

part 'human.g.dart';

@JsonSerializable()
class Human {
  const Human({
    required this.type,
    required this.job,
  });

  factory Human.fromJson(Map<String, Object?> json) => _$HumanFromJson(json);

  final HumanType type;

  /// The job of the human.
  final String job;

  Map<String, Object?> toJson() => _$HumanToJson(this);
}

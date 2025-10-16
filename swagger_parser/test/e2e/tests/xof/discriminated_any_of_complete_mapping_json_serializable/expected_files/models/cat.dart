// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

import 'cat_type.dart';

part 'cat.g.dart';

@JsonSerializable()
class Cat {
  const Cat({
    required this.type,
    required this.mewCount,
  });

  factory Cat.fromJson(Map<String, Object?> json) => _$CatFromJson(json);

  final CatType type;

  /// Number of times the cat meows.
  final int mewCount;

  Map<String, Object?> toJson() => _$CatToJson(this);
}

// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

import 'package:your_package/lib/utils/parsers/custom_int_parser.dart';
import 'package:your_package/lib/utils/parsers/custom_nullable_int_parser.dart';
import 'package:your_package/lib/utils/parsers/custom_bool_parser.dart';
part 'test_model.g.dart';

@JsonSerializable()
class TestModel {
  const TestModel({
    required this.id,
    required this.count,
    required this.isActive,
    required this.score,
    this.optionalCount,
    this.optionalFlag,
    this.name,
  });

  factory TestModel.fromJson(Map<String, Object?> json) =>
      _$TestModelFromJson(json);

  @CustomIntParser()
  final int id;
  @CustomIntParser()
  final int count;
  @CustomBoolParser()
  final bool isActive;
  final num score;
  @CustomNullableIntParser()
  final int? optionalCount;
  final bool? optionalFlag;
  final String? name;

  Map<String, Object?> toJson() => _$TestModelToJson(this);
}

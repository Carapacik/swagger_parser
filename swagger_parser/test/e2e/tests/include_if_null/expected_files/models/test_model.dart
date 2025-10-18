// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:freezed_annotation/freezed_annotation.dart';

part 'test_model.freezed.dart';
part 'test_model.g.dart';

@Freezed()
class TestModel with _$TestModel {
  const factory TestModel({
    required int id,
    @JsonKey(includeIfNull: true) required String? requiredNullableField,
    @JsonKey(includeIfNull: false) String? name,
    @JsonKey(includeIfNull: false) String? optionalNullableField,
  }) = _TestModel;

  factory TestModel.fromJson(Map<String, Object?> json) =>
      _$TestModelFromJson(json);
}

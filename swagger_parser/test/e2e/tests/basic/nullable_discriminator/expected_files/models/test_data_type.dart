// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:freezed_annotation/freezed_annotation.dart';

import 'test_data_type_type.dart';
import 'test_entity_data_union.dart';

part 'test_data_type.freezed.dart';
part 'test_data_type.g.dart';

@Freezed()
class TestDataType with _$TestDataType {
  const factory TestDataType({
    /// Test value
    required String value,
    TestDataTypeType? type,
  }) = _TestDataType;

  factory TestDataType.fromJson(Map<String, Object?> json) =>
      _$TestDataTypeFromJson(json);
}

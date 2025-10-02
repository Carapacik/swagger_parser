// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:freezed_annotation/freezed_annotation.dart';

import 'test_data_type.dart';
import 'test_data_type_type.dart';

part 'test_entity_data_union.freezed.dart';
part 'test_entity_data_union.g.dart';

@Freezed(unionKey: 'type')
sealed class TestEntityDataUnion with _$TestEntityDataUnion {
  @FreezedUnionValue('TEST_TYPE')
  const factory TestEntityDataUnion.testType({
    /// Test value
    required String value,
    TestDataTypeType? type,
  }) = TestEntityDataUnionTestType;

  factory TestEntityDataUnion.fromJson(Map<String, Object?> json) =>
      _$TestEntityDataUnionFromJson(json);
}

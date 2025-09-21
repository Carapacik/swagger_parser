// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:freezed_annotation/freezed_annotation.dart';

import 'test_entity_data_union.dart';

part 'test_entity.freezed.dart';
part 'test_entity.g.dart';

@Freezed()
class TestEntity with _$TestEntity {
  const factory TestEntity({
    /// Test ID
    required String id,

    /// Test name
    required String name,

    /// Test data
    TestEntityDataUnion? data,
  }) = _TestEntity;

  factory TestEntity.fromJson(Map<String, Object?> json) =>
      _$TestEntityFromJson(json);
}

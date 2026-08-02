// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:dart_mappable/dart_mappable.dart';

import 'fruits.dart';

part 'nullable_enum_in_object.mapper.dart';

@MappableClass()
class NullableEnumInObject with NullableEnumInObjectMappable {
  const NullableEnumInObject({
    this.fruits,
  });
  final Fruits? fruits;

  static NullableEnumInObject fromJson(Map<String, dynamic> json) =>
      NullableEnumInObjectMapper.ensureInitialized()
          .decodeMap<NullableEnumInObject>(json);
}

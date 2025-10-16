// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:dart_mappable/dart_mappable.dart';

part 'cat_type.mapper.dart';

@MappableEnum(defaultValue: 'unknown')
enum CatType {
  @MappableValue('Cat')
  cat,

  @MappableValue('unknown')
  unknown;

  @override
  String toString() => toValue().toString();

  /// Returns all defined enum values excluding the unknown value.
  static List<CatType> get $valuesDefined =>
      values.where((value) => value != CatType.unknown).toList();
}

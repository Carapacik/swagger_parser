// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:dart_mappable/dart_mappable.dart';

part 'dog_type.mapper.dart';

@MappableEnum(defaultValue: 'unknown')
enum DogType {
  @MappableValue('Dog')
  dog,

  @MappableValue('unknown')
  unknown;

  @override
  String toString() => toValue().toString();

  /// Returns all defined enum values excluding the unknown value.
  static List<DogType> get $valuesDefined =>
      values.where((value) => value != DogType.unknown).toList();
}

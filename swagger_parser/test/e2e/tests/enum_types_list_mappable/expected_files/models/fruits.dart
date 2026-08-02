// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:dart_mappable/dart_mappable.dart';

part 'fruits.mapper.dart';

@MappableEnum(defaultValue: Fruits.unknown)
enum Fruits {
  @MappableValue('apple')
  apple,

  @MappableValue('orange')
  orange,

  /// The name has been replaced because it contains a keyword. Original name: `null`.
  @MappableValue(null)
  valueNull,

  @MappableValue('unknown')
  unknown;

  @override
  String toString() => toValue().toString();

  /// Returns all defined enum values excluding the unknown value.
  static List<Fruits> get $valuesDefined =>
      values.where((value) => value != Fruits.unknown).toList();
}

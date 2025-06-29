// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import

import 'package:dart_mappable/dart_mappable.dart';

part 'human_type.mapper.dart';

@MappableEnum(defaultValue: 'unknown')
enum HumanType {
  @MappableValue('Human')
  human,

  @MappableValue('unknown')
  unknown;

  @override
  String toString() => toValue() ?? super.toString();

  /// Returns all defined enum values excluding the unknown value.
  static List<HumanType> get $valuesDefined =>
      values.where((value) => value != HumanType.unknown).toList();
}

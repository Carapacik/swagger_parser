// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import

import 'package:dart_mappable/dart_mappable.dart';

part 'ios_device_type.mapper.dart';

@MappableEnum(defaultValue: 'unknown')
enum IosDeviceType {
  @MappableValue('ios')
  ios,

  @MappableValue('unknown')
  unknown;

  /// Returns all defined enum values excluding the unknown value.
  static List<IosDeviceType> get $valuesDefined =>
      values.where((value) => value != IosDeviceType.unknown).toList();
}

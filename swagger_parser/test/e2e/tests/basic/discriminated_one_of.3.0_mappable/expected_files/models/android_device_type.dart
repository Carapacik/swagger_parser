// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import

import 'package:dart_mappable/dart_mappable.dart';

part 'android_device_type.mapper.dart';

@MappableEnum(defaultValue: 'unknown')
enum AndroidDeviceType {
  @MappableValue('android')
  android,

  @MappableValue('unknown')
  unknown;

  @override
  String toString() => toValue() ?? super.toString();

  /// Returns all defined enum values excluding the unknown value.
  static List<AndroidDeviceType> get $valuesDefined =>
      values.where((value) => value != AndroidDeviceType.unknown).toList();
}

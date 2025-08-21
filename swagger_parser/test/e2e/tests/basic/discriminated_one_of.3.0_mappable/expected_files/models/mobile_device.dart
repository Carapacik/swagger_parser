// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:dart_mappable/dart_mappable.dart';

import 'android_device.dart';
import 'android_device_type.dart';
import 'ios_device.dart';
import 'ios_device_type.dart';

part 'mobile_device.mapper.dart';

@MappableClass(
    discriminatorKey: 'type', includeSubClasses: [IosDevice, AndroidDevice])
class MobileDevice with MobileDeviceMappable {
  const MobileDevice();

  T when<T>({
    required T Function(IosDevice ios) ios,
    required T Function(AndroidDevice android) android,
  }) {
    return maybeWhen(
      ios: ios,
      android: android,
    )!;
  }

  T? maybeWhen<T>({
    T Function(IosDevice ios)? ios,
    T Function(AndroidDevice android)? android,
  }) {
    return switch (this) {
      IosDevice _ => ios?.call(this as IosDevice),
      AndroidDevice _ => android?.call(this as AndroidDevice),
      _ => throw Exception("Unhandled type: ${this.runtimeType}"),
    };
  }

  static MobileDevice fromJson(Map<String, dynamic> json) =>
      MobileDeviceMapper.ensureInitialized().decodeMap<MobileDevice>(json);
}

// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import

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

  static MobileDevice fromJson(Map<String, dynamic> json) =>
      MobileDeviceMapper.ensureInitialized().decodeMap<MobileDevice>(json);
}

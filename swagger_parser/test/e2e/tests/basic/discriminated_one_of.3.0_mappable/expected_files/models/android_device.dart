// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:dart_mappable/dart_mappable.dart';

import 'android_device_type.dart';
import 'mobile_device.dart';

part 'android_device.mapper.dart';

@MappableClass(discriminatorValue: 'android')
class AndroidDevice extends MobileDevice with AndroidDeviceMappable {
  const AndroidDevice({
    required this.type,
  });
  final AndroidDeviceType type;

  static AndroidDevice fromJson(Map<String, dynamic> json) =>
      AndroidDeviceMapper.ensureInitialized().decodeMap<AndroidDevice>(json);
}

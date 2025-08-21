// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:dart_mappable/dart_mappable.dart';

import 'ios_device_type.dart';
import 'mobile_device.dart';

part 'ios_device.mapper.dart';

@MappableClass(discriminatorValue: 'ios')
class IosDevice extends MobileDevice with IosDeviceMappable {
  const IosDevice({
    required this.type,
  });
  final IosDeviceType type;

  static IosDevice fromJson(Map<String, dynamic> json) =>
      IosDeviceMapper.ensureInitialized().decodeMap<IosDevice>(json);
}

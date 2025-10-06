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
    discriminatorKey: 'type',
    includeSubClasses: [MobileDeviceIosDevice, MobileDeviceAndroidDevice])
sealed class MobileDevice with MobileDeviceMappable {
  const MobileDevice();

  static MobileDevice fromJson(Map<String, dynamic> json) {
    return MobileDeviceSealedDeserializer.tryDeserialize(json);
  }
}

extension MobileDeviceSealedDeserializer on MobileDevice {
  static MobileDevice tryDeserialize(
    Map<String, dynamic> json, {
    String key = 'type',
    Map<Type, Object?>? mapping,
  }) {
    final mappingFallback = const <Type, Object?>{
      MobileDeviceIosDevice: 'ios',
      MobileDeviceAndroidDevice: 'android',
    };
    final value = json[key];
    final effective = mapping ?? mappingFallback;
    return switch (value) {
      _ when value == effective[MobileDeviceIosDevice] =>
        MobileDeviceIosDeviceMapper.ensureInitialized()
            .decodeMap<MobileDeviceIosDevice>(json),
      _ when value == effective[MobileDeviceAndroidDevice] =>
        MobileDeviceAndroidDeviceMapper.ensureInitialized()
            .decodeMap<MobileDeviceAndroidDevice>(json),
      _ => throw FormatException(
          'Unknown discriminator value "${json[key]}" for MobileDevice'),
    };
  }
}

@MappableClass(discriminatorValue: 'ios')
class MobileDeviceIosDevice extends MobileDevice
    with MobileDeviceIosDeviceMappable
    implements IosDevice {
  @override
  final IosDeviceType type;

  const MobileDeviceIosDevice({
    required this.type,
  });
}

@MappableClass(discriminatorValue: 'android')
class MobileDeviceAndroidDevice extends MobileDevice
    with MobileDeviceAndroidDeviceMappable
    implements AndroidDevice {
  @override
  final AndroidDeviceType type;

  const MobileDeviceAndroidDevice({
    required this.type,
  });
}

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
    return _MobileDeviceHelper._tryDeserialize(json);
  }
}

class _MobileDeviceHelper {
  static MobileDevice _tryDeserialize(Map<String, dynamic> json) {
    if (json['type'] == 'ios') {
      return MobileDeviceIosDeviceMapper.ensureInitialized()
          .decodeMap<MobileDeviceIosDevice>(json);
    } else if (json['type'] == 'android') {
      return MobileDeviceAndroidDeviceMapper.ensureInitialized()
          .decodeMap<MobileDeviceAndroidDevice>(json);
    } else {
      throw FormatException(
          'Unknown discriminator value "${json['type']}" for MobileDevice');
    }
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

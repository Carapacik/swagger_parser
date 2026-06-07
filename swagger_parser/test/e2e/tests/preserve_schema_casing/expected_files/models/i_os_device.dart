// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:freezed_annotation/freezed_annotation.dart';

part 'i_os_device.freezed.dart';
part 'i_os_device.g.dart';

@Freezed()
class iOSDevice with _$iOSDevice {
  const factory iOSDevice({
    required String deviceId,
  }) = _iOSDevice;

  factory iOSDevice.fromJson(Map<String, Object?> json) =>
      _$iOSDeviceFromJson(json);
}

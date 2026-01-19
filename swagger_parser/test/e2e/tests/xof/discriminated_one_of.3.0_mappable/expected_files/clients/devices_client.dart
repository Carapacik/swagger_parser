// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:dio/dio.dart';
import 'package:retrofit/retrofit.dart';

import '../models/mobile_device.dart';

part 'devices_client.g.dart';

@RestApi()
abstract class DevicesClient {
  factory DevicesClient(Dio dio, {String? baseUrl}) = _DevicesClient;

  /// Get a mobile device
  @GET('/devices')
  Future<MobileDevice> getMobileDevice();
}

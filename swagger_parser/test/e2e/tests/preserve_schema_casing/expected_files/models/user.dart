// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:freezed_annotation/freezed_annotation.dart';

import 'url.dart';
import 'xml_http_request.dart';
import 'i_os_device.dart';
import 'k_user_status.dart';

part 'user.freezed.dart';
part 'user.g.dart';

@Freezed()
class User with _$User {
  const factory User({
    required String userId,
    required kUserStatus status,
    required iOSDevice device,
    required URL homepage,
    required XMLHttpRequest lastRequest,
  }) = _User;

  factory User.fromJson(Map<String, Object?> json) => _$UserFromJson(json);
}

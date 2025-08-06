// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import

import 'package:freezed_annotation/freezed_annotation.dart';

import 'domains.dart';
import 'ips.dart';

part 'security.freezed.dart';
part 'security.g.dart';

@Freezed()
class Security with _$Security {
  const factory Security({
    bool? exposeKey,
    Ips? ips,
    Domains? domains,
  }) = _Security;

  factory Security.fromJson(Map<String, Object?> json) =>
      _$SecurityFromJson(json);
}

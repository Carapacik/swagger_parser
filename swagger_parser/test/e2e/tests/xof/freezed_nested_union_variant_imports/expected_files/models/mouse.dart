// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:freezed_annotation/freezed_annotation.dart';

import 'mouse_kind.dart';

part 'mouse.freezed.dart';
part 'mouse.g.dart';

@Freezed()
abstract class Mouse with _$Mouse {
  const factory Mouse({
    required MouseKind kind,
    required bool squeaky,
  }) = _Mouse;

  factory Mouse.fromJson(Map<String, Object?> json) => _$MouseFromJson(json);
}

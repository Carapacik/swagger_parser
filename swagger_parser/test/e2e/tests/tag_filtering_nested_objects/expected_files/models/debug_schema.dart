// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:freezed_annotation/freezed_annotation.dart';

import 'data.dart';

part 'debug_schema.freezed.dart';
part 'debug_schema.g.dart';

@Freezed()
class DebugSchema with _$DebugSchema {
  const factory DebugSchema({
    int? id,
    String? message,
    Data? data,
  }) = _DebugSchema;

  factory DebugSchema.fromJson(Map<String, Object?> json) =>
      _$DebugSchemaFromJson(json);
}

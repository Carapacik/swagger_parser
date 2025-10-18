// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:freezed_annotation/freezed_annotation.dart';

import 'status.dart';
import 'metadata.dart';

part 'data.freezed.dart';
part 'data.g.dart';

@Freezed()
class Data with _$Data {
  const factory Data({
    @JsonKey(includeIfNull: false) String? name,
    @JsonKey(includeIfNull: false) int? id,
    @JsonKey(includeIfNull: false) Status? status,
    @JsonKey(includeIfNull: false) Metadata? metadata,
  }) = _Data;

  factory Data.fromJson(Map<String, Object?> json) => _$DataFromJson(json);
}

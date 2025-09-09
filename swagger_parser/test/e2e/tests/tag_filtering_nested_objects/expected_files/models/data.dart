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
    String? name,
    int? id,
    Status? status,
    Metadata? metadata,
  }) = _Data;

  factory Data.fromJson(Map<String, Object?> json) => _$DataFromJson(json);
}

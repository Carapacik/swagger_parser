// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import

import 'package:freezed_annotation/freezed_annotation.dart';

part 'value.freezed.dart';
part 'value.g.dart';

@Freezed()
class Value with _$Value {
  const factory Value({
    String? data,
  }) = _Value;

  factory Value.fromJson(Map<String, Object?> json) => _$ValueFromJson(json);
}
